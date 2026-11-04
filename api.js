/* All calls to the backend live in this one file. The browser can only READ
   its own rows and call the demo functions defined in the database. */
(function () {
  var S = window.AppSupabase;
  var sb = S && S.client;

  function fail(error) {
    var e = new Error((error && error.message) || "Something went wrong");
    e.code = error && error.code;
    e.status = error && error.status;
    return e;
  }
  async function run(p) {
    var r = await p;
    if (r.error) throw fail(r.error);
    return r.data;
  }
  async function session() {
    var r = await sb.auth.getSession();
    return r.data.session;
  }
  async function uid() {
    var s = await session();
    if (!s) throw new Error("Please sign in first");
    return s.user.id;
  }
  var num = function (v) { return v === null || v === undefined ? null : Number(v); };

  window.API = {
    getSession: session,
    signOut: function () { return sb.auth.signOut(); },

    /* Everything the dashboard needs, in one round of queries. */
    loadState: async function () {
      var id = await uid();
      var res = await Promise.all([
        run(sb.from("profiles").select("id,email,full_name,role,status,referral_code,language").eq("id", id).maybeSingle()),
        run(sb.from("assets").select("symbol,name,category,sort_order").eq("is_active", true).order("sort_order")),
        run(sb.from("market_prices").select("symbol,price,source,updated_at")),
        run(sb.from("wallets").select("symbol,balance").eq("user_id", id)),
        run(sb.from("positions").select("*").eq("user_id", id).eq("status", "open").order("opened_at")),
        run(sb.from("positions").select("*").eq("user_id", id).eq("status", "closed").order("closed_at", { ascending: false }).limit(50)),
        run(sb.from("orders").select("*").eq("user_id", id).in("kind", ["spot", "swap"]).order("created_at", { ascending: false }).limit(50)),
        run(sb.from("ledger_entries").select("id,symbol,amount,entry_type,memo,created_at").eq("user_id", id).in("entry_type", ["demo_grant","demo_deposit","demo_withdrawal","demo_reset"]).order("created_at", { ascending: false }).limit(50)),
        run(sb.from("referrals").select("id,status,created_at").eq("referrer_id", id).order("created_at", { ascending: false }).limit(100))
      ]);
      var wallets = {};
      res[3].forEach(function (w) { wallets[w.symbol] = num(w.balance); });
      return { profile: res[0], assets: res[1], prices: res[2], wallets: wallets,
               positions: res[4], closed: res[5], orders: res[6], ledger: res[7], referrals: res[8] };
    },
    loadPrices: function () { return run(sb.from("market_prices").select("symbol,price,source,updated_at")); },
    updateProfile: async function (changes) {
      var id = await uid();
      var allowed = {};
      ["full_name", "phone", "country", "language"].forEach(function (k) {
        if (Object.prototype.hasOwnProperty.call(changes, k)) allowed[k] = changes[k];
      });
      if (!Object.keys(allowed).length) throw new Error("There are no profile changes to save");
      return run(sb.from("profiles").update(allowed).eq("id", id).select("id,email,full_name,phone,country,language,role,status,referral_code").single());
    },
    loadReferrals: async function () {
      var id = await uid();
      return run(sb.from("referrals").select("id,status,created_at").eq("referrer_id", id).order("created_at", { ascending: false }).limit(100));
    },
    adminOverview: async function () {
      await uid();
      var allowed = await run(sb.rpc("is_admin"));
      if (!allowed) throw new Error("Administrator access required");
      var superadmin = await run(sb.rpc("is_superadmin"));
      var results = await Promise.all([
        run(sb.from("profiles").select("id,email,full_name,role,status,created_at").order("created_at", { ascending: false }).limit(200)),
        run(sb.from("orders").select("id,user_id,kind,side,symbol,from_symbol,amount_usd,price,quantity,status,mode,created_at").order("created_at", { ascending: false }).limit(100)),
        run(sb.from("ledger_entries").select("id,user_id,symbol,amount,entry_type,memo,created_at").order("created_at", { ascending: false }).limit(100)),
        run(sb.from("positions").select("id,user_id,symbol,side,margin_usd,leverage,status,pnl_usd,opened_at,closed_at").order("opened_at", { ascending: false }).limit(100))
      ]);
      return { isSuperadmin: !!superadmin, users: results[0], orders: results[1], ledger: results[2], positions: results[3] };
    },
    adminSetStatus: function (userId, status) {
      if (["active", "suspended"].indexOf(status) < 0) throw new Error("Invalid account status");
      return run(sb.rpc("admin_set_status", { p_user: userId, p_status: status }));
    },
    adminSetRole: function (userId, role) {
      if (["user", "support", "admin", "superadmin"].indexOf(role) < 0) throw new Error("Invalid account role");
      return run(sb.rpc("admin_set_role", { p_user: userId, p_role: role }));
    },
    loadNotifications: async function () {
      var id = await uid();
      return run(sb.from("notifications").select("id,title,created_at,read_at").eq("user_id", id).order("created_at", { ascending: false }).limit(20));
    },
    markNotificationsRead: async function () {
      var id = await uid();
      return run(sb.from("notifications").update({ read_at: new Date().toISOString() }).eq("user_id", id).is("read_at", null));
    },

    /* Demo actions: the server checks everything again, whatever the page says. */
    refreshPrices: function () { return sb.rpc("demo_refresh_prices"); },   // errors ignored on purpose
    spot: function (symbol, side, amount) { return run(sb.rpc("place_spot_order", { p_symbol: symbol, p_side: side, p_amount_usd: amount })); },
    swap: function (from, to, amount) { return run(sb.rpc("place_swap", { p_from: from, p_to: to, p_amount_usd: amount })); },
    openPosition: function (symbol, side, margin, leverage, tp, sl, durationSec) {
      return run(sb.rpc("open_leveraged_position", {
        p_symbol: symbol, p_side: side, p_margin_usd: margin, p_leverage: leverage,
        p_take_profit: tp || 0, p_stop_loss: sl || 0, p_duration_sec: durationSec || 0 }));
    },
    closePosition: function (id) { return run(sb.rpc("close_position", { p_id: id })); },
    settle: async function () { return (await run(sb.rpc("settle_my_positions"))) || []; },
    deposit: function (amount) { return run(sb.rpc("demo_deposit", { p_amount: amount })); },
    withdraw: function (amount) { return run(sb.rpc("demo_withdraw", { p_amount: amount })); },
    resetDemo: function () { return run(sb.rpc("reset_demo_account")); }
  };
})();
