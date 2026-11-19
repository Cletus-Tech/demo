<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class BrokerAsset extends Model { protected $fillable=['symbol','name','category','price','demo_anchor','is_active']; protected $casts=['price'=>'decimal:10','demo_anchor'=>'decimal:10','is_active'=>'boolean']; }