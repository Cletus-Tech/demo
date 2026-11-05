<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = ['name', 'email', 'password', 'phone', 'country'];
    protected $hidden = ['password', 'remember_token'];
    protected function casts(): array
    {
        return ['email_verified_at' => 'datetime', 'password' => 'hashed'];
    }

    public function brokerWallets() { return $this->hasMany(BrokerWallet::class); }
    public function brokerTransactions() { return $this->hasMany(BrokerTransaction::class); }
    public function brokerPositions() { return $this->hasMany(BrokerPosition::class); }
    public function brokerNotifications() { return $this->hasMany(BrokerNotification::class); }
    public function brokerServiceRequests() { return $this->hasMany(BrokerServiceRequest::class); }
}
