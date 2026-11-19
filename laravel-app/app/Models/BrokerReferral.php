<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BrokerReferral extends Model
{
    protected $fillable = ['referrer_id', 'referred_id', 'status'];
}
