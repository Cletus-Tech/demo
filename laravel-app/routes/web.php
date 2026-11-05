<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\Auth\LoginController;
use App\Http\Controllers\Auth\RegisterController;
use Illuminate\Support\Facades\Route;

Route::middleware('guest')->group(function () {
    Route::view('/login', 'auth.login')->name('login');
    Route::post('/login', [LoginController::class, 'store'])->name('login.store');
    Route::view('/register', 'auth.register')->name('register');
    Route::post('/register', [RegisterController::class, 'store'])->name('register.store');
});

Route::post('/logout', [LoginController::class, 'destroy'])->middleware('auth')->name('logout');
Route::get('/', fn () => redirect()->route('dashboard'));
Route::get('/dashboard', DashboardController::class)->middleware('auth')->name('dashboard');\nRoute::middleware('auth')->prefix('admin')->name('admin.')->group(function () {\n    Route::get('/', [AdminController::class, 'index'])->name('index');\n    Route::patch('/users/{user}', [AdminController::class, 'updateUser'])->name('users.update');\n    Route::patch('/services/{serviceRequest}', [AdminController::class, 'updateService'])->name('services.update');\n});
