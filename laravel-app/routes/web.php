<?php

use App\\Http\\Controllers\\DashboardController;
use Illuminate\\Support\\Facades\\Route;

Route::middleware('guest')->group(function () {
    Route::view('/login', 'auth.login')->name('login');
    Route::post('/login', [\\App\\Http\\Controllers\\Auth\\LoginController::class, 'store'])->name('login.store');
    Route::view('/register', 'auth.register')->name('register');
    Route::post('/register', [\\App\\Http\\Controllers\\Auth\\RegisterController::class, 'store'])->name('register.store');
});

Route::post('/logout', [\\App\\Http\\Controllers\\Auth\\LoginController::class, 'destroy'])->middleware('auth')->name('logout');
Route::get('/', fn () => redirect()->route('dashboard'));
Route::get('/dashboard', DashboardController::class)->middleware('auth')->name('dashboard');
