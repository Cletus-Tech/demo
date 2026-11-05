<?php

namespace App\Http\Controllers\Auth;

use App\Models\BrokerReferral;
use App\Models\User;
use App\Services\DemoAccountService;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Throwable;

class RegisterController
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|confirmed|min:8',
            'ref' => 'nullable|string|max:12',
        ]);

        $referrer = null;
        if (!empty($data['ref'])) {
            $referrer = User::where('referral_code', strtoupper(trim($data['ref'])))->first();
        }

        do {
            $referralCode = Str::upper(Str::random(8));
        } while (User::where('referral_code', $referralCode)->exists());

        $user = DB::transaction(function () use ($data, $referrer, $referralCode) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => $data['password'],
                'referral_code' => $referralCode,
                'referred_by' => $referrer?->id,
            ]);

            if ($referrer) {
                BrokerReferral::create([
                    'referrer_id' => $referrer->id,
                    'referred_id' => $user->id,
                    'status' => 'pending',
                ]);
            }

            try {
                DB::transaction(fn () => app(DemoAccountService::class)->grantStartingBalances($user, 'signup'));
            } catch (Throwable $exception) {
                report($exception);
            }

            return $user;
        });
        event(new Registered($user));
        Auth::login($user);
        $request->session()->regenerate();

        return redirect()->route('verification.notice');
    }
}
