<?php

namespace App\Http\Controllers;

use App\Models\{BrokerAsset,BrokerWallet,BrokerTransaction,BrokerPosition,BrokerServiceRequest,BrokerNotification,User};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Illuminate\Validation\Rule;

class BrokerApiController
{
    public function state(Request $request)
    {
        $user=$request->user();
        $wallets=BrokerWallet::where('user_id',$user->id)->get()->keyBy('symbol');
        $assets=BrokerAsset::where('is_active',true)->orderBy('symbol')->get();
        $positions=BrokerPosition::where('user_id',$user->id)->latest()->limit(100)->get();
        return response()->json(['profile'=>['id'=>$user->id,'email'=>$user->email,'full_name'=>$user->name,'phone'=>$user->phone,'country'=>$user->country,'role'=>$user->role ?? 'user','referral_code'=>$user->referral_code],'assets'=>$assets,'wallets'=>$wallets->values(),'positions'=>$positions,'transactions'=>BrokerTransaction::where('user_id',$user->id)->latest()->limit(100)->get()]);
    }

    public function prices()
    {
        return response()->json(
            BrokerAsset::where('is_active', true)
                ->orderBy('symbol')
                ->get(['symbol', 'price', 'updated_at'])
        );
    }

    public function refreshDemoPrices()
    {
        $updated = DB::transaction(function () {
            $assets = BrokerAsset::where('is_active', true)
                ->orderBy('symbol')
                ->lockForUpdate()
                ->get();

            // Restore the accounting quote currency even when another browser
            // has already performed the current market tick.
            $usd = $assets->firstWhere('symbol', 'USD');
            if ($usd && (float) $usd->price !== 1.0) {
                $usd->update(['price' => 1]);
            }

            // One browser refreshes the shared demo market at most once per
            // five seconds. The locked anchor prevents every open client from
            // applying another random move to the same global prices.
            $anchor = $assets->firstWhere('symbol', 'BTC')
                ?? $assets->first(static fn ($asset) => $asset->symbol !== 'USD');
            if ($anchor?->updated_at && $anchor->updated_at->gt(now()->subSeconds(5))) {
                return 0;
            }

            $updated = 0;
            foreach ($assets as $asset) {
                if ($asset->symbol === 'USD') {
                    continue;
                }

                $move = random_int(-30, 30) / 10000;
                $next = max(0.00000001, (float) $asset->price * (1 + $move));
                $asset->update(['price' => round($next, 8)]);
                $updated++;
            }

            return $updated;
        }, 3);

        return response()->json([
            'updated' => $updated,
            'source' => 'simulated_demo',
            'base_currency' => 'USD',
            'throttled' => $updated === 0,
        ]);
    }

