<?php

namespace App\Services;

use App\Models\BrokerAsset;
use App\Models\BrokerTransaction;
use App\Models\BrokerWallet;
use App\Models\User;
use Illuminate\Support\Str;

class DemoAccountService
{
    /**
     * Restore the configured USD-value starting portfolio using current demo prices.
     * Every grant is recorded so the demo activity remains auditable.
     */
    public function grantStartingBalances(User $user, string $reason = 'signup'): void
    {
        $groupId = (string) Str::uuid();

        foreach (config('broker.starting_balances_usd', []) as $symbol => $usdValue) {
            $asset = BrokerAsset::query()
                ->where('symbol', $symbol)
                ->where('is_active', true)
                ->first();

            if (!$asset || (float) $asset->price <= 0 || (float) $usdValue <= 0) {
                continue;
            }

            $quantity = round((float) $usdValue / (float) $asset->price, 8);

            BrokerWallet::query()->updateOrCreate(
                ['user_id' => $user->id, 'symbol' => $symbol],
                ['balance' => $quantity]
            );

            app(DemoLedgerService::class)->record($user->id, $symbol, $quantity, 'demo_grant', 'Demo starting balance ('.$reason.')', $groupId);

            BrokerTransaction::create([
                'user_id' => $user->id,
                'type' => 'demo_grant',
                'symbol' => $symbol,
                'amount' => $quantity,
                'status' => 'completed',
                'meta' => [
                    'mode' => 'demo',
                    'grant_usd' => (float) $usdValue,
                    'reason' => $reason,
                ],
            ]);
        }
    }
}
