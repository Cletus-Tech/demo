/* TEST DOUBLE ONLY. Replaces the Supabase library in the browser test so the
   frontend can be exercised without a real project. It mimics the server rules
   in JavaScript; it does NOT test the real SQL (use supabase/tests/rls_tests.sql). */
(function () {
  var KEY = "__fake_db";
  function load() { try { return JSON.parse(localStorage.getItem(KEY)) || null; } catch (e) { return null; } }
  var db = load() || {
    users: [], session: null, confirmEmail: false,
    profiles: [], wallets: [], positions: [], orders: [], notifications: [],
    assets: [["BTC","Bitcoin","crypto"],["ETH","Ethereum","crypto"],["USD","United States Dollar","fiat"],["SOL","Solana","crypto"],["AAPL","Apple","stocks"]]
      .map(function (a, i) { return { symbol: a[0], name: a[1], category: a[2], sort_order: i + 1, is_active: true }; }),
    prices: { BTC: 80000, ETH: 2500, USD: 1, SOL: 100, AAPL: 200 }
  };
  function save() { localStorage.setItem(KEY, JSON.stringify(db)); }
  var uuid = function () { return "xxxxxxxx-xxxx-4xxx-8xxx-xxxxxxxxxxxx".replace(/x/g, function () { return (Math.random() * 16 | 0).toString(16); }); };
  var err = function (m, code) { return { message: m, code: code || "P0001" }; };
  var me = function () { return db.session && db.session.user; };

  function wallet(uid, sym) {
    var w = db.wallets.find(function (x) { return x.user_id === uid && x.symbol === sym; });
    if (!w) { w = { user_id: uid, symbol: sym, balance: 0 }; db.wallets.push(w); }
    return w;
  }
  function post(uid, sym, amt) { var w = wallet(uid, sym); if (w.balance + amt < -1e-9) throw err("check constraint"); w.balance += amt; }
  function notify(uid, t) { db.notifications.unshift({ id: uuid(), user_id: uid, title: t, created_at: new Date().toISOString(), read_at: null }); }
  var fmt = function (n) { return (n < 0 ? "-$" : "$") + Math.abs(n).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 }); };
  function grant(uid) {
    var cfg = { BTC: 5000, ETH: 2000, USD: 3000, SOL: 2000, AAPL: 1000 };
    Object.keys(cfg).forEach(function (s) { post(uid, s, cfg[s] / db.prices[s]); });
  }
  function active() {
    var u = me(); if (!u) throw err("Please sign in first", "28000");
    return u.id;
  }
  function pnl(p) { return p.margin_usd * p.leverage * (p.side === "long" ? 1 : -1) * (db.prices[p.symbol] / p.entry_price - 1); }
  function closePos(p, reason) {
    var payout = Math.max(0, p.margin_usd + pnl(p));
    if (payout > 0) post(p.user_id, "USD", payout);
    p.status = "closed"; p.close_reason = reason; p.pnl_usd = payout - p.margin_usd; p.closed_at = new Date().toISOString();
    notify(p.user_id, p.symbol + " " + p.side + " closed (" + reason.replace("_", " ") + "): " + fmt(payout - p.margin_usd));
    return { id: p.id, symbol: p.symbol, side: p.side, reason: reason, pnl: Math.round((payout - p.margin_usd) * 100) / 100 };
  }
  var rpcs = {
    demo_refresh_prices: function () { active(); Object.keys(db.prices).forEach(function (s) { if (s !== "USD") db.prices[s] *= 1 + (Math.random() - .5) * .006; }); },
    place_spot_order: function (a) {
      var uid = active(), amt = Math.round(a.p_amount_usd * 100) / 100, sym = String(a.p_symbol).toUpperCase();
      if (!(amt >= .01)) throw err("Enter an amount of at least 0.01");
      if (sym === "USD" || !db.prices[sym]) throw err(sym + " is not available for trading");
      var q = amt / db.prices[sym];
      if (a.p_side === "buy") { if (wallet(uid, "USD").balance < amt) throw err("Not enough USD in your demo balance"); post(uid, "USD", -amt); post(uid, sym, q); }
      else { if (wallet(uid, sym).balance < q) throw err("Not enough " + sym + " in your demo balance"); post(uid, sym, -q); post(uid, "USD", amt); }
      db.orders.push({ id: uuid(), user_id: uid, kind: "spot", side: a.p_side, symbol: sym, amount_usd: amt, created_at: new Date().toISOString() });
      notify(uid, (a.p_side === "buy" ? "Bought " : "Sold ") + fmt(amt) + " of " + sym); return uuid();
    },
    place_swap: function (a) {
      var uid = active(), amt = a.p_amount_usd;
      if (a.p_from === a.p_to) throw err("Pick two different assets");
      var qf = amt / db.prices[a.p_from], qt = amt / db.prices[a.p_to];
      if (wallet(uid, a.p_from).balance < qf) throw err("Not enough " + a.p_from + " in your demo balance");
      post(uid, a.p_from, -qf); post(uid, a.p_to, qt);
      db.orders.push({ id: uuid(), user_id: uid, kind: "swap", side: "convert", symbol: a.p_to, from_symbol: a.p_from, amount_usd: amt, created_at: new Date().toISOString() });
      notify(uid, "Converted " + fmt(amt) + " from " + a.p_from + " to " + a.p_to); return uuid();
    },
    open_leveraged_position: function (a) {
      var uid = active();
      if (a.p_leverage < 2 || a.p_leverage > 100) throw err("Leverage must be between 2x and 100x");
      if (wallet(uid, "USD").balance < a.p_margin_usd) throw err("Not enough USD in your demo balance");
      post(uid, "USD", -a.p_margin_usd);
      var p = { id: uuid(), user_id: uid, symbol: a.p_symbol, side: a.p_side, margin_usd: a.p_margin_usd, leverage: a.p_leverage,
        entry_price: db.prices[a.p_symbol], take_profit: a.p_take_profit || null, stop_loss: a.p_stop_loss || null,
        expires_at: a.p_duration_sec ? new Date(Date.now() + a.p_duration_sec * 1000).toISOString() : null,
        status: "open", opened_at: new Date().toISOString() };
      db.positions.push(p); notify(uid, "Opened " + a.p_leverage + "x " + a.p_side + " on " + a.p_symbol); return p.id;
    },
    close_position: function (a) {
      var uid = active(), p = db.positions.find(function (x) { return x.id === a.p_id && x.user_id === uid && x.status === "open"; });
      if (!p) throw err("Position not found or already closed"); return closePos(p, "manual");
    },
    settle_my_positions: function () {
      var uid = active(), out = [];
      db.positions.filter(function (p) { return p.user_id === uid && p.status === "open"; }).forEach(function (p) {
        if (p.expires_at && Date.now() >= Date.parse(p.expires_at)) out.push(closePos(p, "duration_ended"));
      }); return out;
    },
    demo_deposit: function (a) {
      var uid = active(); if (a.p_amount > 100000) throw err("Demo deposits are limited to $100,000.00 per request");
      post(uid, "USD", a.p_amount); notify(uid, "Demo deposit of " + fmt(a.p_amount));
    },
    demo_withdraw: function (a) {
      var uid = active(); if (wallet(uid, "USD").balance < a.p_amount) throw err("Not enough USD in your demo balance");
      post(uid, "USD", -a.p_amount); notify(uid, "Demo withdrawal of " + fmt(a.p_amount));
    },
    reset_demo_account: function () {
      var uid = active();
      db.positions.filter(function (p) { return p.user_id === uid && p.status === "open"; }).forEach(function (p) { closePos(p, "manual"); });
      db.wallets.filter(function (w) { return w.user_id === uid; }).forEach(function (w) { w.balance = 0; });
      grant(uid); notify(uid, "Demo account reset");
    }
  };

  function builder(table) {
    var op = "select", filters = [], ord = null, lim = null, single = false, upd = null;
    var b = {
      select: function () { return b; },
      update: function (v) { op = "update"; upd = v; return b; },
      eq: function (k, v) { filters.push(function (r) { return r[k] === v; }); return b; },
      in: function (k, vs) { filters.push(function (r) { return vs.indexOf(r[k]) >= 0; }); return b; },
      is: function (k, v) { filters.push(function (r) { return (r[k] === undefined ? null : r[k]) === v; }); return b; },
      order: function (k, o) { ord = [k, !(o && o.ascending === false)]; return b; },
      limit: function (n) { lim = n; return b; },
      maybeSingle: function () { single = true; return b; },
      then: function (res, rej) { return Promise.resolve(exec()).then(res, rej); }
    };
    function exec() {
      var u = me();
      if (!u) return { data: null, error: err("permission denied for table " + table, "42501") };
      if (op === "update") {
        if (table !== "notifications") return { data: null, error: err("permission denied for table " + table, "42501") };
        db.notifications.forEach(function (r) { if (filters.every(function (f) { return f(r); })) Object.assign(r, upd); }); save();
        return { data: [], error: null };
      }
      var rows;
      if (table === "assets") rows = db.assets.slice();
      else if (table === "market_prices") rows = Object.keys(db.prices).map(function (s) { return { symbol: s, price: db.prices[s], source: "demo", updated_at: new Date().toISOString() }; });
      else rows = (db[table] || []).filter(function (r) { return (r.user_id || r.id) === u.id; });   // RLS: own rows
      rows = rows.filter(function (r) { return filters.every(function (f) { return f(r); }); });
      if (ord) rows.sort(function (a, c) { return (a[ord[0]] > c[ord[0]] ? 1 : -1) * (ord[1] ? 1 : -1); });
      if (lim) rows = rows.slice(0, lim);
      return { data: single ? (rows[0] || null) : JSON.parse(JSON.stringify(rows)), error: null };
    }
    return b;
  }

  var listeners = [];
  var client = {
    auth: {
      getSession: function () { return Promise.resolve({ data: { session: db.session } }); },
      onAuthStateChange: function (f) { listeners.push(f); return { data: { subscription: { unsubscribe: function () {} } } }; },
      signInWithPassword: function (c) {
        var u = db.users.find(function (x) { return x.email === c.email && x.password === c.password; });
        if (!u) return Promise.resolve({ data: {}, error: { message: "Invalid login credentials", status: 400 } });
        db.session = { user: { id: u.id, email: u.email } }; save(); return Promise.resolve({ data: { session: db.session }, error: null });
      },
      signUp: function (c) {
        var id = uuid();
        db.users.push({ id: id, email: c.email, password: c.password });
        db.profiles.push({ id: id, email: c.email, full_name: (c.options && c.options.data && c.options.data.full_name) || null, role: "user", status: "active", referral_code: "ABCD1234", language: "en" });
        grant(id);
        if (!db.confirmEmail) db.session = { user: { id: id, email: c.email } };
        save(); return Promise.resolve({ data: { session: db.session, user: { id: id } }, error: null });
      },
      signOut: function () { db.session = null; save(); return Promise.resolve({ error: null }); },
      resetPasswordForEmail: function () { return Promise.resolve({ error: null }); },
      updateUser: function () { return Promise.resolve({ error: null }); }
    },
    from: builder,
    rpc: function (name, args) {
      try { var d = rpcs[name](args || {}); save(); return Promise.resolve({ data: d === undefined ? null : d, error: null }); }
      catch (e) { return Promise.resolve({ data: null, error: e }); }
    }
  };
  window.supabase = { createClient: function () { return client; } };
})();
