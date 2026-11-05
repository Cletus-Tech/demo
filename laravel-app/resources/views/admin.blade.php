<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Broker administration</title>
<style>
*{box-sizing:border-box}body{margin:0;background:#07090c;color:#edf2f7;font:14px/1.5 system-ui,sans-serif;padding:24px}main{max-width:1180px;margin:auto}.top{display:flex;justify-content:space-between;align-items:center;gap:12px;margin-bottom:20px}.panel{background:#10151b;border:1px solid #202a34;border-radius:14px;padding:18px;margin:14px 0;overflow:auto}h1{font-size:24px}h2{font-size:17px;margin-bottom:12px}p,.muted{color:#9aa7b5}a{color:#56b4ff;text-decoration:none}button{background:#168b70;color:#fff;border:0;border-radius:8px;padding:8px 12px;cursor:pointer}select{background:#090e13;color:#edf2f7;border:1px solid #293440;padding:8px;border-radius:8px}table{width:100%;border-collapse:collapse;min-width:700px}th,td{text-align:left;padding:10px;border-bottom:1px solid #202a34;vertical-align:middle}th{color:#9aa7b5;font-weight:600}.flash{background:#103b30;color:#9ff0d6;padding:10px;border-radius:8px;margin-bottom:14px}.actions{display:flex;gap:6px;align-items:center}.actions form{margin:0}.btn{display:inline-block;background:#171b21;color:#edf2f7;border:1px solid #293440;border-radius:8px;padding:8px 12px;text-decoration:none;cursor:pointer}
textarea{background:#090e13;color:#edf2f7;border:1px solid #293440;border-radius:8px;padding:8px;min-width:180px;max-width:260px}.cards{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin:14px 0}.metric{background:#0d1014;border:1px solid #1a1f26;border-radius:13px;padding:14px}.metric span{display:block;color:#8b94a1;font-size:12px}.metric b{display:block;font-size:23px;margin-top:4px}@media(max-width:760px){.cards{grid-template-columns:repeat(2,minmax(0,1fr))}} </style></head><body><main>
<div class="top"><div><h1>Administration</h1><p>Demo brokerage management · {{ auth()->user()->email }}</p></div><div class="actions"><a class="btn" href="{{ route('admin.index') }}">Refresh data</a><a class="btn" href="{{ route('dashboard') }}">← Back to dashboard</a><form method="POST" action="{{ route('logout') }}">@csrf<button class="btn" type="submit">Sign out</button></form></div></div>
@if(session('status'))<div class="flash">{{ session('status') }}</div>@endif
<section class="cards"><div class="metric"><span>Registered users loaded</span><b>{{ $users->count() }}</b></div><div class="metric"><span>Orders / transactions loaded</span><b>{{ $transactions->count() }}</b></div><div class="metric"><span>Open positions loaded</span><b>{{ $positions->where('status','open')->count() }}</b></div><div class="metric"><span>Ledger entries loaded</span><b>{{ $ledger->count() }}</b></div></section>
<section class="panel"><h2>User accounts</h2><table><thead><tr><th>User</th><th>Email</th><th>Role</th><th>Status</th><th>Joined</th><th>Update</th></tr></thead><tbody>
@forelse($users as $user)<tr>
<td>{{ $user->name }}</td>
<td>{{ $user->email }}</td>
<td>
@if(auth()->user()->role==='superadmin' && auth()->id()!==$user->id)
<form class="actions" method="POST" action="{{ route('admin.users.update',$user) }}">@csrf @method('PATCH')
<input type="hidden" name="account_status" value="{{ $user->account_status }}">
<select name="role"><option value="user" @selected($user->role==='user')>User</option><option value="support" @selected($user->role==='support')>Support</option><option value="admin" @selected($user->role==='admin')>Admin</option><option value="superadmin" @selected($user->role==='superadmin')>Superadmin</option></select>
<button>Save role</button></form>
@else{{ ucfirst($user->role ?? 'user') }}@endif
</td>
<td>
<form class="actions" method="POST" action="{{ route('admin.users.update',$user) }}">@csrf @method('PATCH')
<input type="hidden" name="role" value="{{ $user->role ?? 'user' }}">
<select name="account_status"><option value="active" @selected($user->account_status==='active')>Active</option><option value="suspended" @selected($user->account_status==='suspended')>Suspended</option></select>
<button>Save</button></form>
</td>
<td>{{ $user->created_at?->format('Y-m-d') }}</td>
<td class="muted">Account controls</td>
</tr>@empty<tr><td colspan="6">No accounts found.</td></tr>@endforelse
</tbody></table></section>
<section class="panel"><h2>Service enquiries</h2><table><thead><tr><th>Service</th><th>User ID</th><th>Details</th><th>Status</th><th>Update</th></tr></thead><tbody>
@forelse($requests as $item)<tr><td>{{ $item->service_key }}</td><td>{{ $item->user_id }}</td><td>{{ $item->details ?: '—' }}</td><td>{{ $item->status }}</td><td><form class="actions" method="POST" action="{{ route('admin.services.update',$item) }}">@csrf @method('PATCH')<select name="status">@foreach(['pending','in_review','approved','declined','closed'] as $status)<option value="{{ $status }}" @selected($item->status===$status)>{{ ucfirst(str_replace('_',' ',$status)) }}</option>@endforeach</select><textarea name="admin_note" rows="2" placeholder="Private admin note">{{ $item->admin_note }}</textarea><button>Save</button></form></td></tr>@empty<tr><td colspan="5">No service enquiries yet.</td></tr>@endforelse
</tbody></table></section>

<section class="panel"><h2>Demo wallet balances</h2><p>Practice balances only. No real customer funds are held.</p><table><thead><tr><th>User ID</th><th>Asset</th><th>Balance</th><th>Updated</th></tr></thead><tbody>
@forelse($wallets as $wallet)<tr><td>{{ $wallet->user_id }}</td><td>{{ $wallet->symbol }}</td><td>{{ number_format((float)$wallet->balance,8) }}</td><td>{{ $wallet->updated_at?->format('Y-m-d H:i') }}</td></tr>@empty<tr><td colspan="4">No demo wallets yet.</td></tr>@endforelse
</tbody></table></section>
<section class="panel"><h2>Recent demo positions</h2><table><thead><tr><th>User ID</th><th>Asset</th><th>Side</th><th>Quantity</th><th>Leverage</th><th>Margin USD</th><th>Status</th><th>P&amp;L USD</th><th>Close reason</th></tr></thead><tbody>
@forelse($positions as $position)<tr><td>{{ $position->user_id }}</td><td>{{ $position->symbol }}</td><td>{{ $position->side === 'buy' ? 'LONG' : 'SHORT' }}</td><td>{{ number_format((float)$position->quantity,8) }}</td><td>{{ $position->leverage }}x</td><td>{{ number_format((float)$position->margin,2) }}</td><td>{{ $position->status }}</td><td>{{ number_format((float)$position->pnl,2) }}</td><td>{{ $position->close_reason ?: '—' }}</td></tr>@empty<tr><td colspan="9">No demo positions yet.</td></tr>@endforelse
</tbody></table></section>
<section class="panel"><h2>Recent demo orders and transactions</h2><table><thead><tr><th>Time</th><th>User ID</th><th>Type</th><th>Side</th><th>Asset / route</th><th>Price</th><th>Quantity</th><th>Leverage</th><th>Amount USD</th><th>Status</th><th>Mode</th></tr></thead><tbody>
@forelse($transactions as $transaction)<tr>
<td>{{ $transaction->created_at?->format('Y-m-d H:i') }}</td><td>{{ $transaction->user_id }}</td><td>{{ $transaction->type }}</td>
<td>{{ data_get($transaction->meta, 'side', in_array($transaction->type, ['buy','sell','convert'], true) ? $transaction->type : '—') }}</td>
<td>{{ $transaction->type === 'convert' ? $transaction->symbol.' → '.data_get($transaction->meta, 'to_symbol', '?') : ($transaction->symbol ?: '—') }}</td>
<td>{{ number_format((float)data_get($transaction->meta, 'execution_price', data_get($transaction->meta, 'entry_price', 0)),10) }}</td>
<td>{{ number_format((float)data_get($transaction->meta, 'quantity', in_array($transaction->type, ['buy','sell','convert'], true) ? $transaction->amount : 0),10) }}</td>
<td>{{ data_get($transaction->meta, 'leverage', '—') }}</td>
<td>{{ number_format((float)data_get($transaction->meta, 'amount_usd', $transaction->amount),2) }}</td><td>{{ $transaction->status }}</td><td>Demo</td>
</tr>@empty<tr><td colspan="11">No demo transactions yet.</td></tr>@endforelse
</tbody></table></section>

<section class="panel"><h2>Append-only demo wallet ledger</h2><p>Every wallet credit and debit is recorded with the balance immediately after the entry.</p><table><thead><tr><th>Time</th><th>User ID</th><th>Asset</th><th>Amount</th><th>Balance after</th><th>Entry type</th><th>Memo</th></tr></thead><tbody>
@forelse($ledger as $entry)<tr><td>{{ $entry->created_at?->format('Y-m-d H:i:s') }}</td><td>{{ $entry->user_id }}</td><td>{{ $entry->symbol }}</td><td>{{ number_format((float)$entry->amount,8) }}</td><td>{{ number_format((float)$entry->balance_after,8) }}</td><td>{{ $entry->entry_type }}</td><td>{{ $entry->memo ?: '—' }}</td></tr>@empty<tr><td colspan="7">No ledger entries yet.</td></tr>@endforelse
</tbody></table></section>

<section class="panel"><h2>Administrator audit trail</h2><p>Append-only records of role, account-status and service-request changes, including who made each change.</p><table><thead><tr><th>Time</th><th>Administrator</th><th>Action</th><th>Target</th><th>Change details</th></tr></thead><tbody>
@forelse($auditLogs as $entry)<tr><td>{{ $entry->created_at?->format('Y-m-d H:i:s') }}</td><td>{{ $entry->actor_id ?: 'System' }}</td><td>{{ $entry->action }}</td><td>{{ $entry->target_type }} #{{ $entry->target_id }}</td><td>{{ json_encode($entry->details, JSON_UNESCAPED_SLASHES) }}</td></tr>@empty<tr><td colspan="5">No administrator changes recorded yet.</td></tr>@endforelse
</tbody></table></section>
</main></body></html>