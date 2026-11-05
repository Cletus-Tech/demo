<?php

namespace App\Services;

use App\Models\BrokerLedgerEntry;
use App\Models\BrokerWallet;
use Illuminate\Support\Str;

class DemoLedgerService
{
    public function record(
        int $userId,
        string $symbol,
        float $amount,
        string $entryType,
        ?string $memo = null,
        ?string $groupId = null
    ): void {
        $wallet = BrokerWallet::query()
            ->where('user_id', $userId)
            ->where('symbol', $symbol)
            ->firstOrFail();

        BrokerLedgerEntry::create([
            'user_id' => $userId,
            'symbol' => $symbol,
            'amount' => $amount,
            'balance_after' => $wallet->balance,
            'entry_type' => $entryType,
            'group_id' => $groupId ?: (string) Str::uuid(),
            'memo' => $memo,
            'created_at' => now(),
        ]);
    }
}
