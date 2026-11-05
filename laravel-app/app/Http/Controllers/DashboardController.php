<?php

namespace App\\Http\\Controllers;

use Illuminate\\Support\\Facades\\Auth;

class DashboardController
{
    public function __invoke()
    {
        return view('dashboard', ['user' => Auth::user()]);
    }
}
