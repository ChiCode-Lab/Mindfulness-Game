# Project Context
**Goal:** Build a gamified mindfulness application where users identify subtle visual changes in a grid of shapes (Solo and Multiplayer modes).
*(Note: To increase visual engagement, use 3D items for the grid shapes—e.g. 3D pebbles, leaves, or trees—rendered in Flutter.)*
**Tech Stack:** React Native / Flutter (Mobile-first), Supabase (Backend)

## Current Status
- [x] Initial Context Bridge Setup
- [x] Gather brainstorming requirements
- [x] Create Stitch Design Prompt (`next-prompt.md`)
- [x] Generate UI designs in Stitch based on the prompt
- [x] Generate `DESIGN.md` from Stitch screen
- [x] Begin Front-End Implementaton
- [x] Designed Product-Led Viral Growth System
- [ ] Implement Fast-Track Auth and Deep Linking App Links
- [ ] Setup Supabase DB Triggers for Referral Webhooks

## ⚡ CURRENT TASK FOR TERMINAL AGENT (@BigPickle)
**Instructions:**
1. Antigravity has handed off **Task 2: Supabase Referral Reward Webhook (DB Trigger)** from the Viral Growth implementation plan (`mindfulness_app/docs/plans/2026-03-26-viral-growth-plan.md`).
2. Your task is to implement the Postgres Trigger or Supabase Edge Function that handles the "Plant a Tree for Someone" reward loop. 
3. **Logic needed:** When a new user completes their *first standard solo mindfulness session* (recorded in the `progress` table), identify if they have a `referred_by` value in their `users` profile. If they do:
   - Deposit +100 Opals to the Inviter's account.
   - Deposit +50 Opals to the Friend's account.
   - Spawn a unique "Tree" record in the `legacy_trees` table for the Inviter, setting `gifted_by` to the new user's ID.
4. **Validation:** Write a failing Database Test (`supabase db test`) first exactly as demonstrated in the Step-By-Step plan. Implement the migration `supabase/migrations/2026_03_26_viral_rewards.sql`. Ensure testing passes and commit your changes.

## Architecture Notes
- The interface relies heavily on a soft, ethereal vibe to promote mindfulness.
- Design elements are minimal, using frosted glass effects (glassmorphism) over a deep, calming background gradient.
- Supabase integration serves as the source-of-truth for user Opals, Legacy Forest structures, and Co-op Room State.