    public function transact(Request $request)
    {
        $data = $request->validate([
            'type' => 'required|in:deposit,withdraw,buy,sell,convert',
            'symbol' => ['required', 'string', 'max:20', 'regex:/^[A-Z0-9]{2,20}$/i'],
            'amount' => ['nullable', 'numeric', 'gt:0', 'lte:1000000000000', 'decimal:0,8'],
            'quote_amount_usd' => ['nullable', 'numeric', 'gt:0', 'lte:1000000000000', 'decimal:0,8'],
            'to_symbol' => ['nullable', 'string', 'max:20', 'regex:/^[A-Z0-9]{2,20}$/i'],
        ]);

        $type = $data['type'];
        $symbol = strtoupper($data['symbol']);
        $isCashFlow = in_array($type, ['deposit', 'withdraw'], true);

        if ($isCashFlow && ($symbol !== 'USD' || !isset($data['amount']))) {
            throw ValidationException::withMessages([
                'amount' => 'Demo deposits and withdrawals must use a positive USD amount.',
            ]);
        }
        if (!$isCashFlow && !isset($data['quote_amount_usd'])) {
            throw ValidationException::withMessages([
                'quote_amount_usd' => 'Enter the USD value for this demo trade.',
            ]);
        }

        $toSymbol = strtoupper($data['to_symbol'] ?? '');
        if ($type === 'convert' && (!$toSymbol || $toSymbol === $symbol)) {
            throw ValidationException::withMessages([
                'to_symbol' => 'Choose a different destination asset.',
            ]);
        }
        if (in_array($type, ['buy', 'sell'], true) && $symbol === 'USD') {
            throw ValidationException::withMessages([
                'symbol' => 'Choose a non-USD asset to buy or sell.',
            ]);
        }

        return DB::transaction(function () use ($request, $data, $type, $symbol, $toSymbol, $isCashFlow) {
            $assetSymbols = $isCashFlow
                ? ['USD']
                : ($type === 'convert' ? [$symbol, $toSymbol] : [$symbol]);
            sort($assetSymbols, SORT_STRING);

            $assets = BrokerAsset::whereIn('symbol', $assetSymbols)
                ->where('is_active', true)
                ->orderBy('symbol')
                ->lockForUpdate()
                ->get()
                ->keyBy('symbol');

            foreach ($assetSymbols as $assetSymbol) {
                if (!$assets->has($assetSymbol)) {
                    throw ValidationException::withMessages([
                        'symbol' => 'One of the selected demo assets is unavailable.',
                    ]);
                }
            }

            $walletSymbols = match ($type) {
                'deposit', 'withdraw' => ['USD'],
                'buy', 'sell' => ['USD', $symbol],
                'convert' => [$symbol, $toSymbol],
            };
            $wallets = $this->lockWallets((int) $request->user()->id, $walletSymbols);

            $recordAmount = 0.0;
            $meta = ['mode' => 'demo'];
            $notificationText = '';

            if ($type === 'deposit' || $type === 'withdraw') {
                $amount = round((float) $data['amount'], 8);
                $usd = $wallets->get('USD');

                if ($type === 'withdraw' && (float) $usd->balance + 0.000000001 < $amount) {
                    throw ValidationException::withMessages(['amount' => 'Insufficient demo USD balance.']);
                }

                if ($type === 'deposit') {
                    $usd->increment('balance', $amount);
                } else {
                    $usd->decrement('balance', $amount);
                }

                $recordAmount = $amount;
                $notificationText = 'Your demo USD ' . $type . ' was recorded.';
            } elseif ($type === 'buy') {
                $price = (float) $assets->get($symbol)->price;
                $quote = round((float) $data['quote_amount_usd'], 8);
                if ($price <= 0) {
                    throw ValidationException::withMessages(['symbol' => 'The selected demo asset has no valid price.']);
                }

                $quantity = round($quote / $price, 8);
                $executedValue = round($quantity * $price, 8);
                if ($quantity <= 0 || $executedValue <= 0) {
                    throw ValidationException::withMessages(['quote_amount_usd' => 'The amount is too small for this demo asset.']);
                }

                $usd = $wallets->get('USD');
                if ((float) $usd->balance + 0.000000001 < $executedValue) {
                    throw ValidationException::withMessages(['quote_amount_usd' => 'Insufficient demo USD balance.']);
                }

                $usd->decrement('balance', $executedValue);
                $wallets->get($symbol)->increment('balance', $quantity);
                $recordAmount = $quantity;
                $meta += ['quote_amount_usd' => $executedValue, 'execution_price' => $price];
                $notificationText = 'Your demo buy of ' . $symbol . ' was recorded.';
            } elseif ($type === 'sell') {
                $price = (float) $assets->get($symbol)->price;
                $quote = round((float) $data['quote_amount_usd'], 8);
                if ($price <= 0) {
                    throw ValidationException::withMessages(['symbol' => 'The selected demo asset has no valid price.']);
                }

                $quantity = round($quote / $price, 8);
                $proceeds = round($quantity * $price, 8);
                if ($quantity <= 0 || $proceeds <= 0) {
                    throw ValidationException::withMessages(['quote_amount_usd' => 'The amount is too small for this demo asset.']);
                }

                $assetWallet = $wallets->get($symbol);
                if ((float) $assetWallet->balance + 0.000000001 < $quantity) {
                    throw ValidationException::withMessages(['quote_amount_usd' => 'Insufficient demo ' . $symbol . ' balance.']);
                }

                $assetWallet->decrement('balance', $quantity);
                $wallets->get('USD')->increment('balance', $proceeds);
                $recordAmount = $quantity;
                $meta += ['quote_amount_usd' => $proceeds, 'execution_price' => $price];
                $notificationText = 'Your demo sell of ' . $symbol . ' was recorded.';
            } else {
                $fromPrice = (float) $assets->get($symbol)->price;
                $toPrice = (float) $assets->get($toSymbol)->price;
                $quote = round((float) $data['quote_amount_usd'], 8);
                if ($fromPrice <= 0 || $toPrice <= 0) {
                    throw ValidationException::withMessages(['to_symbol' => 'One of the selected demo assets has no valid price.']);
                }

                $fromQuantity = round($quote / $fromPrice, 8);
                $executedValue = round($fromQuantity * $fromPrice, 8);
                $toQuantity = round($executedValue / $toPrice, 8);
                if ($fromQuantity <= 0 || $toQuantity <= 0) {
                    throw ValidationException::withMessages(['quote_amount_usd' => 'The amount is too small for this demo conversion.']);
                }

                $sourceWallet = $wallets->get($symbol);
                if ((float) $sourceWallet->balance + 0.000000001 < $fromQuantity) {
                    throw ValidationException::withMessages(['quote_amount_usd' => 'Insufficient demo ' . $symbol . ' balance.']);
                }

                $sourceWallet->decrement('balance', $fromQuantity);
                $wallets->get($toSymbol)->increment('balance', $toQuantity);
                $recordAmount = $fromQuantity;
                $meta += [
                    'to_symbol' => $toSymbol,
                    'to_amount' => $toQuantity,
                    'quote_amount_usd' => $executedValue,
                    'from_price' => $fromPrice,
                    'to_price' => $toPrice,
                ];
                $notificationText = 'Your demo conversion from ' . $symbol . ' to ' . $toSymbol . ' was recorded.';
            }

            $transaction = BrokerTransaction::create([
                'user_id' => $request->user()->id,
                'type' => $type,
                'symbol' => $symbol,
                'amount' => $recordAmount,
                'status' => 'completed',
                'meta' => $meta,
            ]);
            BrokerNotification::create([
                'user_id' => $request->user()->id,
                'title' => 'Demo ' . ucfirst($type) . ' completed',
                'body' => $notificationText,
            ]);

            $responseWallet = $wallets->get($type === 'sell' ? 'USD' : $symbol)->fresh();

            return response()->json([
                'transaction' => $transaction,
                'wallet' => $responseWallet,
                'mode' => 'demo',
            ], 201);
        }, 3);
    }

