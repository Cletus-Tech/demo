<?php

namespace Database\\Seeders;

use App\\Models\\BrokerAsset;
use App\\Models\\User;
use Illuminate\\Database\\Seeder;
use Illuminate\\Support\\Facades\\Hash;
use Illuminate\\Support\\Str;
use InvalidArgumentException;

class BrokerDemoSeeder extends Seeder
{
    /**
     * Seed clearly labelled demo market data and, optionally, one ordinary
     * demo user supplied by the operator through environment variables.
     *
     * This seeder never creates an administrator or overwrites an existing
     * account password/status.
     */
    public function run(): void
    {
        $assets = [
            ['symbol' => 'BTC', 'name' => 'Bitcoin', 'category' => 'crypto', 'price' => 68000],
            ['symbol' => 'ETH', 'name' => 'Ethereum', 'category' => 'crypto', 'price' => 3500],
            ['symbol' => 'SOL', 'name' => 'Solana', 'category' => 'crypto', 'price' => 160],
            ['symbol' => 'USD', 'name' => 'US Dollar', 'category' => 'fiat', 'price' => 1],
            ['symbol' => 'EUR', 'name' => 'Euro', 'category' => 'fiat', 'price' => 1.08],
        ];

        foreach ($assets as $asset) {
            BrokerAsset::updateOrCreate(
                ['symbol' => $asset['symbol']],
                $asset + ['is_active' => true]
            );
        }

        $email = trim((string) env('BROKER_DEMO_USER_EMAIL', ''));
        $password = (string) env('BROKER_DEMO_USER_PASSWORD', '');

        if ($email === '' && $password === '') {
            return;
        }

        if (!filter_var($email, FILTER_VALIDATE_EMAIL) || strlen($password) < 12) {
            throw new InvalidArgumentException(
                'Set a valid BROKER_DEMO_USER_EMAIL and a BROKER_DEMO_USER_PASSWORD of at least 12 characters.'
            );
        }

        $name = trim((string) env('BROKER_DEMO_USER_NAME', 'Demo Trader')) ?: 'Demo Trader';
        $user = User::firstOrCreate(
            ['email' => $email],
            ['name' => $name, 'password' => Hash::make($password)]
        );

        // Existing users are deliberately left unchanged. Only give the new
        // or existing demo account a referral code if it does not have one.
        if (!$user->referral_code) {
            do {
                $code = Str::upper(Str::random(10));
            } while (User::where('referral_code', $code)->exists());

            $user->forceFill(['referral_code' => $code])->save();
        }
    }
}
