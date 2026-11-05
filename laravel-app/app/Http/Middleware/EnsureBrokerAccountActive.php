<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureBrokerAccountActive
{
    public function handle(Request $request, Closure $next): Response
    {
        abort_unless(($request->user()?->account_status ?? 'active') === 'active', 403, 'This account is suspended.');
        return $next($request);
    }
}