    public function openPosition(Request $request)
    {
        $data = $request->validate([
            'symbol' => ['required', 'string', 'max:20', 'regex:/^[A-Z0-9]{2,20}$/i'],
            'side' => 'required|in:buy,sell',
            'margin_usd' => ['required', 'numeric', 'gt:0', 'lte:1000000000000', 'decimal:0,8'],
            'leverage' => ['required', 'numeric', 'min:1', 'max:100', 'decimal:0,2'],
            'take_profit' => ['nullable', 'numeric', 'gt:0', 'lte:1000000000000', 'decimal:0,8'],
            'stop_loss' => ['nullable', 'numeric', 'gt:0', 'lte:1000000000000', 'decimal:0,8'],
            'duration_seconds' => 'nullable|integer|min:0|max:86400',
        ]);

        return DB::transaction(function () use ($request, $data) {
            $symbol = strtoupper($data['symbol']);
            $asset = BrokerAsset::where('symbol', $symbol)
                ->where('is_active', true)
                ->lockForUpdate()
                ->first();

            if (!$asset) {
                throw ValidationException::withMessages(['symbol' => 'The selected demo asset is unavailable.']);
            }
            if ($asset->category === 'fiat') {
                throw ValidationException::withMessages(['symbol' => 'Leveraged demo positions are available for non-fiat assets only.']);
            }

            $entry = (float) $asset->price;
            if ($entry <= 0) {
                throw ValidationException::withMessages(['symbol' => 'The selected demo asset has no valid price.']);
            }
            if (!empty($data['take_profit']) && (
                ($data['side'] === 'buy' && (float) $data['take_profit'] <= $entry) ||
                ($data['side'] === 'sell' && (float) $data['take_profit'] >= $entry)
            )) {
                throw ValidationException::withMessages([
                    'take_profit' => 'Take profit must be above entry for a buy and below entry for a sell.',
                ]);
            }
            if (!empty($data['stop_loss']) && (
                ($data['side'] === 'buy' && (float) $data['stop_loss'] >= $entry) ||
                ($data['side'] === 'sell' && (float) $data['stop_loss'] <= $entry)
            )) {
                throw ValidationException::withMessages([
                    'stop_loss' => 'Stop loss must be below entry for a buy and above entry for a sell.',
                ]);
            }

            $leverage = (float) $data['leverage'];
            $budget = round((float) $data['margin_usd'], 8);
            $quantity = floor((($budget * $leverage / $entry) * 100000000)) / 100000000;
            $margin = round(($quantity * $entry) / $leverage, 8);
            if ($quantity <= 0 || $margin <= 0) {
                throw ValidationException::withMessages(['margin_usd' => 'The margin is too small for this demo asset and leverage.']);
            }

            $wallets = $this->lockWallets((int) $request->user()->id, ['USD']);
            $usd = $wallets->get('USD');
            if ((float) $usd->balance + 0.000000001 < $margin) {
                throw ValidationException::withMessages(['margin_usd' => 'Insufficient demo USD margin.']);
            }
            $usd->decrement('balance', $margin);

            $position = BrokerPosition::create([
                'user_id' => $request->user()->id,
                'symbol' => $asset->symbol,
                'side' => $data['side'],
                'quantity' => $quantity,
                'entry_price' => $entry,
                'leverage' => $leverage,
                'margin' => $margin,
                'take_profit' => $data['take_profit'] ?? null,
                'stop_loss' => $data['stop_loss'] ?? null,
                'expires_at' => !empty($data['duration_seconds'])
                    ? now()->addSeconds((int) $data['duration_seconds'])
                    : null,
            ]);
            BrokerNotification::create([
                'user_id' => $request->user()->id,
                'title' => $asset->symbol . ' demo position opened',
                'body' => 'A ' . $data['side'] . ' demo position was opened with ' . $data['leverage'] . 'x leverage.',
            ]);

            return response()->json(['position' => $position, 'mode' => 'demo'], 201);
        }, 3);
    }

