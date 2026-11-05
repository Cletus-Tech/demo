<?php

namespace Tests\Feature;

use App\Models\BrokerWallet;
use App\Services\DemoAccountService;
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
        return User::create(array_merge([
            'name' => 'Demo Trader',
            'email' => uniqid('trader-', true).'@example.test',
            'password' => 'password123',
        ], $overrides));
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
            ->assertSee('Recent demo transactions');
    }

    public function test_admin_console_is_not_available_to_ordinary_users(): void
    {
        $this->actingAs($this->account(), 'web');
        $this->get('/admin')->assertForbidden();
    }

    public function test_new_accounts_receive_the_original_configured_demo_portfolio(): void
    {
        $email = uniqid('new-user-', true).'@example.test';

        $this->post('/register', [
            'name' => 'New Demo User',
            'email' => $email,
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ])->assertRedirect('/dashboard');

        $user = User::where('email', $email)->firstOrFail();

        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'BTC', 'balance' => 0.0625,
        ]);
        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 3000,
        ]);
        $this->assertDatabaseCount('broker_wallets', 5);
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
        $this->assertDatabaseCount('broker_transactions', 11);
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

}
