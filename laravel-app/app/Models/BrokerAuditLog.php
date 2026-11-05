<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BrokerAuditLog extends Model
{
    public $timestamps = false;

    protected $fillable = ['actor_id', 'action', 'target_type', 'target_id', 'details', 'created_at'];

    protected $casts = ['details' => 'array', 'created_at' => 'datetime'];

    protected static function booted(): void
    {
        static::updating(fn () => throw new \LogicException('Administrator audit logs are append-only.'));
        static::deleting(fn () => throw new \LogicException('Administrator audit logs are append-only.'));
    }
}
