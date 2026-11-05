<?php

namespace App\Http\Controllers;

use App\Models\{BrokerAsset,BrokerWallet,BrokerTransaction,BrokerPosition,BrokerServiceRequest,BrokerNotification};
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
        return response()->json(['profile'=>['id'=>$user->id,'email'=>$user->email,'full_name'=>$user->name,'role'=>$user->role ?? 'user'],'assets'=>$assets,'wallets'=>$wallets->values(),'positions'=>$positions,'transactions'=>BrokerTransaction::where('user_id',$user->id)->latest()->limit(50)->get()]);
    }

    public function transact(Request $request)
    {
        $data=$request->validate(['type'=>'required|in:deposit,withdraw,buy,sell,convert','symbol'=>'required|string|max:20','amount'=>'required|numeric|gt:0','to_symbol'=>'nullable|string|max:20']);
        return DB::transaction(function() use($request,$data) {
            $user=$request->user(); $symbol=strtoupper($data['symbol']);
            $wallet=BrokerWallet::firstOrCreate(['user_id'=>$user->id,'symbol'=>$symbol],['balance'=>0]);
            $amount=(float)$data['amount'];
            if(in_array($data['type'],['withdraw','sell','convert']) && (float)$wallet->balance < $amount) throw ValidationException::withMessages(['amount'=>'Insufficient demo balance.']);
            if($data['type']==='deposit') $wallet->balance=(float)$wallet->balance+$amount;
            if($data['type']==='withdraw') $wallet->balance=(float)$wallet->balance-$amount;
            if($data['type']==='buy') {
                $price=(float)(BrokerAsset::where('symbol',$symbol)->value('price') ?? 0);
                if($price<=0 || $symbol==='USD') throw ValidationException::withMessages(['symbol'=>'Asset price is unavailable for this action.']);
                $usd=BrokerWallet::firstOrCreate(['user_id'=>$user->id,'symbol'=>'USD'],['balance'=>0]);
                $cost=$amount*$price;
                if((float)$usd->balance<$cost) throw ValidationException::withMessages(['amount'=>'Insufficient demo USD balance.']);
                $usd->decrement('balance',$cost); $wallet->increment('balance',$amount);
            }
            if($data['type']==='sell') {
                $price=(float)(BrokerAsset::where('symbol',$symbol)->value('price') ?? 0);
                if($price<=0 || $symbol==='USD') throw ValidationException::withMessages(['symbol'=>'Asset price is unavailable for this action.']);
                $wallet->decrement('balance',$amount);
                $usd=BrokerWallet::firstOrCreate(['user_id'=>$user->id,'symbol'=>'USD'],['balance'=>0]);
                $usd->increment('balance',$amount*$price);
            }
            if($data['type']==='convert') {
                $to=strtoupper($data['to_symbol'] ?? '');
                if(!$to || $to===$symbol) throw ValidationException::withMessages(['to_symbol'=>'Choose a different destination asset.']);
                $fromPrice=(float)(BrokerAsset::where('symbol',$symbol)->value('price') ?? 0);
                $toPrice=(float)(BrokerAsset::where('symbol',$to)->value('price') ?? 0);
                if($fromPrice<=0 || $toPrice<=0) throw ValidationException::withMessages(['to_symbol'=>'One of the selected assets is unavailable.']);
                $target=BrokerWallet::firstOrCreate(['user_id'=>$user->id,'symbol'=>$to],['balance'=>0]);
                $wallet->decrement('balance',$amount);
                $target->increment('balance',($amount*$fromPrice)/$toPrice);
            }
            $wallet->refresh();
            $tx=BrokerTransaction::create(['user_id'=>$user->id,'type'=>$data['type'],'symbol'=>$symbol,'amount'=>$amount,'status'=>'completed','meta'=>['mode'=>'demo','to_symbol'=>$data['to_symbol']??null]]);
            return response()->json(['transaction'=>$tx,'wallet'=>$wallet,'mode'=>'demo'],201);
        });
    }

    public function openPosition(Request $request)
    {
        $d=$request->validate(['symbol'=>'required|string|max:20','side'=>'required|in:buy,sell','quantity'=>'required|numeric|gt:0','leverage'=>'required|numeric|min:1|max:100','take_profit'=>'nullable|numeric','stop_loss'=>'nullable|numeric']);
        return DB::transaction(function () use ($request,$d) {
            $asset=BrokerAsset::where('symbol',strtoupper($d['symbol']))->where('is_active',true)->firstOrFail();
            $margin=((float)$d['quantity']*(float)$asset->price)/(float)$d['leverage'];
            $usd=BrokerWallet::firstOrCreate(['user_id'=>$request->user()->id,'symbol'=>'USD'],['balance'=>0]);
            if((float)$usd->balance<$margin) throw ValidationException::withMessages(['quantity'=>'Insufficient demo USD margin.']);
            $usd->decrement('balance',$margin);
            $position=BrokerPosition::create(['user_id'=>$request->user()->id,'symbol'=>$asset->symbol,'side'=>$d['side'],'quantity'=>$d['quantity'],'entry_price'=>$asset->price,'leverage'=>$d['leverage'],'margin'=>$margin,'take_profit'=>$d['take_profit']??null,'stop_loss'=>$d['stop_loss']??null]);
            return response()->json(['position'=>$position,'mode'=>'demo'],201);
        });
    }

    public function closePosition(Request $request, BrokerPosition $position)
    {
        abort_unless($position->user_id===$request->user()->id,404);
        abort_unless($position->status==='open',422);
        return DB::transaction(function () use ($position) {
            $price=(float)(BrokerAsset::where('symbol',$position->symbol)->value('price') ?? $position->entry_price);
            $direction=$position->side==='buy' ? 1 : -1;
            $pnl=((float)$position->quantity)*($price-(float)$position->entry_price)*$direction;
            $release=max(0,(float)$position->margin+$pnl);
            $usd=BrokerWallet::firstOrCreate(['user_id'=>$position->user_id,'symbol'=>'USD'],['balance'=>0]);
            $usd->increment('balance',$release);
            $position->update(['status'=>'closed','closed_at'=>now(),'pnl'=>$pnl]);
            BrokerTransaction::create(['user_id'=>$position->user_id,'type'=>'position_close','symbol'=>$position->symbol,'amount'=>$release,'status'=>'completed','meta'=>['mode'=>'demo','pnl'=>$pnl]]);
            return response()->json(['position'=>$position->fresh(),'released_margin_and_pnl'=>$release,'mode'=>'demo']);
        });
    }

    public function services(Request $request)
    {
        return response()->json(BrokerServiceRequest::where('user_id',$request->user()->id)->latest()->get());
    }

    public function createService(Request $request)
    {
        $d=$request->validate(['service_key'=>'required|string|max:80','details'=>'nullable|string|max:3000']);
        $row=BrokerServiceRequest::create($d+['user_id'=>$request->user()->id]);
        return response()->json($row,201);
    }
}