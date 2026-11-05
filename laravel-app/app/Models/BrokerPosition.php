<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class BrokerPosition extends Model { protected $fillable=['user_id','symbol','side','quantity','entry_price','leverage','take_profit','stop_loss','status','pnl','closed_at']; protected $casts=['quantity'=>'decimal:8','entry_price'=>'decimal:8','leverage'=>'decimal:2','take_profit'=>'decimal:8','stop_loss'=>'decimal:8','pnl'=>'decimal:8','closed_at'=>'datetime']; }