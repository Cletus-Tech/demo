"""Headless-browser test of the frontend against a FAKE Supabase (see fake-supabase.js).
Run:  python3 tests/ui-test.py        (needs: pip install playwright + a Chromium)"""
import http.server, threading, socketserver, os, sys, functools, re
from playwright.sync_api import sync_playwright

ROOT = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(ROOT, "..", "app")
FAKE = open(os.path.join(ROOT, "fake-supabase.js"), encoding="utf-8").read()
CFG = 'window.APP_CONFIG={SUPABASE_URL:"https://fake-project.supabase.co",SUPABASE_ANON_KEY:"fake-anon-key"};'
PORT = 8765
results = []
def check(name, cond, detail=""):
    results.append((name, bool(cond)))
    print(("PASS  " if cond else "FAIL  ") + name + ("" if cond else f"  [{detail}]"))

class Q(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *a): pass
socketserver.TCPServer.allow_reuse_address = True
srv = socketserver.TCPServer(("127.0.0.1", PORT), functools.partial(Q, directory=APP))
threading.Thread(target=srv.serve_forever, daemon=True).start()
B = f"http://127.0.0.1:{PORT}/"

def money(page, sym):  # value shown in the assets list for a symbol
    return page.evaluate("""(s)=>{const rows=[...document.querySelectorAll('#assets .row')];
      const r=rows.find(x=>x.querySelector('.n span').textContent===s);return r?r.querySelector('.v').childNodes[0].textContent:null}""", sym)

