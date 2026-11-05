<?php
namespace App\\Models;
use Illuminate\\Database\\Eloquent\\Model;
class BrokerServiceRequest extends Model { protected $table='broker_service_requests'; protected $fillable=['user_id','service_key','details','status']; }