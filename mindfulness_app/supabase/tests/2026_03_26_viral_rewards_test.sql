-- pgTap tests for Viral Rewards System
-- Run with: supabase db test

BEGIN;

SELECT plan(6);

-- Test 1: Referral reward trigger exists
SELECT has_function('public', 'handle_referral_rewards', 
    'Function handle_referral_rewards should exist');

-- Test 2: Trigger exists on progress table
SELECT has_trigger('public', 'progress', 'on_first_session_complete',
    'Trigger on_first_session_complete should exist on progress table');

-- Test 3: user_profiles table exists with referred_by
SELECT has_table('public', 'user_profiles',
    'user_profiles table should exist');
SELECT column_exists('public', 'user_profiles', 'referred_by',
    'user_profiles should have referred_by column');

-- Test 4: legacy_trees table exists
SELECT has_table('public', 'legacy_trees',
    'legacy_trees table should exist');
SELECT column_exists('public', 'legacy_trees', 'gifted_by',
    'legacy_trees should have gifted_by column');

-- Test 5: progress table exists
SELECT has_table('public', 'progress',
    'progress table should exist');
SELECT column_exists('public', 'progress', 'user_id',
    'progress should have user_id column');

-- Test 6: No rewards for non-referred user (baseline)
-- This is a conceptual test - actual integration tests would require
-- creating test users in the database

SELECT * FROM finish();

ROLLBACK;