with sync_playwright() as p:
    br = p.chromium.launch()
    # ---------- unconfigured ----------
    ctx = br.new_context(); pg = ctx.new_page()
    pg.route("**/supabase.js", lambda r: r.fulfill(body=FAKE, content_type="application/javascript"))
    pg.goto(B + "index.html"); pg.wait_for_url("**/setup-check.html")
    pg.wait_for_selector("li.f")
    check("unconfigured app is sent to the setup check", "setup-check" in pg.url)
    check("setup check explains the problem", "config.js" in pg.inner_text("#out"))
    pg.goto(B + "dashboard.html"); pg.wait_for_url("**/setup-check.html")
    check("dashboard refuses to run when unconfigured", "setup-check" in pg.url)
    ctx.close()

    # ---------- secret key is refused ----------
    ctx = br.new_context(); pg = ctx.new_page()
    pg.route("**/supabase.js", lambda r: r.fulfill(body=FAKE, content_type="application/javascript"))
    pg.route("**/js/config.js", lambda r: r.fulfill(body='window.APP_CONFIG={SUPABASE_URL:"https://fake-project.supabase.co",SUPABASE_ANON_KEY:"sb_secret_abc123"};', content_type="application/javascript"))
    pg.goto(B + "setup-check.html"); pg.wait_for_selector("li.f")
    check("a secret key in config.js is rejected", "SECRET" in pg.inner_text("#out"))
    ctx.close()

    # ---------- configured ----------
    ctx = br.new_context(viewport={"width": 1280, "height": 900}); pg = ctx.new_page()
    errors = []
    pg.on("pageerror", lambda e: errors.append(str(e)))
    pg.route("**/supabase.js", lambda r: r.fulfill(body=FAKE, content_type="application/javascript"))
    pg.route("**/js/config.js", lambda r: r.fulfill(body=CFG, content_type="application/javascript"))
    pg.goto(B + "dashboard.html"); pg.wait_for_url("**/login.html")
    check("signed-out visitor is redirected to login", "login.html" in pg.url)

    pg.fill("#email", "tester@example.com"); pg.click("#tIn"); pg.fill("#pass", "wrong-pass")
    pg.click("#go"); pg.wait_for_function("document.getElementById('msg').textContent.length>0")
    check("wrong credentials show a generic error", pg.inner_text("#msg") == "Invalid email or password.")

    pg.click("#tUp"); pg.fill("#name", "Test User"); pg.fill("#pass", "short"); pg.fill("#pass2", "short"); pg.click("#go")
    check("short password rejected on signup", "at least 8" in pg.inner_text("#msg"))
    pg.fill("#pass", "correct-horse"); pg.fill("#pass2", "correct-horse"); pg.click("#go")
    pg.wait_for_url("**/dashboard.html"); pg.wait_for_selector("#assets .row")
    check("signup lands on the dashboard", "dashboard.html" in pg.url)
    check("demo starting balance is $13,000.00", pg.inner_text("#total") == "$13,000.00", pg.inner_text("#total"))
    check("user name comes from the profile", pg.inner_text("#uName") == "Test User")
    check("demo banner is visible", pg.is_visible(".demobar"))

    # spot buy
    pg.select_option("#tType", "Stocks"); pg.select_option("#tAsset", "AAPL"); pg.fill("#tAmt", "100"); pg.click("#go")
    pg.wait_for_function("document.getElementById('msg').textContent.includes('Bought')")
    check("spot buy confirms", "Bought $100.00 of AAPL (demo)" in pg.inner_text("#msg"))
    check("USD debited", money(pg, "USD") == "$2,900.00", money(pg, "USD"))
    # overspend
    pg.fill("#tAmt", "999999"); pg.click("#go")
    pg.wait_for_function("document.getElementById('msg').textContent.includes('Not enough')")
    check("server rejects overspend", "Not enough USD" in pg.inner_text("#msg"))
    # leveraged
    pg.fill("#tAmt", "100")
    pg.evaluate("()=>{const l=document.getElementById('lev');l.value=10;l.dispatchEvent(new Event('input',{bubbles:true}))}")
    pg.click("#go"); pg.wait_for_function("document.getElementById('msg').textContent.includes('Opened')")
    check("leveraged position opens", "Opened 10x long on AAPL" in pg.inner_text("#msg"))
    pg.wait_for_selector("#pos [data-c]")
    check("open position listed with a Close button", pg.locator("#pos [data-c]").count() == 1)
    pg.click("#pos [data-c]"); pg.wait_for_function("document.getElementById('msg').textContent.includes('closed (manual)')")
    check("position closes via the server", "closed (manual)" in pg.inner_text("#msg"))
    pg.wait_for_function("document.querySelectorAll('#pos [data-c]').length===0")
    check("position removed from open list", pg.locator("#pos [data-c]").count() == 0)
    # deposit / withdraw
    pg.click('#nav a[data-go="Deposit"]'); pg.fill("#moneyAmt", "500"); before = money(pg, "USD"); pg.click("#moneyOk")
    pg.wait_for_function("document.getElementById('money').classList.contains('open')===false")
    check("demo deposit changes USD", money(pg, "USD") != before, f"{before} -> {money(pg,'USD')}")
    pg.click('#nav a[data-go="Withdraw"]'); pg.fill("#moneyAmt", "99999999"); pg.click("#moneyOk")
    pg.wait_for_function("document.getElementById('moneyErr').textContent.length>0")
    check("withdraw above balance rejected by server", "Not enough USD" in pg.inner_text("#moneyErr"))
    pg.click("#moneyCancel")
    # notifications from the server
    pg.wait_for_function("!document.getElementById('bellDot').hidden")
    pg.click("#bell")
    check("notifications come from the database", "Bought $100.00 of AAPL" in pg.inner_text("#bellMenu"))
    # price polling does not crash & balances revalue
    pg.wait_for_timeout(5600)
    check("price polling keeps running without errors", not errors, str(errors))
    # reset
    pg.click("#acctBtn"); pg.click("#mReset"); pg.click("#reset")
    pg.wait_for_function("document.getElementById('total').textContent==='$13,000.00'", timeout=8000)
    check("reset restores starting balances", pg.inner_text("#total") == "$13,000.00")
    # nothing sensitive in browser storage
    keys = pg.evaluate("Object.keys(localStorage)")
    check("balances are not stored in the browser", not any("balance" in k.lower() for k in keys), str(keys))
    # sign out
    pg.click("#acctBtn"); pg.click("#mOut"); pg.wait_for_url("**/login.html")
    check("sign out returns to login", "login.html" in pg.url)
    pg.goto(B + "dashboard.html"); pg.wait_for_url("**/login.html")
    check("dashboard is locked after sign out", "login.html" in pg.url)

    # ---------- mobile layout smoke test ----------
    m = br.new_context(viewport={"width": 375, "height": 740}, is_mobile=True); mp = m.new_page()
    mp.route("**/supabase.js", lambda r: r.fulfill(body=FAKE, content_type="application/javascript"))
    mp.route("**/js/config.js", lambda r: r.fulfill(body=CFG, content_type="application/javascript"))
    mp.goto(B + "login.html"); mp.fill("#email", "m@example.com"); mp.click("#tUp"); mp.fill("#pass", "correct-horse"); mp.fill("#pass2", "correct-horse"); mp.click("#go")
    mp.wait_for_url("**/dashboard.html"); mp.wait_for_selector("#assets .row")
    over = mp.evaluate("document.documentElement.scrollWidth>document.documentElement.clientWidth")
    check("no horizontal scroll on a 375px phone", not over)
    mp.screenshot(path="/tmp/mobile-dashboard.png")
    br.close()
srv.shutdown()
bad = [n for n, ok in results if not ok]
print(f"\n{len(results)-len(bad)} passed, {len(bad)} failed")
sys.exit(1 if bad else 0)
