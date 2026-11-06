<?php

namespace App\Http\Controllers\Auth;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class RegisterController
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => 'required|string|max:120',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|confirmed|min:8',
            'referral_code' => 'nullable|string|size:10|alpha_num',
        ]);

        $referrerId = null;
        $submittedCode = strtoupper(trim($data['referral_code'] ?? ''));
        if ($submittedCode !== '') {
            $referrer = User::where('referral_code', $submittedCode)->first();
            if (!$referrer) {
                throw ValidationException::withMessages([
                    'referral_code' => 'That referral code could not be found.',
                ]);
            }
            $referrerId = $referrer->id;
        }

        $user = DB::transaction(function () use ($data, $referrerId) {
            $user = User::create([
                'name' => $data['name'],
                'email' => $data['email'],
                'password' => bcrypt($data['password']),
            ]);

            $user->forceFill([
                'referral_code' => $this->newReferralCode(),
                'referred_by' => $referrerId,
            ])->save();

            return $user;
        }, 3);

        Auth::login($user);
        $request->session()->regenerate();

        return redirect()->route('dashboard');
    }

    private function newReferralCode(): string
    {
        do {
            $code = Str::upper(Str::random(10));
        } while (User::where('referral_code', $code)->exists());

        return $code;
    }
}
