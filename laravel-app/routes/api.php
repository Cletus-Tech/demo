<?php

use App\Http\Controllers\BrokerApiController;
use Illuminate\Support\Facades\Route;

Route::middleware('auth:sanctum')->prefix('broker')->group(function () {
    Route::get('/state',[BrokerApiController::class,'state']);
    Route::post('/transactions',[BrokerApiController::class,'transact']);
    Route::post('/positions',[BrokerApiController::class,'openPosition']);
    Route::post('/positions/{position}/close',[BrokerApiController::class,'closePosition']);
    Route::get('/notifications',[BrokerApiController::class,'notifications']);\n    Route::post('/notifications/read',[BrokerApiController::class,'markNotificationsRead']);\n    Route::patch('/profile',[BrokerApiController::class,'updateProfile']);\n    Route::get('/services',[BrokerApiController::class,'services']);
    Route::post('/services',[BrokerApiController::class,'createService']);
});