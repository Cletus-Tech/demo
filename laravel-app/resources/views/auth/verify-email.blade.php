<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#07090c">
<title>Confirm your email · Demo Broker</title>
<style>
:root{--bg:#07090c;--panel:#0d1014;--line:#1a1f26;--text:#f2f5f8;--mute:#8b94a1;--blue:#2d9cff;--green:#0fb58a}
*{box-sizing:border-box}
body{margin:0;min-height:100vh;display:grid;place-items:center;padding:20px;background:var(--bg);color:var(--text);font:15px/1.5 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}
.card{width:100%;max-width:430px;background:var(--panel);border:1px solid var(--line);border-radius:16px;padding:26px}
h1{font-size:21px;margin:0 0 8px}
p{color:var(--mute);margin:8px 0 16px}
.notice{background:#1a2230;border:1px solid #27405f;color:#9cc7f5;border-radius:10px;padding:12px;font-size:13px}
.ok{background:#102b22;border:1px solid #1e5945;color:#8de2be;border-radius:9px;padding:10px;margin:12px 0;font-size:13px}
button{width:100%;margin-top:18px;padding:12px;border:0;border-radius:9px;background:var(--blue);color:#fff;font:inherit;font-weight:650;cursor:pointer}
a{color:var(--blue)}
.secondary{display:block;text-align:center;margin-top:16px;font-size:13px}
</style>
</head>
<body>
<main class="card">
<h1>Confirm your email address</h1>
<p>One more step before you enter your Demo Broker account.</p>
<div class="notice">We sent a confirmation link to <strong>{{ auth()->user()->email }}</strong>. Open that email and click the link to verify your address. Check your spam folder if you cannot find it.</div>
@if(session('status'))<div class="ok" role="status">{{ session('status') }}</div>@endif
<form method="POST" action="{{ route('verification.send') }}">@csrf<button type="submit">Resend confirmation email</button></form>
<a class="secondary" href="{{ route('logout') }}" onclick="event.preventDefault();document.getElementById('logout-form').submit();">Sign out</a>
<form id="logout-form" method="POST" action="{{ route('logout') }}" hidden>@csrf</form>
</main>
</body>
</html>
