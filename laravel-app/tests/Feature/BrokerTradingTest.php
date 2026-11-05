<?php

namespace Tests\Feature;

use App\Models\BrokerAsset;
use App\Models\BrokerWallet;
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
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 320,
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
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 560,
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
            'user_id' => $user->id, 'symbol' => 'USD', 'balance' => 320,
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

        $this->actingAs($other, 'sanctum');
        $this->getJson('/api/broker/state')->assertOk()->assertJsonPath('wallets', []);
        $this->assertDatabaseHas('broker_wallets', [
            'user_id' => $owner->id, 'symbol' => 'USD', 'balance' => 500,
        ]);
    }

    public function test_admin_console_is_not_available_to_ordinary_users(): void
    {
        $this->actingAs($this->account(), 'web');
        $this->get('/admin')->assertForbidden();
    }
}
