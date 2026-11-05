<?php
// Reference trait for the host App\\Models\\User model. Add these methods to User.php,
// or use this trait in that model if your Laravel app supports traits.
namespace App\\Models;
trait UserBrokerageRelations {
    public function brokerServiceRequests() { return $this->hasMany(BrokerServiceRequest::class,'user_id'); }
}