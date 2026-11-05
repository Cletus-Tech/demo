<?php

use App\Http\Controllers\BrokerApiController;
use App\Http\Middleware\EnsureBrokerAccountActive;
use Illuminate\Support\Facades\Route;

Route::middleware(['auth:sanctum', EnsureBrokerAccountActive::class])->prefix('broker')->group(function () {
    Route::get('/state',[BrokerApiController::class,'state']);
    Route::post('/prices/refresh',[BrokerApiController::class,'refreshDemoPrices']);
    Route::post('/transactions',[BrokerApiController::class,'transact']);
    Route::post('/reset',[BrokerApiController::class,'resetDemo']);
    Route::post('/positions',[BrokerApiController::class,'openPosition']);
    Route::post('/positions/settle',[BrokerApiController::class,'settlePositions']);
    Route::post('/positions/{position}/close',[BrokerApiController::class,'closePosition']);
    Route::get('/notifications',[BrokerApiController::class,'notifications']);
    Route::get('/referrals',[BrokerApiController::class,'referrals']);
    Route::post('/notifications/read',[BrokerApiController::class,'markNotificationsRead']);
    Route::patch('/profile',[BrokerApiController::class,'updateProfile']);
    Route::get('/services',[BrokerApiController::class,'services']);
    Route::post('/services',[BrokerApiController::class,'createService']);
});