    /**
     * Close a position at one locked demo quote. A null reason means that TP,
     * SL or expiry must be evaluated inside this same transaction.
     */
    private function settlePosition(int $positionId, ?string $reason): ?BrokerPosition
    {
        return DB::transaction(function () use ($positionId, $reason) {
            $position = BrokerPosition::whereKey($positionId)->lockForUpdate()->first();
            if (!$position || $position->status !== 'open') {
                return null;
            }

            $asset = BrokerAsset::where('symbol', $position->symbol)
                ->lockForUpdate()
                ->first();
            $price = (float) ($asset?->price ?? $position->entry_price);

            if ($reason === null) {
                $isLong = $position->side === 'buy';

                if ($position->take_profit !== null && (
                    $isLong
                        ? $price >= (float) $position->take_profit
                        : $price <= (float) $position->take_profit
                )) {
                    $reason = 'take_profit';
                } elseif ($position->stop_loss !== null && (
                    $isLong
                        ? $price <= (float) $position->stop_loss
                        : $price >= (float) $position->stop_loss
                )) {
                    $reason = 'stop_loss';
                } elseif ($position->expires_at && $position->expires_at->isPast()) {
                    $reason = 'duration_ended';
                } else {
                    return null;
                }
            }

            $direction = $position->side === 'buy' ? 1 : -1;
            $rawPnl = (float) $position->quantity
                * ($price - (float) $position->entry_price)
                * $direction;
            // Demo loss is capped at the reserved margin; the released amount can never be negative.
            $pnl = round(max(-(float) $position->margin, $rawPnl), 8);
            $release = round(max(0, (float) $position->margin + $pnl), 8);

            $wallets = $this->lockWallets((int) $position->user_id, ['USD']);
            $wallets->get('USD')->increment('balance', $release);

            $position->update([
                'status' => 'closed',
                'closed_at' => now(),
                'pnl' => $pnl,
                'close_reason' => $reason,
            ]);

            BrokerTransaction::create([
                'user_id' => $position->user_id,
                'type' => 'position_close',
                'symbol' => $position->symbol,
                'amount' => $release,
                'status' => 'completed',
                'meta' => ['mode' => 'demo', 'pnl' => $pnl, 'reason' => $reason],
            ]);
            BrokerNotification::create([
                'user_id' => $position->user_id,
                'title' => $position->symbol . ' position closed',
                'body' => 'Your demo position closed: ' . $reason . '.',
            ]);

            return $position->fresh();
        }, 3);
    }

    public function closePosition(Request $request, BrokerPosition $position)
    {
        abort_unless((int) $position->user_id === (int) $request->user()->id, 404);
        abort_unless($position->status==='open',422);
        $closed=$this->settlePosition($position->id,'manual');
        abort_unless($closed,422);
        return response()->json(['position'=>$closed,'mode'=>'demo']);
    }

