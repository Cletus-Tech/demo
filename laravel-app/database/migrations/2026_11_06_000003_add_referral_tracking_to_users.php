<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'referral_code')) {
                $table->string('referral_code', 10)->nullable()->unique();
            }
            if (!Schema::hasColumn('users', 'referred_by')) {
                $table->foreignId('referred_by')->nullable()->constrained('users')->nullOnDelete();
            }
        });

        DB::table('users')->whereNull('referral_code')->orderBy('id')->chunkById(100, function ($users) {
            foreach ($users as $user) {
                do {
                    $code = Str::upper(Str::random(10));
                } while (DB::table('users')->where('referral_code', $code)->exists());

                DB::table('users')->where('id', $user->id)->update(['referral_code' => $code]);
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'referred_by')) {
                $table->dropForeign(['referred_by']);
                $table->dropColumn('referred_by');
            }
            if (Schema::hasColumn('users', 'referral_code')) {
                $table->dropUnique(['referral_code']);
                $table->dropColumn('referral_code');
            }
        });
    }
};
