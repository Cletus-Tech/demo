<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('broker_assets', function (Blueprint $table) {
            $table->id(); $table->string('symbol', 20)->unique(); $table->string('name');
            $table->string('category', 40)->default('crypto'); $table->decimal('price', 28, 10)->default(1); $table->decimal('demo_anchor', 28, 10)->default(1);
            $table->boolean('is_active')->default(true); $table->timestamps();
        });
        Schema::create('broker_wallets', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('symbol', 20); $table->decimal('balance', 28, 10)->default(0);
            $table->timestamps(); $table->unique(['user_id','symbol']);
        });
        Schema::create('broker_transactions', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type', 30); $table->string('symbol', 20)->nullable();
            $table->decimal('amount', 28, 10); $table->string('status', 20)->default('completed');
            $table->json('meta')->nullable(); $table->timestamps();
        });
        Schema::create('broker_positions', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('symbol',20); $table->string('side',10); $table->decimal('quantity',28,10);
            $table->decimal('entry_price',28,10); $table->decimal('leverage',8,2)->default(1); $table->decimal('margin',28,10)->default(0);
            $table->decimal('take_profit',28,10)->nullable(); $table->decimal('stop_loss',28,10)->nullable();
            $table->string('status',20)->default('open'); $table->decimal('pnl',28,10)->default(0);
            $table->timestamp('closed_at')->nullable(); $table->timestamp('expires_at')->nullable(); $table->string('close_reason',30)->nullable(); $table->timestamps();
        });
        Schema::create('broker_notifications', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('title'); $table->text('body')->nullable(); $table->timestamp('read_at')->nullable(); $table->timestamps();
        });
        Schema::create('broker_service_requests', function (Blueprint $table) {
            $table->id(); $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('service_key',80); $table->text('details')->nullable();
            $table->string('status',20)->default('pending'); $table->timestamps();
        });

        DB::table('broker_assets')->insert([
            ['symbol'=>'BTC','name'=>'Bitcoin','category'=>'crypto','price'=>80000,'demo_anchor'=>80000,'is_active'=>true,'created_at'=>now(),'updated_at'=>now()],
            ['symbol'=>'ETH','name'=>'Ethereum','category'=>'crypto','price'=>2500,'demo_anchor'=>2500,'is_active'=>true,'created_at'=>now(),'updated_at'=>now()],
            ['symbol'=>'USD','name'=>'United States Dollar','category'=>'fiat','price'=>1,'demo_anchor'=>1,'is_active'=>true,'created_at'=>now(),'updated_at'=>now()],
            ['symbol'=>'SOL','name'=>'Solana','category'=>'crypto','price'=>100,'demo_anchor'=>100,'is_active'=>true,'created_at'=>now(),'updated_at'=>now()],
            ['symbol'=>'AAPL','name'=>'Apple','category'=>'stocks','price'=>200,'demo_anchor'=>200,'is_active'=>true,'created_at'=>now(),'updated_at'=>now()],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('broker_service_requests'); Schema::dropIfExists('broker_notifications');
        Schema::dropIfExists('broker_positions'); Schema::dropIfExists('broker_transactions');
        Schema::dropIfExists('broker_wallets'); Schema::dropIfExists('broker_assets');
    }
};