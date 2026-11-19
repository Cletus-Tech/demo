<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class BrokerNotification extends Model {
    protected $fillable=['user_id','title','body','read_at'];
    protected $casts=['read_at'=>'datetime'];
}