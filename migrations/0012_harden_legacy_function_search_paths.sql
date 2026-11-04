-- 0012_harden_legacy_function_search_paths.sql
alter function public.bootstrap_superadmin(text) set search_path = public;
alter function public._fmt_usd(numeric) set search_path = public;
alter function public.set_updated_at() set search_path = public;
alter function public.gen_referral_code() set search_path = public;
alter function public._block_modification() set search_path = public;
alter function public._wallet_guard() set search_path = public;
