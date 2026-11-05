<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class BrokerLedgerEntry extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id', 'symbol', 'amount', 'balance_after',
        'entry_type', 'group_id', 'memo', 'created_at',
    ];

    protected $casts = [
        'amount' => 'decimal:8',
        'balance_after' => 'decimal:8',
        'created_at' => 'datetime',
    ];

    protected static function booted(): void
    {
        static::updating(fn () => throw new \LogicException('Demo ledger entries are append-only.'));
        static::deleting(fn () => throw new \LogicException('Demo ledger entries are append-only.'));
    }
}
