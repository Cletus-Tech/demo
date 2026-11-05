<?php
namespace App\\Models;
use Illuminate\\Database\\Eloquent\\Model;
class BrokerWallet extends Model { protected $fillable=['user_id','symbol','balance']; protected $casts=['balance'=>'decimal:8']; }