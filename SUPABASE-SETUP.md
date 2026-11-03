# Supabase setup: click by click

Time needed: about 20 minutes. Cost: **free** (the Supabase Free plan is enough for this stage).
Nothing in this stage needs a paid service. Exact button names in Supabase change from time to time, so if a label
differs slightly, look for the closest match.

> The app will show a clear "not configured" screen until you finish this guide, and it will **not** pretend to be
> connected. Step 9 proves the connection with real tests.

## Step 1. Create a Supabase account
1. Go to **supabase.com** and click **Start your project** (or **Sign in**).
2. Sign up with GitHub or with your email. Confirm your email if asked.

## Step 2. Create the project
1. Click **New project**. If asked, create an **Organization** first (any name, plan **Free**).
2. **Name:** for example `broker-demo`.
3. **Database password:** click **Generate a password** and **save it in a password manager**. You will almost never need it,
   but you cannot read it again later. **Never put it in the app or share it.**
4. **Region:** pick the one closest to your users.
5. Click **Create new project** and wait 1 to 3 minutes until the dashboard finishes loading.

## Step 3. Create the database tables (one paste)
1. In the left sidebar click **SQL Editor**.
2. Click **New query** (the **+** button).
3. On your computer open the file `supabase/setup_all.sql` from this project in any text editor, select **everything**, copy.
4. Paste into the SQL Editor and click **Run**.
5. Wait for **Success. No rows returned**. If you get a red error, **copy the whole error text and send it to me**.
   Do not run the file twice: the second run fails with "already exists". If you must start over, create a fresh project.

## Step 4. Copy the two public values
1. In the left sidebar click the **gear icon (Project Settings)**, then **API** (newer dashboards: **API Keys** and **Data API**).
2. Copy the **Project URL** (looks like `https://abcdefghijklmnop.supabase.co`).
3. Copy the **anon** key (it may be called the **publishable** key, or be on the **Legacy API keys** tab).
4. **Do not copy** the `service_role` key or any key labelled **secret**. The app refuses to start if you paste one.

## Step 5. Put them in the app
1. Open `app/js/config.js` in a text editor.
2. Paste the URL between the quotes after `SUPABASE_URL:` and the key after `SUPABASE_ANON_KEY:`.
3. Save the file.

## Step 6. Turn on email sign-up rules
1. Sidebar: **Authentication**, then **Sign In / Providers** (or **Providers**), then **Email**.
2. Keep **Enable Email provider** ON.
3. **Confirm email**: leave ON for real use. While you are only testing you may turn it OFF so sign-up logs you in at once.
   Supabase's built-in email sender allows only a very small number of emails per hour, so for real launch you will need a
   custom email provider (**Authentication > Emails > SMTP Settings**). Many have free tiers. Ask me before paying for anything.
4. Set **Minimum password length** to 8 or more.
5. Click **Save**.

## Step 7. Tell Supabase where your site lives
1. Sidebar: **Authentication**, then **URL Configuration**.
2. **Site URL:** where the app will run, for example `http://localhost:8000` while testing, later your real address.
3. **Redirect URLs:** add the same address followed by `/**` (for example `http://localhost:8000/**`). Add your real address later too.
4. Click **Save**.

## Step 8. Run the app
Local test (needs Python, which most computers have):
```
cd app
python3 -m http.server 8000
```
then open **http://localhost:8000**. To put it online later, upload the **app** folder to any static host
(Netlify Drop, Cloudflare Pages, GitHub Pages, Vercel). Remember to add that address in Step 7.

## Step 9. Verify the connection (do not skip)
1. Open **http://localhost:8000/setup-check.html**.
2. You should see **PASS** for: configuration, Auth service reachable, tables exist and are locked from anonymous visitors,
   and trading functions exist and refuse anonymous callers.
3. Click **Go to sign in**, create an account, then open the setup check again. It now also tests that your profile and
   demo wallets exist, and that you **cannot** edit your own balance or promote yourself. Every line should be **PASS**.
4. Any **FAIL** means something is not set up correctly. Send me a screenshot.

## Step 10. Run the security test script
1. Supabase: **SQL Editor > New query**.
2. Paste all of `supabase/tests/rls_tests.sql` and click **Run**.
3. You will see a **red error box. That is intentional**: the script ends with an error so every fake test user is rolled back.
   The message begins **ALL TESTS PASSED** or **SOME TESTS FAILED** and lists each check.
4. Send me the full message either way.

## Step 11. Make yourself the first administrator (optional in Stage 1)
1. Create your own account in the app first.
2. SQL Editor > New query, run (with your email):
   ```sql
   select public.bootstrap_superadmin('you@example.com');
   ```
3. This works only from the SQL Editor, not from the browser. It is recorded in the audit log.
   The admin screens themselves arrive in Stage 3.

## Things never to do
- Never paste the **service_role** or **secret** key, or the **database password**, into any file in `app/`.
- Never share screenshots that show those keys.
- If a secret ever leaks: Project Settings > API > roll/regenerate the key, and tell me.
- Free projects are **paused after about a week of inactivity**. Open the dashboard and click **Restore** if that happens.
