<?php
namespace App\\Models;
use Illuminate\\Database\\Eloquent\\Model;
class BrokerAsset extends Model { protected $fillable=['symbol','name','category','price','is_active']; protected $casts=['price'=>'decimal:8','is_active'=>'boolean']; }