<?php

namespace Tests\Feature;

use App\Models\BrokerAsset;
use App\Models\BrokerNotification;
use App\Models\BrokerPosition;
use App\Models\BrokerServiceRequest;
use App\Models\BrokerWallet;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BrokerApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_demo_deposit_is_usd_only_and_buy_uses_server_price(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user);

        $this->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'BTC',
            'amount' => 50,
        ])->assertUnprocessable();

        $this->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 500,
        ])->assertCreated();

        // Extra client-supplied quantity/price fields must not control execution.
        $this->postJson('/api/broker/transactions', [
            'type' => 'buy',
            'symbol' => 'BTC',
            'quote_amount_usd' => 250,
            'amount' => 999999,
            'price' => 0.01,
        ])->assertCreated();

        $btc = BrokerWallet::where('user_id', $user->id)->where('symbol', 'BTC')->firstOrFail();
        $usd = BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->firstOrFail();

        $this->assertSame(0.00367647, round((float) $btc->balance, 8));
        $this->assertSame(250.00004, round((float) $usd->balance, 8));
    }

    public function test_position_uses_server_price_and_cannot_be_closed_by_another_user(): void
    {
        $owner = User::factory()->create();
        $this->actingAs($owner)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 1000,
        ])->assertCreated();

        $response = $this->actingAs($owner)->postJson('/api/broker/positions', [
            'symbol' => 'BTC',
            'side' => 'buy',
            'margin_usd' => 100,
            'leverage' => 2,
            'quantity' => 999,
            'entry_price' => 0.01,
        ])->assertCreated();

        $positionId = $response->json('position.id');
        $position = BrokerPosition::findOrFail($positionId);
        $this->assertSame(68000.0, (float) $position->entry_price);
        $this->assertSame(0.00294117, round((float) $position->quantity, 8));

        $otherUser = User::factory()->create();
        $this->actingAs($otherUser)
            ->postJson('/api/broker/positions/' . $positionId . '/close', [])
            ->assertNotFound();

        $this->assertSame('open', $position->fresh()->status);
    }

    public function test_take_profit_is_settled_using_the_current_server_price(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 500,
        ])->assertCreated();

        $response = $this->actingAs($user)->postJson('/api/broker/positions', [
            'symbol' => 'BTC',
            'side' => 'buy',
            'margin_usd' => 100,
            'leverage' => 1,
            'take_profit' => 68100,
        ])->assertCreated();

        $positionId = $response->json('position.id');
        BrokerAsset::where('symbol', 'BTC')->update(['price' => 68200]);

        $this->actingAs($user)
            ->postJson('/api/broker/positions/settle', [])
            ->assertOk()
            ->assertJsonFragment(['reason' => 'take_profit']);

        $this->assertSame('closed', BrokerPosition::findOrFail($positionId)->status);
        $this->assertSame('take_profit', BrokerPosition::findOrFail($positionId)->close_reason);
    }

    public function test_admin_routes_and_role_changes_are_restricted(): void
    {
        $ordinaryUser = User::factory()->create();
        $this->actingAs($ordinaryUser)->get('/admin')->assertForbidden();

        $admin = User::factory()->create(['role' => 'admin']);
        $target = User::factory()->create();

        $this->actingAs($admin)->get('/admin')->assertOk();
        $this->actingAs($admin)->patch('/admin/users/' . $target->id, [
            'role' => 'admin',
            'account_status' => 'active',
        ])->assertForbidden();

        $this->assertSame('user', $target->fresh()->role);
    }

    public function test_demo_buy_sell_and_conversion_use_server_prices_and_keep_wallets_non_negative(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 1000,
        ])->assertCreated();

        $this->postJson('/api/broker/transactions', [
            'type' => 'buy',
            'symbol' => 'BTC',
            'quote_amount_usd' => 340,
            'quantity' => 999999,
            'price' => 0.01,
        ])->assertCreated();

        $this->postJson('/api/broker/transactions', [
            'type' => 'convert',
            'symbol' => 'BTC',
            'to_symbol' => 'ETH',
            'quote_amount_usd' => 68,
        ])->assertCreated();

        $this->postJson('/api/broker/transactions', [
            'type' => 'sell',
            'symbol' => 'BTC',
            'quote_amount_usd' => 68,
        ])->assertCreated();

        $this->getJson('/api/broker/state')
            ->assertOk()
            ->assertJsonCount(4, 'transactions');

        $this->assertEqualsWithDelta(728.0, (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->value('balance'), 0.00001);
        $this->assertEqualsWithDelta(0.003, (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'BTC')->value('balance'), 0.00000001);
        $this->assertEqualsWithDelta(0.01942857, (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'ETH')->value('balance'), 0.00000001);
        $this->assertDatabaseCount('broker_notifications', 4);

        foreach (BrokerWallet::where('user_id', $user->id)->get() as $wallet) {
            $this->assertGreaterThanOrEqual(0, (float) $wallet->balance);
        }
    }

    public function test_withdraw_buy_and_conversion_reject_overspending_without_changing_balances(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'BTC',
            'amount' => 5,
        ])->assertUnprocessable();

        $this->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 10,
        ])->assertCreated();

        $this->postJson('/api/broker/transactions', [
            'type' => 'withdraw',
            'symbol' => 'USD',
            'amount' => 20,
        ])->assertUnprocessable();

        $this->postJson('/api/broker/transactions', [
            'type' => 'buy',
            'symbol' => 'BTC',
            'quote_amount_usd' => 20,
        ])->assertUnprocessable();

        $this->postJson('/api/broker/transactions', [
            'type' => 'convert',
            'symbol' => 'BTC',
            'to_symbol' => 'ETH',
            'quote_amount_usd' => 1,
        ])->assertUnprocessable();

        $this->assertEqualsWithDelta(10.0, (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->value('balance'), 0.00000001);
        $this->assertEqualsWithDelta(0.0, (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'BTC')->value('balance'), 0.00000001);
        $this->assertDatabaseCount('broker_transactions', 1);
    }

    public function test_leveraged_position_reserves_margin_and_releases_margin_plus_realized_demo_pnl(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 500,
        ])->assertCreated();

        $opened = $this->postJson('/api/broker/positions', [
            'symbol' => 'BTC',
            'side' => 'buy',
            'margin_usd' => 100,
            'leverage' => 2,
            'duration_seconds' => 0,
        ])->assertCreated();

        $position = BrokerPosition::findOrFail($opened->json('position.id'));
        $reservedBalance = (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->value('balance');
        $this->assertLessThan(500, $reservedBalance);
        $this->assertGreaterThan(0, (float) $position->margin);

        BrokerAsset::where('symbol', 'BTC')->update(['price' => 69000]);

        $this->postJson('/api/broker/positions/' . $position->id . '/close')
            ->assertOk()
            ->assertJsonPath('position.status', 'closed');

        $expectedPnl = (float) $position->quantity * (69000 - (float) $position->entry_price);
        $expectedBalance = 500 + $expectedPnl;
        $finalBalance = (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->value('balance');

        $this->assertEqualsWithDelta($expectedPnl, (float) $position->fresh()->pnl, 0.00000001);
        $this->assertEqualsWithDelta($expectedBalance, $finalBalance, 0.000001);
        $this->assertDatabaseHas('broker_transactions', [
            'user_id' => $user->id,
            'type' => 'position_close',
            'status' => 'completed',
        ]);

        // The same persisted rows power the dashboard's recent trade/history panels.
        $this->getJson('/api/broker/state')
            ->assertOk()
            ->assertJsonCount(2, 'transactions')
            ->assertJsonFragment(['id' => $position->id, 'status' => 'closed']);
    }

    public function test_fiat_assets_cannot_be_used_for_leveraged_demo_positions_and_usd_stays_at_one(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/broker/positions', [
            'symbol' => 'EUR',
            'side' => 'buy',
            'margin_usd' => 50,
            'leverage' => 2,
        ])->assertUnprocessable();

        BrokerAsset::where('symbol', 'USD')->update(['price' => 1.25]);

        $this->postJson('/api/broker/prices/refresh')
            ->assertOk()
            ->assertJsonPath('source', 'simulated_demo');

        $this->assertEqualsWithDelta(1.0, (float) BrokerAsset::where('symbol', 'USD')->value('price'), 0.00000001);
    }

    public function test_users_can_only_read_their_notifications_and_close_their_own_positions(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();

        $position = BrokerPosition::create([
            'user_id' => $owner->id,
            'symbol' => 'BTC',
            'side' => 'buy',
            'quantity' => 0.01,
            'entry_price' => 68000,
            'leverage' => 2,
            'margin' => 340,
            'status' => 'open',
        ]);

        $mine = BrokerNotification::create([
            'user_id' => $other->id,
            'title' => 'My notification',
            'body' => 'Private to the other account.',
        ]);
        $theirs = BrokerNotification::create([
            'user_id' => $owner->id,
            'title' => 'Owner notification',
            'body' => 'Private to the owner.',
        ]);

        $this->actingAs($other)->postJson('/api/broker/positions/' . $position->id . '/close')
            ->assertNotFound();

        $this->getJson('/api/broker/notifications')
            ->assertOk()
            ->assertJsonCount(1)
            ->assertJsonFragment(['id' => $mine->id]);

        $this->postJson('/api/broker/notifications/read')->assertOk();

        $this->assertNotNull($mine->fresh()->read_at);
        $this->assertNull($theirs->fresh()->read_at);
    }

    public function test_automatic_take_profit_is_rechecked_and_settled_at_the_locked_server_price(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 500,
        ])->assertCreated();

        $opened = $this->postJson('/api/broker/positions', [
            'symbol' => 'BTC',
            'side' => 'buy',
            'margin_usd' => 100,
            'leverage' => 1,
            'take_profit' => 68100,
        ])->assertCreated();

        $positionId = $opened->json('position.id');
        BrokerAsset::where('symbol', 'BTC')->update(['price' => 68200]);

        $this->postJson('/api/broker/positions/settle', [])
            ->assertOk()
            ->assertJsonFragment(['reason' => 'take_profit']);

        $position = BrokerPosition::findOrFail($positionId);
        $this->assertSame('closed', $position->status);
        $this->assertSame('take_profit', $position->close_reason);
    }

    public function test_admin_routes_require_an_admin_and_only_superadmin_can_change_roles(): void
    {
        $ordinary = User::factory()->create();
        $target = User::factory()->create();
        $this->actingAs($ordinary)->get('/admin')->assertForbidden();

        $admin = User::factory()->create();
        $admin->forceFill(['role' => 'admin'])->save();

        $this->actingAs($admin)->get('/admin')->assertOk();
        $this->patch('/admin/users/' . $target->id, [
            'role' => 'admin',
            'account_status' => 'active',
        ])->assertForbidden();

        $superadmin = User::factory()->create();
        $superadmin->forceFill(['role' => 'superadmin'])->save();

        $this->actingAs($superadmin)->patch('/admin/users/' . $target->id, [
            'role' => 'support',
            'account_status' => 'active',
        ])->assertRedirect();

        $service = BrokerServiceRequest::create([
            'user_id' => $ordinary->id,
            'service_key' => 'signals',
            'details' => 'Please share demo access information.',
            'status' => 'pending',
        ]);

        $this->patch('/admin/services/' . $service->id, ['status' => 'in_review'])
            ->assertRedirect();

        $this->assertDatabaseHas('users', ['id' => $target->id, 'role' => 'support']);
        $this->assertDatabaseHas('broker_service_requests', ['id' => $service->id, 'status' => 'in_review']);
    }

    public function test_referral_signups_are_attributed_and_referral_lists_are_private(): void
    {
        $referrer = User::factory()->create();
        $referrer->forceFill(['referral_code' => 'CLETUS1234'])->save();

        $this->post('/register', [
            'name' => 'Invited User',
            'email' => 'invited@example.test',
            'password' => 'strong-password',
            'password_confirmation' => 'strong-password',
            'referral_code' => 'cletus1234',
        ])->assertRedirect(route('dashboard'));

        $invitee = User::where('email', 'invited@example.test')->firstOrFail();
        $this->assertSame($referrer->id, $invitee->referred_by);
        $this->assertMatchesRegularExpression('/^[A-Z0-9]{10}$/', $invitee->referral_code);

        $this->actingAs($referrer)->getJson('/api/broker/referrals')
            ->assertOk()
            ->assertJsonPath('code', 'CLETUS1234')
            ->assertJsonPath('count', 1)
            ->assertJsonPath('rewards_enabled', false)
            ->assertJsonPath('referrals.0.id', $invitee->id);

        $other = User::factory()->create();
        $this->actingAs($other)->getJson('/api/broker/referrals')
            ->assertOk()
            ->assertJsonPath('count', 0)
            ->assertJsonMissing(['id' => $invitee->id]);
    }

    public function test_broker_api_requires_an_authenticated_user(): void
    {
        $this->getJson('/api/broker/state')->assertUnauthorized();
    }

    public function test_market_quote_endpoint_returns_lightweight_simulated_prices(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->getJson('/api/broker/prices')
            ->assertOk()
            ->assertJsonCount(5)
            ->assertJsonFragment(['symbol' => 'BTC'])
            ->assertJsonFragment(['symbol' => 'USD']);
    }

    public function test_shared_demo_market_refresh_is_limited_to_one_tick_per_five_seconds(): void
    {
        $user = User::factory()->create();
        BrokerAsset::where('symbol', 'BTC')->update(['updated_at' => now()->subSeconds(10)]);

        $first = $this->actingAs($user)->postJson('/api/broker/prices/refresh')
            ->assertOk()
            ->assertJsonPath('throttled', false);
        $this->assertSame(4, $first->json('updated'));

        $this->postJson('/api/broker/prices/refresh')
            ->assertOk()
            ->assertJsonPath('updated', 0)
            ->assertJsonPath('throttled', true);
    }


    public function test_registration_login_logout_and_dashboard_session_protection(): void
    {
        $this->get('/dashboard')->assertRedirect(route('login'));

        $credentials = [
            'name' => 'Session Test User',
            'email' => 'session-user@example.test',
            'password' => 'a-strong-test-password',
            'password_confirmation' => 'a-strong-test-password',
        ];

        $this->post('/register', $credentials)->assertRedirect(route('dashboard'));
        $user = User::where('email', $credentials['email'])->firstOrFail();
        $this->assertAuthenticatedAs($user);
        $this->get('/dashboard')->assertOk();

        // A browser session must also authenticate the same-origin Sanctum API.
        $this->getJson('/api/broker/state')->assertOk();

        $this->post('/logout')->assertRedirect(route('login'));
        $this->assertGuest();
        $this->get('/dashboard')->assertRedirect(route('login'));

        $this->post('/login', [
            'email' => $credentials['email'],
            'password' => $credentials['password'],
        ])->assertRedirect(route('dashboard'));
        $this->assertAuthenticatedAs($user);
    }

    public function test_suspended_accounts_cannot_login_or_reuse_dashboard_or_api_sessions(): void
    {
        $user = User::factory()->create([
            'password' => Hash::make('suspended-account-password'),
            'account_status' => 'suspended',
        ]);

        $this->post('/login', [
            'email' => $user->email,
            'password' => 'suspended-account-password',
        ])->assertSessionHasErrors('email');
        $this->assertGuest();

        $this->actingAs($user)->get('/dashboard')->assertForbidden();
        $this->actingAs($user)->getJson('/api/broker/state')->assertForbidden();
        $this->actingAs($user)->get('/admin')->assertForbidden();
    }

    public function test_sanctum_csrf_cookie_endpoint_is_available_for_the_browser_adapter(): void
    {
        $this->get('/sanctum/csrf-cookie')->assertNoContent();
    }

    public function test_take_profit_and_stop_loss_must_be_on_the_correct_side_of_entry(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 500,
        ])->assertCreated();

        $invalidOrders = [
            ['side' => 'buy', 'take_profit' => 67000],
            ['side' => 'buy', 'stop_loss' => 69000],
            ['side' => 'sell', 'take_profit' => 69000],
            ['side' => 'sell', 'stop_loss' => 67000],
        ];

        foreach ($invalidOrders as $order) {
            $this->postJson('/api/broker/positions', [
                'symbol' => 'BTC',
                'side' => $order['side'],
                'margin_usd' => 50,
                'leverage' => 2,
            ] + $order)->assertUnprocessable();
        }

        $this->assertDatabaseCount('broker_positions', 0);
        $this->assertEqualsWithDelta(
            500.0,
            (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->value('balance'),
            0.00000001
        );
    }

    public function test_short_position_stop_loss_uses_short_pnl_direction_and_releases_remaining_margin(): void
    {
        $user = User::factory()->create();
        $this->actingAs($user)->postJson('/api/broker/transactions', [
            'type' => 'deposit',
            'symbol' => 'USD',
            'amount' => 500,
        ])->assertCreated();

        $opened = $this->postJson('/api/broker/positions', [
            'symbol' => 'BTC',
            'side' => 'sell',
            'margin_usd' => 100,
            'leverage' => 2,
            'stop_loss' => 69000,
        ])->assertCreated();

        $position = BrokerPosition::findOrFail($opened->json('position.id'));
        BrokerAsset::where('symbol', 'BTC')->update(['price' => 69000]);

        $this->postJson('/api/broker/positions/settle', [])
            ->assertOk()
            ->assertJsonFragment(['reason' => 'stop_loss']);

        $position->refresh();
        $this->assertSame('closed', $position->status);
        $this->assertSame('stop_loss', $position->close_reason);
        $this->assertLessThan(0, (float) $position->pnl);
        $this->assertGreaterThan(0, (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->value('balance'));
        $this->assertLessThan(
            500,
            (float) BrokerWallet::where('user_id', $user->id)->where('symbol', 'USD')->value('balance')
        );
    }

    public function test_service_enquiries_are_validated_and_private_to_the_requesting_user(): void
    {
        $owner = User::factory()->create();
        $other = User::factory()->create();

        $this->actingAs($owner)->postJson('/api/broker/services', [
            'service_key' => 'signals',
            'details' => 'Please share information about the demo signals service.',
        ])->assertCreated();

        $this->getJson('/api/broker/services')->assertOk()->assertJsonCount(1);
        $this->postJson('/api/broker/services', [
            'service_key' => 'unlisted_financial_product',
            'details' => 'This key must not be accepted.',
        ])->assertUnprocessable();

        $this->actingAs($other)->getJson('/api/broker/services')
            ->assertOk()
            ->assertJsonCount(0);

        $this->assertDatabaseCount('broker_service_requests', 1);
    }

}
