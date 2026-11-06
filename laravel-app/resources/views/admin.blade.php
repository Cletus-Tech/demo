<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="theme-color" content="#07090c">
<title>Broker administration</title>
<style>
*{box-sizing:border-box}
body{margin:0;background:#07090c;color:#edf2f7;font:14px/1.5 system-ui,-apple-system,Segoe UI,sans-serif;padding:20px}
main{max-width:1240px;margin:0 auto}
.top{display:flex;justify-content:space-between;align-items:center;gap:16px;margin-bottom:20px}
h1{font-size:24px;margin:0 0 4px}h2{font-size:17px;margin:0 0 14px}
p,.muted{color:#9aa7b5;margin:0}
a{color:#56b4ff;text-decoration:none}
.panel{background:#10151b;border:1px solid #202a34;border-radius:14px;padding:18px;margin:14px 0}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse;min-width:760px}
th,td{text-align:left;padding:11px 10px;border-bottom:1px solid #202a34;vertical-align:middle}
th{color:#9aa7b5;font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.04em}
td{font-size:13px}
select{max-width:100%;background:#090e13;color:#edf2f7;border:1px solid #293440;padding:8px;border-radius:8px}
button{background:#168b70;color:#fff;border:0;border-radius:8px;padding:8px 12px;cursor:pointer;font-weight:600}
button:hover{filter:brightness(1.08)}
.actions{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.flash{background:#103b30;color:#9ff0d6;padding:11px 13px;border-radius:9px;margin-bottom:14px}
.errors{background:#3b171a;color:#ffc0c4;padding:11px 13px;border-radius:9px;margin-bottom:14px}
@media(max-width:600px){body{padding:12px}.top{align-items:flex-start;flex-direction:column}.panel{padding:13px}}
</style>
</head>
<body>
<main>
<header class="top">
  <div><h1>Administration</h1><p>Demo brokerage management · {{ auth()->user()->email }}</p></div>
  <a href="{{ route('dashboard') }}">← Back to dashboard</a>
</header>
@if(session('status'))<div class="flash">{{ session('status') }}</div>@endif
@if($errors->any())<div class="errors">{{ $errors->first() }}</div>@endif

<section class="panel">
  <h2>User accounts <span class="muted">({{ $users->count() }})</span></h2>
  <div class="table-wrap">
    <table>
      <thead><tr><th>User</th><th>Email</th><th>Role</th><th>Status</th><th>Joined</th><th>Save</th></tr></thead>
      <tbody>
      @forelse($users as $user)
        <tr>
          <td>{{ $user->name }}</td>
          <td>{{ $user->email }}</td>
          <td>
            <form id="user-form-{{ $user->id }}" method="POST" action="{{ route('admin.users.update',$user) }}">
              @csrf
              @method('PATCH')
              <select name="role" aria-label="Role for {{ $user->email }}">
                <option value="user" @selected($user->role==='user')>User</option>
                <option value="support" @selected($user->role==='support')>Support</option>
                <option value="admin" @selected($user->role==='admin')>Admin</option>
                <option value="superadmin" @selected($user->role==='superadmin')>Superadmin</option>
              </select>
            </form>
          </td>
          <td>
            <select name="account_status" form="user-form-{{ $user->id }}" aria-label="Account status for {{ $user->email }}">
              <option value="active" @selected($user->account_status==='active')>Active</option>
              <option value="suspended" @selected($user->account_status==='suspended')>Suspended</option>
            </select>
          </td>
          <td class="muted">{{ $user->created_at?->format('Y-m-d') }}</td>
          <td><button type="submit" form="user-form-{{ $user->id }}">Save</button></td>
        </tr>
      @empty
        <tr><td colspan="6">No accounts found.</td></tr>
      @endforelse
      </tbody>
    </table>
  </div>
</section>

<section class="panel">
  <h2>Service enquiries <span class="muted">({{ $requests->count() }})</span></h2>
  <div class="table-wrap">
    <table>
      <thead><tr><th>Service</th><th>User ID</th><th>Details</th><th>Current status</th><th>Update</th></tr></thead>
      <tbody>
      @forelse($requests as $item)
        <tr>
          <td>{{ $item->service_key }}</td>
          <td>{{ $item->user_id }}</td>
          <td>{{ $item->details ?: '—' }}</td>
          <td>{{ ucfirst(str_replace('_',' ',$item->status)) }}</td>
          <td>
            <form class="actions" method="POST" action="{{ route('admin.services.update',$item) }}">
              @csrf
              @method('PATCH')
              <select name="status" aria-label="Status for service enquiry {{ $item->id }}">
                @foreach(['pending','in_review','approved','declined','closed'] as $status)
                  <option value="{{ $status }}" @selected($item->status===$status)>{{ ucfirst(str_replace('_',' ',$status)) }}</option>
                @endforeach
              </select>
              <button type="submit">Save</button>
            </form>
          </td>
        </tr>
      @empty
        <tr><td colspan="5">No service enquiries yet.</td></tr>
      @endforelse
      </tbody>
    </table>
  </div>
</section>
</main>
</body>
</html>
