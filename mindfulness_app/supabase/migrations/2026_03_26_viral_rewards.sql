-- Viral Rewards System: Referral "Plant a Tree" Loop
-- Trigger fires when a new user completes their first solo mindfulness session

-- Step 1: Create user_profiles table with referred_by field (extends auth.users)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    referred_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    username TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS for user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own profile
CREATE POLICY "Users can view own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = id);

-- Allow authenticated users to insert their own profile
CREATE POLICY "Users can insert own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Step 2: Create progress table for session tracking
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

-- Index for faster lookup of user's progress records
CREATE INDEX IF NOT EXISTS idx_progress_user_id ON public.progress(user_id);
CREATE INDEX IF NOT EXISTS idx_progress_session_date ON public.progress(session_date);

-- Enable RLS for progress
ALTER TABLE public.progress ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own progress
CREATE POLICY "Users can view own progress"
    ON public.progress FOR SELECT
    USING (auth.uid() = user_id);

-- Allow authenticated users to insert their own progress
CREATE POLICY "Users can insert own progress"
    ON public.progress FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Step 3: Create legacy_trees table for gifted trees
CREATE TABLE IF NOT EXISTS public.legacy_trees (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    gifted_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'planted', -- 'planted', 'growing', 'mature'
    tree_type TEXT DEFAULT 'gifted_oak',
    leaf_count INTEGER DEFAULT 0,
    planted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for faster lookup
CREATE INDEX IF NOT EXISTS idx_legacy_trees_user_id ON public.legacy_trees(user_id);

-- Enable RLS for legacy_trees
ALTER TABLE public.legacy_trees ENABLE ROW LEVEL SECURITY;

-- Allow users to read their own legacy trees
CREATE POLICY "Users can view own legacy trees"
    ON public.legacy_trees FOR SELECT
    USING (auth.uid() = user_id);

-- Allow users to read gifted trees (for inviter's forest)
CREATE POLICY "Users can view gifted trees"
    ON public.legacy_trees FOR SELECT
    USING (auth.uid() = user_id);

-- Step 4: Create the referral rewards trigger function
-- This trigger fires AFTER INSERT on progress table
CREATE OR REPLACE FUNCTION public.handle_referral_rewards()
RETURNS TRIGGER AS $$
DECLARE
    inviter_id UUID;
    first_session_count INTEGER;
BEGIN
    -- Only process standard solo sessions
    IF NEW.session_type != 'solo' THEN
        RETURN NEW;
    END IF;

    -- Check if this is the user's first progress record (first solo session)
    SELECT COUNT(*) INTO first_session_count
    FROM public.progress
    WHERE user_id = NEW.user_id;

    -- Only proceed if this is their first session
    IF first_session_count = 1 THEN
        -- Find if they were referred
        SELECT referred_by INTO inviter_id
        FROM public.user_profiles
        WHERE id = NEW.user_id;

        -- If user was referred by someone
        IF inviter_id IS NOT NULL THEN
            -- Deposit +100 Opals to Inviter's account
            UPDATE public.user_economy
            SET opals_balance = opals_balance + 100,
                updated_at = NOW()
            WHERE id = inviter_id;

            -- Deposit +50 Opals to Friend's account
            UPDATE public.user_economy
            SET opals_balance = opals_balance + 50,
                updated_at = NOW()
            WHERE id = NEW.user_id;

            -- Spawn a unique "Tree" record in legacy_trees for the Inviter
            INSERT INTO public.legacy_trees (user_id, gifted_by, status, tree_type)
            VALUES (inviter_id, NEW.user_id, 'planted', 'gifted_oak');
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if exists (for idempotency)
DROP TRIGGER IF EXISTS on_first_session_complete ON public.progress;

-- Create the trigger on progress table
CREATE TRIGGER on_first_session_complete
    AFTER INSERT ON public.progress
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_referral_rewards();

-- Step 5: Add referred_by column to existing user_economy if needed (for convenience)
-- This provides a shortcut to access referral info alongside opals
ALTER TABLE public.user_economy
ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;
