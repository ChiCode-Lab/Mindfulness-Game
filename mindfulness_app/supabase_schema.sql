-- Mindfulness App Supabase Initialization Script
-- Run this directly in the Supabase SQL Editor

-- 1. Create the matchmaking_queue table
CREATE TABLE IF NOT EXISTS public.matchmaking_queue (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL,
    grid_size INTEGER NOT NULL,
    session_length INTEGER NOT NULL,
    joined_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create the zen_rooms table
CREATE TABLE IF NOT EXISTS public.zen_rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id VARCHAR(6) UNIQUE NOT NULL, -- The 6-digit room code
    player_1_id UUID NOT NULL,
    player_2_id UUID,                     -- Null until second player joins
    shared_leaf_count INTEGER DEFAULT 0,
    active_target_index INTEGER NOT NULL,
    mutation_type VARCHAR(50) NOT NULL,
    spawn_timestamp TIMESTAMPTZ DEFAULT NOW(),
    grid_size INTEGER NOT NULL,
    session_length INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'active',  -- 'active' or 'completed'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Enable Realtime on zen_rooms
-- This allows clients to listen for state changes like score increments
alter publication supabase_realtime add table public.zen_rooms;

-- 4. Enable RLS (Row Level Security) - Simplified for Anonymous usage
ALTER TABLE public.matchmaking_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zen_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous read access to zen_rooms"
ON public.zen_rooms FOR SELECT
TO anon
USING (true);

CREATE POLICY "Allow anonymous insert access to zen_rooms"
ON public.zen_rooms FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow anonymous update access to zen_rooms"
ON public.zen_rooms FOR UPDATE
TO anon
USING (true);

CREATE POLICY "Allow anonymous read access to matchmaking_queue"
ON public.matchmaking_queue FOR SELECT
TO anon
USING (true);

CREATE POLICY "Allow anonymous insert access to matchmaking_queue"
ON public.matchmaking_queue FOR INSERT
TO anon
WITH CHECK (true);

CREATE POLICY "Allow anonymous delete from matchmaking_queue"
ON public.matchmaking_queue FOR DELETE
TO anon
USING (true);

-- 5. Matchmaking Postgres Function (RPC)
-- This function automatically pairs players with exact same settings
CREATE OR REPLACE FUNCTION public.find_or_create_match(
    p_user_id UUID, 
    p_grid_size INTEGER, 
    p_session_length INTEGER
) 
RETURNS VARCHAR(6) AS $$
DECLARE
    matched_user UUID;
    new_room_id VARCHAR(6);
BEGIN
    -- 1. Check if there's someone in the queue with matching preferences
    SELECT user_id INTO matched_user
    FROM public.matchmaking_queue
    WHERE grid_size = p_grid_size AND session_length = p_session_length AND user_id != p_user_id
    ORDER BY joined_at ASC
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF matched_user IS NOT NULL THEN
        -- We found a match! Remove them from the queue
        DELETE FROM public.matchmaking_queue WHERE user_id = matched_user;

        -- Generate a 6-digit room ID mathematically
        new_room_id := lpad(floor(random() * 1000000)::text, 6, '0');

        -- Create the new active zen_room for both players
        INSERT INTO public.zen_rooms (
            room_id, player_1_id, player_2_id, active_target_index, mutation_type, grid_size, session_length
        ) VALUES (
            new_room_id, matched_user, p_user_id, 0, 'MutationType.color', p_grid_size, p_session_length
        );

        RETURN new_room_id;
    ELSE
        -- No match found. Add current user to the wait queue
        -- Delete any existing entries for this user first
        DELETE FROM public.matchmaking_queue WHERE user_id = p_user_id;

        INSERT INTO public.matchmaking_queue (user_id, grid_size, session_length)
        VALUES (p_user_id, p_grid_size, p_session_length);

        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
