<?php

use Illuminate\Support\Facades\Artisan;

Artisan::command('broker:demo-info', function () {
    $this->info('Demo Broker uses simulated practice balances and prices only.');
})->purpose('Display demo-only operating information');
