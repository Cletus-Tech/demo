// Static safety checks that run anywhere with Node (no database needed).
// They do NOT replace supabase/tests/rls_tests.sql, which tests the real database.
const fs = require('fs'), path = require('path');
const root = path.join(__dirname, '..');
let fails = 0;
const ok = (n, c, d = '') => { console.log((c ? 'PASS  ' : 'FAIL  ') + n + (c ? '' : '  [' + d + ']')); if (!c) fails++; };
const migDir = path.join(root, 'supabase', 'migrations');
const files = fs.readdirSync(migDir).filter(f => f.endsWith('.sql')).sort();
const sql = Object.fromEntries(files.map(f => [f, fs.readFileSync(path.join(migDir, f), 'utf8')]));
const all = Object.values(sql).join('\n');

// 1. syntax sanity: dollar quotes and parentheses balance
for (const [f, s] of Object.entries(sql)) {
  const tags = (s.match(/\$[A-Za-z_]*\$/g) || []);
  ok(`${f}: dollar-quote tags are paired`, tags.length % 2 === 0, `${tags.length} tags`);
  const stripped = s.replace(/--.*$/gm, '').replace(/'(?:[^']|'')*'/g, "''");
  const o = (stripped.match(/\(/g) || []).length, c = (stripped.match(/\)/g) || []).length;
  ok(`${f}: parentheses balance`, o === c, `${o} open vs ${c} close`);
}
// 2. every table has RLS
const tables = [...all.matchAll(/create table public\.(\w+)/g)].map(m => m[1]);
for (const t of tables) ok(`RLS enabled on public.${t}`, new RegExp(`alter table public\\.${t}\\s+enable row level security`).test(all));
// 3. grants: clients get SELECT only (plus two column-level updates)
const grants = sql['0009_grants_and_lockdown.sql'];
ok('no grant to anon anywhere', !/grant\s[^;]*\sto\s[^;]*\banon\b/i.test(grants.replace(/revoke[^;]*;/gi, '')));
const tableGrants = [...grants.matchAll(/grant\s+(select|insert|update|delete|all)\b[^;]*?to authenticated;/gis)].map(m => m[0]);
ok('table grants to authenticated are SELECT or column-limited UPDATE only',
   tableGrants.every(g => /^grant select/i.test(g) || /^grant update \((full_name, phone, country, language|read_at)\)/i.test(g)), tableGrants.join(' | ').slice(0, 200));
// 4. every function is either granted explicitly or is internal (starts with _ ) / trigger / helper
const fnNames = [...all.matchAll(/create or replace function public\.(\w+)\(/g)].map(m => m[1]);
const granted = [...grants.matchAll(/grant execute on function public\.(\w+)\(/g)].map(m => m[1]);
const clientFns = ['is_staff','is_admin','is_superadmin','demo_refresh_prices','place_spot_order','place_swap','open_leveraged_position','close_position','settle_my_positions','demo_deposit','demo_withdraw','reset_demo_account','admin_set_role','admin_set_status'];
ok('exactly the intended functions are callable by clients', JSON.stringify([...new Set(granted)].filter(n => n !== 'handle_new_user').sort()) === JSON.stringify(clientFns.slice().sort()), granted.join(','));
for (const f of fnNames.filter(n => /^(place_|open_|close_|demo_|reset_|settle_|admin_)/.test(n))) {
  const body = all.slice(all.indexOf(`function public.${f}(`));
  const def = body.slice(0, body.indexOf('$$;') + 3);
  if (!/^(demo_refresh)/.test(f)) ok(`public.${f} is SECURITY DEFINER with a fixed search_path`, /security definer set search_path = public/.test(def));
}
ok('ledger forced to demo mode (mode = demo check)', /mode\s+text not null default 'demo' check \(mode = 'demo'\)/.test(sql['0003_wallets_and_ledger.sql']));
ok('signup trigger never reads role/status from metadata', !/->>\s*'(role|status)'/.test(sql['0007_signup_trigger.sql']));

// 5. frontend: no secrets, no browser balance storage
const walk = d => fs.readdirSync(d, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]);
const appFiles = walk(path.join(root, 'app')).filter(f => /\.(html|js)$/.test(f));
const joined = appFiles.map(f => fs.readFileSync(f, 'utf8')).join('\n');
ok('no JWT-looking token embedded in app/', !/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\./.test(joined));
ok('no sb_secret_ key in app/', !/sb_secret_[A-Za-z0-9]/.test(joined));
ok('dashboard does not use localStorage for balances', !/localStorage/.test(fs.readFileSync(path.join(root, 'app', 'dashboard.html'), 'utf8')));
ok('config.js ships empty (no project is assumed)', /SUPABASE_URL:\s*""/.test(fs.readFileSync(path.join(root, 'app', 'js', 'config.js'), 'utf8')) || process.env.ALLOW_CONFIGURED === '1');
const envEx = fs.readFileSync(path.join(root, '.env.example'), 'utf8');
ok('.env.example contains placeholders only', /YOUR-/.test(envEx) && !/eyJ/.test(envEx));
console.log(fails ? `\n${fails} check(s) FAILED` : '\nAll static checks passed');
process.exit(fails ? 1 : 0);
