<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('broker_ledger_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('symbol', 20);
            $table->decimal('amount', 28, 10);
            $table->decimal('balance_after', 28, 10);
            $table->string('entry_type', 30);
            $table->uuid('group_id')->nullable();
            $table->text('memo')->nullable();
            $table->timestamp('created_at')->useCurrent();
            $table->index(['user_id', 'created_at']);
            $table->index('group_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('broker_ledger_entries');
    }
};
