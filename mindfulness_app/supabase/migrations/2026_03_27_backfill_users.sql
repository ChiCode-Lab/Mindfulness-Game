-- 2026_03_27_backfill_users.sql
-- Ensures all existing auth.users have records in user_profiles and user_economy

DO $$
BEGIN
    -- Backfill user_profiles if missing
    INSERT INTO public.user_profiles (id, username, has_completed_onboarding)
    SELECT id, 'zen_' || substr(id::text, 1, 8), true
    FROM auth.users
    ON CONFLICT (id) DO NOTHING;

    -- Backfill user_economy if missing
    INSERT INTO public.user_economy (id, opals_balance, is_paid_subscriber)
    SELECT id, 100, false
    FROM auth.users
    ON CONFLICT (id) DO NOTHING;
END $$;