    public function settlePositions(Request $request)
    {
        $closed = [];
        $positionIds = BrokerPosition::where('user_id', $request->user()->id)
            ->where('status', 'open')
            ->orderBy('id')
            ->pluck('id');

        foreach ($positionIds as $positionId) {
            $row = $this->settlePosition((int) $positionId, null);
            if ($row) {
                $closed[] = [
                    'id' => $row->id,
                    'symbol' => $row->symbol,
                    'side' => $row->side === 'buy' ? 'long' : 'short',
                    'reason' => $row->close_reason,
                    'pnl' => (float) $row->pnl,
                ];
            }
        }

        return response()->json($closed);
    }

    public function resetDemo(Request $request)
    {
        $userId = (int) $request->user()->id;

        DB::transaction(function () use ($userId) {
            // Keep the same lock order as position settlement: positions first,
            // then wallets, so reset cannot deadlock against a concurrent close.
            $positions = BrokerPosition::where('user_id', $userId)
                ->where('status', 'open')
                ->orderBy('id')
                ->lockForUpdate()
                ->get();
            $wallets = BrokerWallet::where('user_id', $userId)
                ->orderBy('symbol')
                ->lockForUpdate()
                ->get();

            foreach ($wallets as $wallet) {
                $wallet->update(['balance' => 0]);
            }
            foreach ($positions as $position) {
                $position->update([
                    'status' => 'closed',
                    'closed_at' => now(),
                    'close_reason' => 'reset',
                    'pnl' => 0,
                ]);
            }

            BrokerNotification::create([
                'user_id' => $userId,
                'title' => 'Demo account reset',
                'body' => 'Your demo wallet balances were cleared and open demo positions were closed.',
            ]);
        }, 3);

        return response()->json(['reset' => true, 'mode' => 'demo']);
    }

    private function lockWallets(int $userId, array $symbols)
    {
        $symbols = array_values(array_unique(array_map(
            static fn ($symbol) => strtoupper((string) $symbol),
            $symbols
        )));
        sort($symbols, SORT_STRING);

        $now = now();
        $rows = array_map(static fn ($symbol) => [
            'user_id' => $userId,
            'symbol' => $symbol,
            'balance' => 0,
            'created_at' => $now,
            'updated_at' => $now,
        ], $symbols);
        DB::table('broker_wallets')->insertOrIgnore($rows);

        return BrokerWallet::where('user_id', $userId)
            ->whereIn('symbol', $symbols)
            ->orderBy('symbol')
            ->lockForUpdate()
            ->get()
            ->keyBy('symbol');
    }

    public function notifications(Request $request)
    {
        return response()->json(BrokerNotification::where('user_id',$request->user()->id)->latest()->limit(30)->get());
    }

    public function markNotificationsRead(Request $request)
    {
        BrokerNotification::where('user_id',$request->user()->id)->whereNull('read_at')->update(['read_at'=>now()]);
        return response()->json(['updated'=>true]);
    }

    public function updateProfile(Request $request)
    {
        $data=$request->validate(['full_name'=>'required|string|max:120','phone'=>'nullable|string|max:40','country'=>'nullable|string|max:100']);
        $request->user()->forceFill(['name'=>$data['full_name'],'phone'=>$data['phone']??null,'country'=>$data['country']??null])->save();
        return response()->json(['id'=>$request->user()->id,'email'=>$request->user()->email,'full_name'=>$request->user()->name,'phone'=>$request->user()->phone,'country'=>$request->user()->country,'role'=>$request->user()->role ?? 'user']);
    }

    public function referrals(Request $request)
    {
        $user = $request->user();
        $referrals = User::where('referred_by', $user->id)
            ->latest()
            ->limit(100)
            ->get(['id', 'name', 'created_at']);

        return response()->json([
            'code' => $user->referral_code,
            'count' => User::where('referred_by', $user->id)->count(),
            'referrals' => $referrals,
            'rewards_enabled' => false,
        ]);
    }

    public function services(Request $request)
    {
        return response()->json(BrokerServiceRequest::where('user_id', $request->user()->id)->latest()->limit(100)->get());
    }

    public function createService(Request $request)
    {
        $data = $request->validate([
            'service_key' => ['required', Rule::in([
                'cold_storage', 'cards', 'subscribe', 'signals', 'connect_wallet',
                'investing', 'copy_trading', 'mining', 'real_estate', 'stake',
            ])],
            'details' => 'nullable|string|max:3000',
        ]);

        $row = BrokerServiceRequest::create($data + ['user_id' => $request->user()->id]);
        return response()->json($row, 201);
    }
}