<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class BrokerPosition extends Model { protected $fillable=['user_id','symbol','side','quantity','entry_price','leverage','margin','take_profit','stop_loss','status','pnl','closed_at','expires_at','close_reason']; protected $casts=['quantity'=>'decimal:10','entry_price'=>'decimal:10','leverage'=>'decimal:2','margin'=>'decimal:10','take_profit'=>'decimal:10','stop_loss'=>'decimal:10','pnl'=>'decimal:10','closed_at'=>'datetime','expires_at'=>'datetime']; }