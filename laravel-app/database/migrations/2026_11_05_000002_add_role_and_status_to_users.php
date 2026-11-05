<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'role')) $table->string('role', 30)->default('user');
            if (!Schema::hasColumn('users', 'account_status')) $table->string('account_status', 20)->default('active');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'account_status')) $table->dropColumn('account_status');
            if (Schema::hasColumn('users', 'role')) $table->dropColumn('role');
        });
    }
};