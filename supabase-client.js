/* Creates the Supabase browser client and refuses unsafe configuration. */
(function () {
  var cfg = window.APP_CONFIG || {};
  var url = String(cfg.SUPABASE_URL || "").trim().replace(/\/+$/, "");
  var key = String(cfg.SUPABASE_ANON_KEY || "").trim();
  var S = { ready: false, problem: null, client: null, url: url, key: key };

  function jwtRole(k) {
    try {
      var p = k.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
      return JSON.parse(atob(p)).role || null;
    } catch (e) { return null; }
  }

  if (!url || !key) {
    S.problem = "Supabase is not configured yet. Open config.js in the repository root and add your Project URL and anon key.";
  } else if (!/^https:\/\/[a-z0-9-]+\.supabase\.(co|in)$/i.test(url) &&
             !/^http:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(url)) {
    S.problem = "SUPABASE_URL does not look right. It should look like https://abcdefgh.supabase.co";
  } else if (/^sb_secret_/.test(key) || jwtRole(key) === "service_role") {
    S.problem = "STOP: that key is a SECRET key. Never put it in the app. Use the anon/publishable key instead, and rotate the secret key in Supabase.";
  } else if (!window.supabase || !window.supabase.createClient) {
    S.problem = "The Supabase library could not be loaded. Check your internet connection.";
  } else {
    S.client = window.supabase.createClient(url, key, {
      auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
    });
    S.ready = true;
  }
  window.AppSupabase = S;
})();
