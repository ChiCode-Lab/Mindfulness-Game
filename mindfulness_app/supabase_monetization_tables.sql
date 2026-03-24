-- ─────────────────────────────────────────────────────────────
-- Phase 1: Premium Subscription Columns
-- Run this in the Supabase SQL Editor after the existing schema.
-- ─────────────────────────────────────────────────────────────

ALTER TABLE public.user_economy
  ADD COLUMN IF NOT EXISTS is_paid_subscriber    BOOLEAN       NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS subscription_status   VARCHAR(20)   NOT NULL DEFAULT 'free',
  -- values: 'free' | 'trial' | 'active' | 'expired' | 'cancelled'
  ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS premium_source        VARCHAR(20)   NOT NULL DEFAULT 'none';
  -- values: 'none' | 'trial' | 'revenuecat'

-- Index for fast webhook lookups by RevenueCat app_user_id.
-- RevenueCat app_user_id is set to the Supabase user UUID in SubscriptionService.init().
CREATE INDEX IF NOT EXISTS idx_user_economy_subscription_status
  ON public.user_economy (subscription_status);
