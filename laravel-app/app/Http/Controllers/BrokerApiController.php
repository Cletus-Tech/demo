<?php

namespace App\Http\Controllers;

use App\Models\{BrokerAsset,BrokerWallet,BrokerTransaction,BrokerPosition,BrokerServiceRequest,BrokerNotification,User};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class BrokerApiController
{
    public function state(Request $request)
    {
        $user=$request->user();
        $wallets=BrokerWallet::where('user_id',$user->id)->get()->keyBy('symbol');
        $assets=BrokerAsset::where('is_active',true)->orderBy('symbol')->get();
        $positions=BrokerPosition::where('user_id',$user->id)->latest()->limit(100)->get();
        return response()->json(['profile'=>['id'=>$user->id,'email'=>$user->email,'full_name'=>$user->name,'phone'=>$user->phone,'country'=>$user->country,'role'=>$user->role ?? 'user'],'assets'=>$assets,'wallets'=>$wallets->values(),'positions'=>$positions,'transactions'=>BrokerTransaction::where('user_id',$user->id)->latest()->limit(50)->get()]);
    }

    public function refreshDemoPrices()
    {
        $interval = max(1, (int) config('broker.price_refresh_interval_seconds', 5));
        $volatility = max(0, (float) config('broker.price_volatility', 0.006));
        $assets = BrokerAsset::query()
            ->where('is_active', true)
            ->where('category', '<>', 'fiat')
            ->where('updated_at', '<=', now()->subSeconds($interval))
            ->get();

        foreach ($assets as $asset) {
            $move = ((random_int(0, 10000) / 10000) - 0.5) * $volatility;
            $next = max(0.00000001, (float) $asset->price * (1 + $move));
            $asset->update(['price' => $next]);
        }

        return response()->json(['updated' => $assets->count(), 'source' => 'simulated_demo']);
    }

    public function transact(Request $request)
    {
        $data=$request->validate(['type'=>'required|in:deposit,withdraw,buy,sell,convert','symbol'=>'required|string|max:20','amount'=>'required|numeric|min:0.01|max:10000000','to_symbol'=>'nullable|string|max:20']);
        return DB::transaction(function() use($request,$data) {
            // Serialize all balance mutations for this account. This also makes first-wallet creation safe.
            $user=User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            $symbol=strtoupper($data['symbol']);
            if (in_array($data['type'], ['deposit','withdraw'], true) && $symbol !== 'USD') {
                throw ValidationException::withMessages(['symbol'=>'Demo deposits and withdrawals are USD-only.']);
            }
            $wallet=BrokerWallet::where('user_id',$user->id)->where('symbol',$symbol)->lockForUpdate()->first();
            if (!$wallet) $wallet=BrokerWallet::create(['user_id'=>$user->id,'symbol'=>$symbol,'balance'=>0]);
            $amount=(float)$data['amount'];
            $meta=['mode'=>'demo','to_symbol'=>$data['to_symbol']??null];
            if(in_array($data['type'],['withdraw','sell','convert']) && (float)$wallet->balance < $amount) throw ValidationException::withMessages(['amount'=>'Insufficient demo balance.']);
            if($data['type']==='deposit') $wallet->increment('balance',$amount);
            if($data['type']==='withdraw') $wallet->decrement('balance',$amount);
            if($data['type']==='buy') {
                $price=(float)(BrokerAsset::where('symbol',$symbol)->where('is_active',true)->value('price') ?? 0);
                if($price<=0 || $symbol==='USD') throw ValidationException::withMessages(['symbol'=>'Asset price is unavailable for this action.']);
                $usd=BrokerWallet::where('user_id',$user->id)->where('symbol','USD')->lockForUpdate()->first();
                if (!$usd) $usd=BrokerWallet::create(['user_id'=>$user->id,'symbol'=>'USD','balance'=>0]);
                $cost=$amount*$price;
                if ($cost < 0.01 || $cost > 10000000) throw ValidationException::withMessages(['amount'=>'Demo order value must be between $0.01 and $10,000,000.']);
                $meta['execution_price']=$price; $meta['amount_usd']=$cost;
                if((float)$usd->balance<$cost) throw ValidationException::withMessages(['amount'=>'Insufficient demo USD balance.']);
                $usd->decrement('balance',$cost); $wallet->increment('balance',$amount);
            }
            if($data['type']==='sell') {
                $price=(float)(BrokerAsset::where('symbol',$symbol)->where('is_active',true)->value('price') ?? 0);
                if($price<=0 || $symbol==='USD') throw ValidationException::withMessages(['symbol'=>'Asset price is unavailable for this action.']);
                $wallet->decrement('balance',$amount);
                $proceeds=$amount*$price;
                if ($proceeds < 0.01 || $proceeds > 10000000) throw ValidationException::withMessages(['amount'=>'Demo order value must be between $0.01 and $10,000,000.']);
                $meta['execution_price']=$price; $meta['amount_usd']=$proceeds;
                $usd=BrokerWallet::where('user_id',$user->id)->where('symbol','USD')->lockForUpdate()->first();
                if (!$usd) $usd=BrokerWallet::create(['user_id'=>$user->id,'symbol'=>'USD','balance'=>0]);
                $usd->increment('balance',$proceeds);
            }
            if($data['type']==='convert') {
                $to=strtoupper($data['to_symbol'] ?? '');
                if(!$to || $to===$symbol) throw ValidationException::withMessages(['to_symbol'=>'Choose a different destination asset.']);
                $fromPrice=(float)(BrokerAsset::where('symbol',$symbol)->where('is_active',true)->value('price') ?? 0);
                $toPrice=(float)(BrokerAsset::where('symbol',$to)->where('is_active',true)->value('price') ?? 0);
                if($fromPrice<=0 || $toPrice<=0) throw ValidationException::withMessages(['to_symbol'=>'One of the selected assets is unavailable.']);
                $target=BrokerWallet::where('user_id',$user->id)->where('symbol',$to)->lockForUpdate()->first();
                if (!$target) $target=BrokerWallet::create(['user_id'=>$user->id,'symbol'=>$to,'balance'=>0]);
                $targetQuantity=($amount*$fromPrice)/$toPrice;
                $conversionValue=$amount*$fromPrice;
                if ($conversionValue < 0.01 || $conversionValue > 10000000) throw ValidationException::withMessages(['amount'=>'Demo conversion value must be between $0.01 and $10,000,000.']);
                $meta['execution_price']=$fromPrice; $meta['to_price']=$toPrice;
                $meta['amount_usd']=$conversionValue; $meta['to_amount']=$targetQuantity;
                $wallet->decrement('balance',$amount);
                $target->increment('balance',$targetQuantity);
            }
            $wallet->refresh();
            $tx=BrokerTransaction::create(['user_id'=>$user->id,'type'=>$data['type'],'symbol'=>$symbol,'amount'=>$amount,'status'=>'completed','meta'=>$meta]);
            BrokerNotification::create(['user_id'=>$user->id,'title'=>'Demo '.ucfirst($data['type']).' completed','body'=>'Your demo '.$data['type'].' request for '.$symbol.' was recorded.']);
            return response()->json(['transaction'=>$tx,'wallet'=>$wallet,'mode'=>'demo'],201);
        });
    }

    public function openPosition(Request $request)
    {
        $d=$request->validate(['symbol'=>'required|string|max:20','side'=>'required|in:buy,sell','quantity'=>'required|numeric|gt:0','leverage'=>'required|integer|min:2|max:100','take_profit'=>'nullable|numeric|gt:0','stop_loss'=>'nullable|numeric|gt:0','duration_seconds'=>'nullable|integer|min:0|max:2592000']);
        return DB::transaction(function () use ($request,$d) {
            $account=User::whereKey($request->user()->id)->lockForUpdate()->firstOrFail();
            if (!empty($d['duration_seconds']) && (int)$d['duration_seconds'] < 10) {
                throw ValidationException::withMessages(['duration_seconds'=>'Duration must be at least 10 seconds.']);
            }
            $asset=BrokerAsset::where('symbol',strtoupper($d['symbol']))->where('is_active',true)->firstOrFail();
            $entry=(float)$asset->price;
            if (!empty($d['take_profit']) && (($d['side']==='buy' && (float)$d['take_profit']<=$entry) || ($d['side']==='sell' && (float)$d['take_profit']>=$entry))) {
                throw ValidationException::withMessages(['take_profit'=>'Take profit must be above entry for a buy and below entry for a sell.']);
            }
            if (!empty($d['stop_loss']) && (($d['side']==='buy' && (float)$d['stop_loss']>=$entry) || ($d['side']==='sell' && (float)$d['stop_loss']<=$entry))) {
                throw ValidationException::withMessages(['stop_loss'=>'Stop loss must be below entry for a buy and above entry for a sell.']);
            }
            $margin=((float)$d['quantity']*$entry)/(float)$d['leverage'];
            if ($margin < 0.01 || $margin > 10000000) {
                throw ValidationException::withMessages(['quantity'=>'Demo position margin must be between $0.01 and $10,000,000.']);
            }
            $usd=BrokerWallet::where('user_id',$request->user()->id)->where('symbol','USD')->lockForUpdate()->first();
            if (!$usd) $usd=BrokerWallet::create(['user_id'=>$request->user()->id,'symbol'=>'USD','balance'=>0]);
            if((float)$usd->balance<$margin) throw ValidationException::withMessages(['quantity'=>'Insufficient demo USD margin.']);
            $usd->decrement('balance',$margin);
            $position=BrokerPosition::create(['user_id'=>$request->user()->id,'symbol'=>$asset->symbol,'side'=>$d['side'],'quantity'=>$d['quantity'],'entry_price'=>$entry,'leverage'=>$d['leverage'],'margin'=>$margin,'take_profit'=>$d['take_profit']??null,'stop_loss'=>$d['stop_loss']??null,'expires_at'=>!empty($d['duration_seconds'])?now()->addSeconds((int)$d['duration_seconds']):null]);
            return response()->json(['position'=>$position,'mode'=>'demo'],201);
        });
    }

    private function settlePosition(int $positionId, string $reason): ?BrokerPosition
    {
        return DB::transaction(function () use ($positionId,$reason) {
            $position=BrokerPosition::whereKey($positionId)->lockForUpdate()->first();
            if (!$position || $position->status!=='open') return null;
            $price=(float)(BrokerAsset::where('symbol',$position->symbol)->value('price') ?? $position->entry_price);
            $direction=$position->side==='buy' ? 1 : -1;
            $rawPnl=((float)$position->quantity)*($price-(float)$position->entry_price)*$direction;
            $release=max(0,(float)$position->margin+$rawPnl);
            $pnl=$release-(float)$position->margin;
            $usd=BrokerWallet::where('user_id',$position->user_id)->where('symbol','USD')->lockForUpdate()->first();
            if (!$usd) $usd=BrokerWallet::create(['user_id'=>$position->user_id,'symbol'=>'USD','balance'=>0]);
            $usd->increment('balance',$release);
            $position->update(['status'=>'closed','closed_at'=>now(),'pnl'=>$pnl,'close_reason'=>$reason]);
            BrokerTransaction::create(['user_id'=>$position->user_id,'type'=>'position_close','symbol'=>$position->symbol,'amount'=>$release,'status'=>'completed','meta'=>['mode'=>'demo','pnl'=>$pnl,'reason'=>$reason,'close_price'=>$price]]);
            BrokerNotification::create(['user_id'=>$position->user_id,'title'=>$position->symbol.' position closed','body'=>'Your demo position closed: '.$reason.'.']);
            return $position->fresh();
        });
    }

    public function closePosition(Request $request, BrokerPosition $position)
    {
        abort_unless($position->user_id===$request->user()->id,404);
        abort_unless($position->status==='open',422);
        $closed=$this->settlePosition($position->id,'manual');
        abort_unless($closed,422);
        return response()->json(['position'=>$closed,'mode'=>'demo']);
    }

    public function settlePositions(Request $request)
    {
        $closed=[];
        $positions=BrokerPosition::where('user_id',$request->user()->id)->where('status','open')->get();
        foreach ($positions as $position) {
            $price=(float)(BrokerAsset::where('symbol',$position->symbol)->value('price') ?? $position->entry_price);
            $long=$position->side==='buy';
            $reason=null;
            $pnl=((float)$position->quantity)*($price-(float)$position->entry_price)*($long ? 1 : -1);
            if ($position->expires_at && $position->expires_at->isPast()) $reason='duration_ended';
            elseif ($pnl <= -(float)$position->margin) $reason='liquidated';
            elseif ($position->take_profit && ($long ? $price >= (float)$position->take_profit : $price <= (float)$position->take_profit)) $reason='take_profit';
            elseif ($position->stop_loss && ($long ? $price <= (float)$position->stop_loss : $price >= (float)$position->stop_loss)) $reason='stop_loss';
            if ($reason) {
                $row=$this->settlePosition($position->id,$reason);
                if ($row) $closed[]=['id'=>$row->id,'symbol'=>$row->symbol,'side'=>$row->side==='buy'?'long':'short','reason'=>$reason,'pnl'=>(float)$row->pnl];
            }
        }
        return response()->json($closed);
    }

    public function resetDemo(Request $request)
    {
        $userId=$request->user()->id;
        DB::transaction(function () use ($userId) {
            $user = User::whereKey($userId)->lockForUpdate()->firstOrFail();
            $openPositions = BrokerPosition::where('user_id',$userId)->where('status','open')->get();
            foreach ($openPositions as $position) {
                $this->settlePosition($position->id, 'manual');
            }
            $balances = BrokerWallet::where('user_id',$userId)->where('balance','>',0)->get();
            foreach ($balances as $wallet) {
                BrokerTransaction::create([
                    'user_id'=>$userId,'type'=>'demo_reset','symbol'=>$wallet->symbol,
                    'amount'=>-((float)$wallet->balance),'status'=>'completed',
                    'meta'=>['mode'=>'demo','reason'=>'user_requested_reset']
                ]);
            }
            BrokerWallet::where('user_id',$userId)->update(['balance'=>0]);
            app(\App\Services\DemoAccountService::class)->grantStartingBalances($user, 'reset');
            BrokerNotification::create(['user_id'=>$userId,'title'=>'Demo account reset','body'=>'Your demo balances were restored to their configured starting amounts and open demo positions were closed.']);
        });
        return response()->json(['reset'=>true,'mode'=>'demo']);
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

    public function services(Request $request)
    {
        return response()->json(BrokerServiceRequest::where('user_id',$request->user()->id)->latest()->get());
    }

    public function createService(Request $request)
    {
        $d=$request->validate(['service_key'=>'required|in:cold_storage,cards,subscribe,signals,connect_wallet,investing,copy_trading,mining,real_estate,stake','details'=>'nullable|string|max:2000']);
        $row=BrokerServiceRequest::create($d+['user_id'=>$request->user()->id]);
        return response()->json($row,201);
    }
}