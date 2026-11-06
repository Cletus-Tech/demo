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

        $this->assertNull($mine->fresh()->read_at);
        $this->assertNotNull($theirs->fresh()->read_at);
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

    public function test_broker_api_requires_an_authenticated_user(): void
    {
        $this->getJson('/api/broker/state')->assertUnauthorized();
    }
}
