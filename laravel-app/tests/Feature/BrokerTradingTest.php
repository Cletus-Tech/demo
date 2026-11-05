<?php

namespace Tests\Feature;

use App\Models\BrokerWallet;
use App\Models\BrokerServiceRequest;
use App\Services\DemoAccountService;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Auth\Notifications\VerifyEmail;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BrokerTradingTest extends TestCase
{
    use RefreshDatabase;

    protected function beforeRefreshingDatabase(): void
    {
        config(['database.default' => 'sqlite']);
        config(['database.connections.sqlite.database' => ':memory:']);
        config(['database.connections.sqlite.foreign_key_constraints' => true]);
    }

    private function account(array $overrides = []): User
    {
        $user = User::create(array_merge([
            'name' => 'Demo Trader',
            'email' => uniqid('trader-', true).'@example.test',
            'password' => 'password123',
        ], $overrides));
        $user->forceFill(['email_verified_at' => now()])->save();
        return $user;
    }

    public function test_demo_usd_deposit_buy_sell_and_withdraw_are_recorded_atomically(): void
    {
        $user = $this->account();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/broker/transactions', [
            'type' => 'deposit', 'symbol' => 'USD', 'amount' => 1000,
        ])->assertCreated();

        $this->postJson('/api/broker/transactions', [
            'type' => 'buy', 'symbol' => 'BTC', 'amount' => 0.01,
        ])->assertCreated();

        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 200,
        ]);
        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'BTC', 'balance' => 0.01,
        ]);

        $this->postJson('/api/broker/transactions', [
            'type' => 'sell', 'symbol' => 'BTC', 'amount' => 0.005,
        ])->assertCreated();

        $this->postJson('/api/broker/transactions', [
            'type' => 'withdraw', 'symbol' => 'USD', 'amount' => 100,
        ])->assertCreated();

        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 500,
        ]);
        $this->assertDatabaseHas('broker_transactions', [
            'user_id' => $user->id, 'type' => 'deposit', 'symbol' => 'USD',
        ]);
        $this->assertDatabaseCount('broker_ledger_entries', 6);
    }

    public function test_deposits_are_usd_only_and_insufficient_funds_are_rejected(): void
    {
        $user = $this->account();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/broker/transactions', [
            'type' => 'deposit', 'symbol' => 'BTC', 'amount' => 1,
        ])->assertUnprocessable();

        $this->postJson('/api/broker/transactions', [
            'type' => 'withdraw', 'symbol' => 'USD', 'amount' => 1,
        ])->assertUnprocessable();

        $this->assertDatabaseMissing('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'BTC',
        ]);
    }

    public function test_leveraged_position_reserves_margin_and_closes_back_to_demo_wallet(): void
    {
        $user = $this->account();
        $this->actingAs($user, 'sanctum');

        $this->postJson('/api/broker/transactions', [
            'type' => 'deposit', 'symbol' => 'USD', 'amount' => 1000,
        ])->assertCreated();

        $opened = $this->postJson('/api/broker/positions', [
            'symbol' => 'BTC',
            'side' => 'buy',
            'quantity' => 0.1,
            'leverage' => 10,
        ])->assertCreated()->assertJsonPath('mode', 'demo');

        $positionId = $opened->json('position.id');
        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 200,
        ]);

        $this->postJson('/api/broker/positions/'.$positionId.'/close')
            ->assertOk()
            ->assertJsonPath('position.status', 'closed');

        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 1000,
        ]);
        $this->assertDatabaseCount('broker_ledger_entries', 3);
    }

    public function test_users_cannot_close_another_users_position_or_read_their_wallets(): void
    {
        $owner = $this->account();
        $other = $this->account();
        BrokerWallet::create(['user_id' => $owner->id, 'symbol' => 'USD', 'balance' => 500]);

        $this->actingAs($owner, 'sanctum');
        $opened = $this->postJson('/api/broker/positions', [
            'symbol' => 'BTC', 'side' => 'buy', 'quantity' => 0.001, 'leverage' => 10,
        ])->assertCreated();
        $positionId = $opened->json('position.id');

        $this->actingAs($other, 'sanctum');
        $this->getJson('/api/broker/state')->assertOk()->assertJsonPath('wallets', []);
        $this->postJson('/api/broker/positions/'.$positionId.'/close')->assertNotFound();

        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $owner->id, 'symbol' => 'USD', 'balance' => 492,
        ]);
    }

    public function test_admin_can_open_the_management_overview(): void
    {
        $admin = $this->account();
        $admin->forceFill(['role' => 'admin'])->save();

        $this->actingAs($admin, 'web')
            ->get('/admin')
            ->assertOk()
            ->assertSee('Demo wallet balances')
            ->assertSee('Recent demo orders and transactions')
            ->assertSee('Append-only demo wallet ledger')
            ->assertSee('Administrator audit trail');
    }

    public function test_admin_console_is_not_available_to_ordinary_users(): void
    {
        $this->actingAs($this->account(), 'web');
        $this->get('/admin')->assertForbidden();
    }

    public function test_new_accounts_receive_the_original_configured_demo_portfolio(): void
    {
        Notification::fake();
        $email = uniqid('new-user-', true).'@example.test';

        $this->post('/register', [
            'name' => 'New Demo User',
            'email' => $email,
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertRedirect('/email/verify');

        $user = User::where('email', $email)->firstOrFail();
        $this->assertNull($user->email_verified_at);
        Notification::assertSentTo($user, VerifyEmail::class);

        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'BTC', 'balance' => 0.0625,
        ]);
        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 3000,
        ]);
        $this->assertDatabaseCount('broker_wallets', 5);
        $this->assertDatabaseCount('broker_ledger_entries', 5);
    }

    public function test_demo_reset_restores_starting_balances_and_keeps_the_account_history(): void
    {
        $user = $this->account();
        app(DemoAccountService::class)->grantStartingBalances($user, 'signup');
        BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->update(['balance' => 12]);

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/broker/reset')
            ->assertOk()
            ->assertJsonPath('reset', true);

        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 3000,
        ]);
        $this->assertDatabaseHas('broker_transactions', [
            'user_id' => $user->id, 'type' => 'demo_reset', 'symbol' => 'USD',
        ]);
        $this->assertDatabaseCount('broker_transactions', 15);
        $this->assertDatabaseCount('broker_ledger_entries', 15);
    }


    public function test_simulated_price_refresh_is_rate_limited_and_does_not_move_fiat(): void
    {
        $this->actingAs($this->account(), 'sanctum');

        $this->postJson('/api/broker/prices/refresh')
            ->assertOk()
            ->assertJsonPath('updated', 0);

        $this->travel(6)->seconds();

        $this->postJson('/api/broker/prices/refresh')
            ->assertOk()
            ->assertJsonPath('updated', 4);

        $this->assertDatabaseHas('broker_assets', [
            'symbol' => 'USD', 'price' => 1,
        ]);
    }


    public function test_referral_code_is_created_and_valid_referrals_are_tracked(): void
    {
        Notification::fake();
        $referrer = $this->account(['referral_code' => 'REFCODE8']);
        $email = uniqid('referred-', true).'@example.test';

        $this->post('/register', [
            'name' => 'Referred Trader',
            'email' => $email,
            'password' => 'password123',
            'password_confirmation' => 'password123',
            'ref' => 'refcode8',
        ])->assertRedirect('/email/verify');

        $referred = User::where('email', $email)->firstOrFail();

        $this->assertNotEmpty($referred->referral_code);
        $this->assertSame($referrer->id, $referred->referred_by);
        $this->assertDatabaseHas('broker_referrals', [
            'referrer_id' => $referrer->id,
            'referred_id' => $referred->id,
            'status' => 'registered',
        ]);

        $this->actingAs($referrer, 'sanctum')
            ->getJson('/api/broker/referrals')
            ->assertOk()
            ->assertJsonCount(1);
    }


    public function test_password_reset_link_can_be_sent_and_used(): void
    {
        $user = $this->account();
        Notification::fake();

        $this->get('/forgot-password')->assertOk();
        $this->post('/forgot-password', ['email' => $user->email])
            ->assertSessionHas('status');

        $token = null;
        Notification::assertSentTo($user, ResetPassword::class, function ($notification) use (&$token) {
            $token = $notification->token;
            return true;
        });

        $this->get('/reset-password/'.$token.'?email='.urlencode($user->email))->assertOk();
        $this->post('/reset-password', [
            'token' => $token,
            'email' => $user->email,
            'password' => 'new-password-123',
            'password_confirmation' => 'new-password-123',
        ])->assertRedirect('/login');

        $this->assertTrue(Hash::check('new-password-123', $user->fresh()->password));
    }


    public function test_dashboard_renders_original_brokerage_interface_through_laravel(): void
    {
        $this->actingAs($this->account(), 'web')
            ->get('/dashboard')
            ->assertOk()
            ->assertSee('Demo mode: practice funds')
            ->assertSee('Buy')
            ->assertDontSee('supabase-js');
    }


    public function test_admin_can_update_service_enquiry_status_and_private_note(): void
    {
        $admin = $this->account();
        $admin->forceFill(['role' => 'admin'])->save();
        $request = BrokerServiceRequest::create([
            'user_id' => $this->account()->id,
            'service_key' => 'cold_storage',
            'details' => 'Please contact me.',
            'status' => 'pending',
        ]);

        $this->actingAs($admin, 'web')
            ->patch('/admin/services/'.$request->id, [
                'status' => 'in_review',
                'admin_note' => 'Customer follow-up requested.',
            ])
            ->assertRedirect();

        $this->assertDatabaseHas('broker_service_requests', [
            'id' => $request->id,
            'status' => 'in_review',
            'admin_note' => 'Customer follow-up requested.',
        ]);
        $this->assertDatabaseHas('broker_audit_logs', [
            'actor_id' => $admin->id,
            'action' => 'service_request_status_changed',
            'target_id' => (string) $request->id,
        ]);
    }


    public function test_repeated_demo_transaction_request_with_same_idempotency_key_is_not_applied_twice(): void
    {
        $user = $this->account();
        $this->actingAs($user, 'sanctum');
        $key = (string) \Illuminate\Support\Str::uuid();
        $payload = ['type' => 'deposit', 'symbol' => 'USD', 'amount' => 250, 'idempotency_key' => $key];

        $this->postJson('/api/broker/transactions', $payload)->assertCreated();
        $this->postJson('/api/broker/transactions', $payload)->assertOk()->assertJsonPath('replayed', true);

        $this->assertDatabaseHas('broker_wallets', ['user_id' => $user->id, 'symbol' => 'USD', 'balance' => 250]);
        $this->assertDatabaseCount('broker_transactions', 1);
        $this->assertDatabaseCount('broker_ledger_entries', 1);
    }

    public function test_repeated_leveraged_position_request_returns_the_original_position(): void
    {
        $user = $this->account();
        BrokerWallet::create(['user_id' => $user->id, 'symbol' => 'USD', 'balance' => 1000]);
        $this->actingAs($user, 'sanctum');
        $key = (string) \Illuminate\Support\Str::uuid();
        $payload = ['symbol' => 'BTC', 'side' => 'buy', 'quantity' => 0.1, 'leverage' => 10, 'idempotency_key' => $key];

        $first = $this->postJson('/api/broker/positions', $payload)->assertCreated();
        $second = $this->postJson('/api/broker/positions', $payload)->assertOk()->assertJsonPath('replayed', true);

        $this->assertSame($first->json('position.id'), $second->json('position.id'));
        $this->assertDatabaseCount('broker_positions', 1);
        $this->assertDatabaseCount('broker_transactions', 1);
        $this->assertDatabaseCount('broker_ledger_entries', 1);
        $this->assertDatabaseHas('broker_wallets', ['user_id' => $user->id, 'symbol' => 'USD', 'balance' => 200]);
    }


    public function test_only_superadmins_can_change_roles_and_users_cannot_change_their_own_role(): void
    {
        $admin = $this->account();
        $admin->forceFill(['role' => 'admin'])->save();
        $target = $this->account();
        $this->actingAs($admin, 'web')
            ->patch('/admin/users/'.$target->id, ['role' => 'admin', 'account_status' => 'suspended'])
            ->assertForbidden();

        $this->assertDatabaseHas('users', ['id' => $target->id, 'role' => 'user', 'account_status' => 'active']);

        $superadmin = $this->account();
        $superadmin->forceFill(['role' => 'superadmin'])->save();
        $this->actingAs($superadmin, 'web')
            ->patch('/admin/users/'.$target->id, ['role' => 'support', 'account_status' => 'active'])
            ->assertRedirect();

        $this->assertDatabaseHas('users', ['id' => $target->id, 'role' => 'support']);
        $this->actingAs($superadmin, 'web')
            ->patch('/admin/users/'.$target->id, ['role' => 'support', 'account_status' => 'suspended'])
            ->assertRedirect();
        $this->assertDatabaseHas('broker_audit_logs', ['actor_id' => $superadmin->id, 'action' => 'role_changed', 'target_id' => (string) $target->id]);
        $this->assertDatabaseHas('broker_audit_logs', ['actor_id' => $superadmin->id, 'action' => 'status_changed', 'target_id' => (string) $target->id]);
        $this->actingAs($superadmin, 'web')
            ->patch('/admin/users/'.$superadmin->id, ['role' => 'admin', 'account_status' => 'active'])
            ->assertStatus(422);
    }


    public function test_signed_email_verification_link_activates_the_account(): void
    {
        Notification::fake();
        $email = uniqid('verify-', true).'@example.test';
        $this->post('/register', [
            'name' => 'Email Verification User',
            'email' => $email,
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertRedirect('/email/verify');

        $user = User::where('email', $email)->firstOrFail();
        $url = URL::temporarySignedRoute(
            'verification.verify',
            now()->addMinutes(30),
            ['id' => $user->id, 'hash' => sha1($user->getEmailForVerification())]
        );

        $this->actingAs($user)->get($url)->assertRedirect('/dashboard');
        $this->assertNotNull($user->fresh()->email_verified_at);
    }

}
