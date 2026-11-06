<?php

namespace Tests\Feature;

use App\Models\BrokerAsset;
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

    public function test_service_enquiries_are_private_to_their_owner(): void
    {
        $owner = User::factory()->create();
        $this->actingAs($owner)->postJson('/api/broker/services', [
            'service_key' => 'cold_storage',
            'details' => 'Please send information.',
        ])->assertCreated();

        $this->assertSame(1, BrokerServiceRequest::where('user_id', $owner->id)->count());

        $otherUser = User::factory()->create();
        $this->actingAs($otherUser)->getJson('/api/broker/services')
            ->assertOk()
            ->assertExactJson([]);
    }

    public function test_suspended_accounts_are_blocked_from_broker_api(): void
    {
        $user = User::factory()->create(['account_status' => 'suspended']);

        $this->actingAs($user)->getJson('/api/broker/state')->assertForbidden();
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
}
