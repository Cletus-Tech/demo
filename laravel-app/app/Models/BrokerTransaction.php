<?php
namespace App\\Models;
use Illuminate\\Database\\Eloquent\\Model;
class BrokerTransaction extends Model { protected $fillable=['user_id','type','symbol','amount','status','meta']; protected $casts=['amount'=>'decimal:8','meta'=>'array']; }