/* Laravel-native browser adapter for the existing brokerage dashboard.
 * All money/position operations are simulated demo operations on the server.
 */
(function () {
  "use strict";
  const base = "/api/broker";
  let csrfReady = false;

  function cookie(name) {
    const part = document.cookie.split("; ").find(row => row.startsWith(name + "="));
    return part ? decodeURIComponent(part.slice(name.length + 1)) : "";
  }
  async function csrf() {
    if (csrfReady) return;
    const response = await fetch("/sanctum/csrf-cookie", { credentials: "same-origin" });
    if (!response.ok) throw new Error("Could not initialize the secure session. Check Sanctum configuration.");
    csrfReady = true;
  }
  async function request(path, options) {
    options = options || {};
    const method = (options.method || "GET").toUpperCase();
    const headers = Object.assign({ "Accept": "application/json" }, options.headers || {});
    if (method !== "GET" && method !== "HEAD") {
      await csrf();
      const token = cookie("XSRF-TOKEN");
      if (token) headers["X-XSRF-TOKEN"] = token;
      headers["Content-Type"] = "application/json";
    }
    const response = await fetch(path.startsWith("/") ? path : base + path, {
      method, credentials: "same-origin", headers,
      body: options.body ? JSON.stringify(options.body) : undefined
    });
    let data = {};
    try { data = await response.json(); } catch (_) {}
    if (response.status === 401 || response.status === 419) {
      const error = new Error(response.status === 419 ? "Your secure session expired. Refresh and sign in again." : "Your session has expired. Please sign in again.");
      error.status = response.status;
      throw error;
    }
    if (!response.ok) {
      const first = data.errors && Object.values(data.errors)[0];
      throw new Error((Array.isArray(first) && first[0]) || data.message || "The request could not be completed.");
    }
    return data;
  }
  const post = (path, body) => request(path, { method: "POST", body });
  const priceOf = (state, symbol) => {
    const asset = (state.assets || []).find(a => a.symbol === symbol);
    return asset ? Number(asset.price) : 0;
  };
  async function state() {
    const raw = await request("/state");
    const assets = raw.assets || [];
    const transactions = raw.transactions || [];
    const positions = raw.positions || [];
    return {
      profile: raw.profile,
      assets,
      prices: assets.map(a => ({ symbol: a.symbol, price: Number(a.price), source: "demo", updated_at: a.updated_at })),
      wallets: Object.fromEntries((raw.wallets || []).map(w => [w.symbol, Number(w.balance)])),
      positions: positions.filter(p => p.status === "open").map(p => Object.assign({}, p, {
        margin_usd: p.margin, leverage: p.leverage, side: p.side === "buy" ? "long" : "short"
      })),
      closed: positions.filter(p => p.status === "closed").map(p => Object.assign({}, p, {
        margin_usd: p.margin, leverage: p.leverage, pnl_usd: p.pnl,
        side: p.side === "buy" ? "long" : "short", close_reason: "manual", closed_at: p.closed_at
      })),
      orders: transactions.filter(t => ["buy", "sell", "convert"].includes(t.type)).map(t => ({
        kind: t.type === "convert" ? "swap" : "spot",
        side: t.type, symbol: t.type === "convert" ? ((t.meta || {}).to_symbol || t.symbol) : t.symbol,
        from_symbol: t.symbol, amount_usd: Number(t.amount) * priceOf({ assets }, t.symbol),
        created_at: t.created_at
      })),
      ledger: transactions.filter(t => ["deposit", "withdraw"].includes(t.type)).map(t => ({
        id: t.id, symbol: t.symbol, amount: t.type === "withdraw" ? -Number(t.amount) : Number(t.amount),
        entry_type: t.type === "deposit" ? "demo_deposit" : "demo_withdrawal",
        memo: "Demo transaction", created_at: t.created_at
      })),
      referrals: []
    };
  }
  const API = {
    getSession: async function () {
      try { await request("/state"); return { user: true }; }
      catch (e) { if (e.status === 401) return null; throw e; }
    },
    signOut: async function () {
      await post("/logout", {});
      location.assign("/login");
    },
    loadState: state,
    loadPrices: async function () {
      const s = await state();
      return s.prices;
    },
    refreshPrices: async function () { return true; },
    deposit: async function (amount) { return post("/transactions", { type: "deposit", symbol: "USD", amount }); },
    withdraw: async function (amount) { return post("/transactions", { type: "withdraw", symbol: "USD", amount }); },
    spot: async function (symbol, side, amountUsd) {
      const s = await state(), price = priceOf(s, symbol);
      if (!(price > 0)) throw new Error("The selected demo asset has no valid price.");
      const quantity = Number(amountUsd) / price;
      return post("/transactions", { type: side === "sell" ? "sell" : "buy", symbol, amount: quantity });
    },
    swap: async function (from, to, amountUsd) {
      const s = await state(), price = priceOf(s, from);
      if (!(price > 0)) throw new Error("The selected source asset has no valid price.");
      return post("/transactions", { type: "convert", symbol: from, to_symbol: to, amount: Number(amountUsd) / price });
    },
    openPosition: async function (symbol, side, marginUsd, leverage, tp, sl, durationSec) {
      const s = await state(), price = priceOf(s, symbol);
      if (!(price > 0)) throw new Error("The selected demo asset has no valid price.");
      return post("/positions", {
        symbol, side: side === "short" ? "sell" : "buy",
        quantity: Number(marginUsd) * Number(leverage) / price,
        leverage: Number(leverage), take_profit: Number(tp) || null, stop_loss: Number(sl) || null, duration_seconds: Number(durationSec) || 0
      });
    },
    closePosition: async function (id) {
      const result = await post("/positions/" + encodeURIComponent(id) + "/close", {});
      const p = result.position || {};
      return { symbol: p.symbol, side: p.side === "buy" ? "long" : "short", pnl: Number(p.pnl || 0) };
    },
    settle: async function () { return post("/positions/settle", {}); },
    resetDemo: async function () { throw new Error("Demo account reset is not enabled in this Laravel package."); },
    loadNotifications: function () { return request("/notifications"); },
    markNotificationsRead: function () { return post("/notifications/read", {}); },
    loadReferrals: async function () { return []; },
    updateProfile: function (changes) { return request("/profile", { method: "PATCH", body: { full_name: changes.full_name, phone: changes.phone, country: changes.country } }); },
    loadMyServiceRequests: function () { return request("/services"); },
    createServiceRequest: function (service_key, details) { return post("/services", { service_key, details }); }
  };
  window.API = API;
})();