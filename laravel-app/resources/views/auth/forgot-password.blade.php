<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Reset password</title>
<style>body{margin:0;background:#07090c;color:#edf2f7;font:15px system-ui;display:grid;min-height:100vh;place-items:center}.card{width:min(420px,calc(100% - 40px));background:#10151b;border:1px solid #202a34;border-radius:18px;padding:30px;box-sizing:border-box}h1{margin:0 0 8px}p{color:#9aa7b5}label{display:block;margin:18px 0 7px}input{width:100%;box-sizing:border-box;padding:13px;border-radius:9px;border:1px solid #293440;background:#090e13;color:white}button{width:100%;padding:13px;border:0;border-radius:9px;background:#00b894;color:#001b16;font-weight:700;margin-top:22px;cursor:pointer}.error{color:#ff7777;font-size:13px}.status{color:#6ee7b7;font-size:13px}</style></head>
<body><main class="card"><h1>Forgot password?</h1><p>Enter your account email and we’ll send a secure password reset link.</p>
@if(session('status'))<p class="status">{{ session('status') }}</p>@endif
@if($errors->any())<div class="error">{{ $errors->first() }}</div>@endif
<form method="POST" action="{{ route('password.email') }}">@csrf<label>Email address</label><input type="email" name="email" value="{{ old('email') }}" required autocomplete="email"><button type="submit">Send reset link</button></form>
<p><a style="color:#45c9ad" href="{{ route('login') }}">Back to sign in</a></p></main></body></html>
