-- Viral Rewards System: Referral "Plant a Tree" Loop
-- Trigger fires when a new user completes their first solo mindfulness session

-- 1. User profiles (extends auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    referred_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    username TEXT UNIQUE,
    is_public BOOLEAN DEFAULT false,
    has_completed_onboarding BOOLEAN DEFAULT false,
    current_streak INTEGER DEFAULT 0,
    longest_streak INTEGER DEFAULT 0,
    total_mindful_minutes INTEGER DEFAULT 0,
    last_meditated_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. User economy (Source of Truth for Opals and Subscription)
CREATE TABLE IF NOT EXISTS public.user_economy (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    opals_balance INTEGER DEFAULT 100,
    is_paid_subscriber BOOLEAN DEFAULT false,
    premium_source TEXT DEFAULT 'none', -- 'none', 'trial', 'revenuecat'
    premium_trial_end TIMESTAMPTZ,
    subscription_status TEXT DEFAULT 'free',
    last_daily_reward TIMESTAMPTZ,
    referred_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Progress tracking
CREATE TABLE IF NOT EXISTS public.progress (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_type TEXT NOT NULL DEFAULT 'solo', -- 'solo' or 'multiplayer'
    grid_size INTEGER,
    duration_seconds INTEGER,
    score INTEGER DEFAULT 0,
    session_date DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Legacy forest (Synced trees)
CREATE TABLE IF NOT EXISTS public.legacy_forest (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    tree_data JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Gifted trees tracking (Unique referral trees)
CREATE TABLE IF NOT EXISTS public.legacy_trees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    gifted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'planted',
    tree_type TEXT DEFAULT 'gifted_oak',
    leaf_count INTEGER DEFAULT 0,
    planted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS POLICIES --

-- user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Profiles are public if is_public is true" ON public.user_profiles FOR SELECT USING (is_public = true);

-- user_economy
ALTER TABLE public.user_economy ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own economy" ON public.user_economy FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own economy" ON public.user_economy FOR INSERT WITH CHECK (auth.uid() = id);
-- Note: Update is usually handled via server-side functions or limited fields, but for now let's allow own update
CREATE POLICY "Users can update own economy" ON public.user_economy FOR UPDATE USING (auth.uid() = id);

-- progress
ALTER TABLE public.progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own progress" ON public.progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON public.progress FOR INSERT WITH CHECK (auth.uid() = user_id);

-- legacy_forest
ALTER TABLE public.legacy_forest ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own legacy forest" ON public.legacy_forest FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own legacy forest" ON public.legacy_forest FOR INSERT WITH CHECK (auth.uid() = user_id);
-- Allow public viewing of forest if the profile is public
CREATE POLICY "Public can view forest of public profiles" ON public.legacy_forest FOR SELECT 
USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE id = user_id AND is_public = true));

-- legacy_trees
ALTER TABLE public.legacy_trees ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view own legacy trees" ON public.legacy_trees FOR SELECT USING (auth.uid() = user_id);

-- TRIGGER LOGIC --

CREATE OR REPLACE FUNCTION public.handle_referral_rewards()
RETURNS TRIGGER AS $$
DECLARE
    inviter_id UUID;
    first_session_count INTEGER;
BEGIN
    IF NEW.session_type != 'solo' THEN
        RETURN NEW;
    END IF;

    SELECT COUNT(*) INTO first_session_count
    FROM public.progress
    WHERE user_id = NEW.user_id;

    IF first_session_count = 1 THEN
        SELECT referred_by INTO inviter_id
        FROM public.user_profiles
        WHERE id = NEW.user_id;

        IF inviter_id IS NOT NULL THEN
            UPDATE public.user_economy
            SET opals_balance = opals_balance + 100,
                updated_at = NOW()
            WHERE id = inviter_id;

            UPDATE public.user_economy
            SET opals_balance = opals_balance + 50,
                updated_at = NOW()
            WHERE id = NEW.user_id;

            INSERT INTO public.legacy_trees (user_id, gifted_by, status, tree_type)
            VALUES (inviter_id, NEW.user_id, 'planted', 'gifted_oak');
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_first_session_complete ON public.progress;
CREATE TRIGGER on_first_session_complete
    AFTER INSERT ON public.progress
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_referral_rewards();

-- Initial Population (Optional convenience)
-- This trigger handles profile/economy creation on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, username, is_public)
  VALUES (NEW.id, 'user_' || substr(NEW.id::text, 1, 8), false);

  INSERT INTO public.user_economy (id)
  VALUES (NEW.id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
