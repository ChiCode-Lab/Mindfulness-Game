-- Create the User Economy table
CREATE TABLE IF NOT EXISTS public.user_economy (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    opals_balance INT4 NOT NULL DEFAULT 100,
    premium_trial_end TIMESTAMPTZ,
    last_daily_reward TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS for user_economy
ALTER TABLE public.user_economy ENABLE ROW LEVEL SECURITY;

-- Create policies so users can only view and update their own economy row
CREATE POLICY "Users can view own economy" ON public.user_economy
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own economy" ON public.user_economy
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own economy" ON public.user_economy
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Trigger to automatically create user_economy row when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user_economy()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_economy (id, opals_balance)
    VALUES (NEW.id, 100);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop trigger if it exists (for idempotency)
DROP TRIGGER IF EXISTS on_auth_user_created_economy ON auth.users;

-- Create the trigger
CREATE TRIGGER on_auth_user_created_economy
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_economy();


-- Alter existing zen_rooms table to support the Social Surcharge
ALTER TABLE public.zen_rooms
ADD COLUMN IF NOT EXISTS entry_cost INT4 DEFAULT 0;
