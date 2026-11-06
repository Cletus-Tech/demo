<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\AdminController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use App\Http\Middleware\EnsureBrokerAccountActive;
use Illuminate\Support\Facades\Route;

Route::middleware('guest:web')->group(function () {
    Route::view('/login', 'auth.login')->name('login');
    Route::post('/login', [LoginController::class, 'store'])->name('login.store');
    Route::view('/register', 'auth.register')->name('register');
    Route::post('/register', [RegisterController::class, 'store'])->name('register.store');
});

Route::post('/logout', [LoginController::class, 'destroy'])->middleware('auth:web')->name('logout');
Route::get('/', fn () => redirect()->route('dashboard'));
Route::get('/dashboard', DashboardController::class)
    ->middleware(['auth:web', EnsureBrokerAccountActive::class])
    ->name('dashboard');

Route::middleware(['auth:web', EnsureBrokerAccountActive::class])->prefix('admin')->name('admin.')->group(function () {
    Route::get('/', [AdminController::class, 'index'])->name('index');
    Route::patch('/users/{user}', [AdminController::class, 'updateUser'])->name('users.update');
    Route::patch('/services/{serviceRequest}', [AdminController::class, 'updateService'])->name('services.update');
});
