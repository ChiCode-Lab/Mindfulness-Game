# Premium Subscription Plan: ZenForest
**Date:** 2026-03-21
**Status:** Approved — Ready for Implementation
**Platform Priority:** Android (Google Play) first

---

## 1. Overview

When a user's 5-day free trial ends, ZenForest presents a branded **"Zen Paywall"** screen that leverages their personal progress — their Legacy Forest, streak, and presence level — as the emotional conversion hook. Users must make an explicit choice: subscribe or tap "Continue Free." There is no silent drop-off.

The subscription infrastructure is powered by **RevenueCat**, which handles Google Play receipt validation, entitlement management, expiry webhooks, and restore purchases. RevenueCat syncs premium status back to Supabase via webhook, keeping `EconomyService` as the single source of truth for the app.

---

## 2. Pricing Tiers

| Tier | Price | Effective Rate | Google Play Product ID |
|------|-------|----------------|------------------------|
| **Monthly** | $9.99 / month | $9.99/mo | `zenforest_premium_monthly` |
| **Annual** | $59.99 / year | ~$5.00/mo | `zenforest_premium_annual` |

The **Annual plan is the conversion target** — it should be visually highlighted as "Best Value" with the effective monthly rate prominently displayed.

---

## 3. What Premium Unlocks

- Completely bypasses the Opal economy — unlimited sessions with no cost
- Maxed complexity grids (4×4) with no Opal gate
- Unlimited session duration
- Full premium soundscape library (Rain, Ocean, Campfire, Forest)
- Legacy Forest shows all 12 days (free users see only 5)
- Zero ads, ever

---

## 4. Pre-Expiry Nudge Flow (Day 3 of 5)

On Day 3 of the trial, a two-part nudge is triggered **once only**:

### 4a. Persistent Banner (Dashboard)
- Appears at the top of `DashboardScreen` below the header
- Text: *"Your Zen sanctuary expires in 2 days — lock it in ✨"*
- Coral accent color (`#FF8A66`) with a subtle glow border
- Tapping it navigates to `PaywallScreen`
- Persists until trial expires or user subscribes
- Stored flag in `SharedPreferences`: `shown_trial_nudge_banner: true`

### 4b. One-Time Modal (App Open)
- Appears once on the first app open on Day 3
- Full-screen glassmorphic overlay (consistent with `_TreeDetailOverlay` style)
- Shows user's current streak + leaf count + "2 days remaining"
- Two buttons: **"See Plans"** (coral CTA) and **"Maybe Later"** (muted dismiss)
- Stored flag in `SharedPreferences`: `shown_trial_nudge_modal: true`

---

## 5. The Zen Paywall Screen (`PaywallScreen`)

Triggered on the **first app open after trial expiry**. The user **must make an explicit choice** — there is no way to dismiss without tapping either a subscription option or "Continue Free."

### 5a. Visual Layout

```
┌─────────────────────────────────────┐
│  [Blurred Legacy Forest background] │
│                                     │
│  "Your Sanctuary Awaits"            │  ← headline
│  "You grew X trees. Keep your       │
│   forest growing."                  │  ← personal stat hook
│                                     │
│  ┌─────────────────────────────┐    │
│  │  MONTHLY      $9.99/mo      │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ ★ ANNUAL   $59.99/yr        │    │  ← highlighted "Best Value"
│  │   ~$5.00/mo · Save 50%      │    │
│  └─────────────────────────────┘    │
│                                     │
│  [Subscribe — Start Now]            │  ← primary CTA
│  [Restore Purchases]                │  ← secondary
│  [Continue Free →]                  │  ← explicit free path
│                                     │
│  Privacy Policy · Terms of Use      │
└─────────────────────────────────────┘
```

### 5b. Behaviour Rules
- Background is a **live blurred snapshot** of the user's actual `ForestScreen` grid — makes the loss tangible
- Selecting a tier highlights it; tapping **"Subscribe — Start Now"** triggers the RevenueCat purchase flow
- **"Continue Free"** explicitly downgrades the user back to the Opal economy and navigates to Dashboard
- **"Restore Purchases"** calls `RevenueCat.restorePurchases()` for users who reinstall

---

## 6. Post-Trial Free User Re-engagement

For users who tap "Continue Free," the paywall does not reappear on every launch. Instead:

- A **persistent soft banner** stays on the Dashboard: *"✨ Go Premium — Unlimited Sessions"*
- The `OutOfOpalsDialog` (already implemented) gains a third button: **"Go Premium"** which navigates to `PaywallScreen`
- The Legacy Forest locked cells (days 6–12) show a soft "Premium" blur — tapping any locked cell navigates to `PaywallScreen`

### Daily Login Opal Reward (Streak Scaling)
To keep free users engaged until they convert:

| Streak | Daily Opal Reward |
|--------|-------------------|
| Day 1–6 | 20 Opals |
| Day 7–13 | 35 Opals |
| Day 14–29 | 50 Opals |
| Day 30+ | 100 Opals |

Stored in `user_economy.last_daily_reward` (already exists in `supabase_monetization_tables.sql`).

---

## 7. Technical Architecture

### 7a. New Dependencies (`pubspec.yaml`)
```yaml
purchases_flutter: ^6.x.x   # RevenueCat Flutter SDK
```

### 7b. New Files

| File | Responsibility |
|------|---------------|
| `lib/services/subscription_service.dart` | RevenueCat wrapper — init, purchase, restore, entitlement check |
| `lib/screens/paywall_screen.dart` | The Zen Paywall UI |
| `lib/widgets/trial_nudge_banner.dart` | Persistent Day 3 banner for Dashboard |
| `lib/widgets/trial_nudge_modal.dart` | One-time Day 3 modal on app open |

### 7c. Modified Files

| File | Change |
|------|--------|
| `lib/models/economy_state.dart` | Add `premiumSource` enum (`trial`, `subscription`, `free`); add `isPaidSubscriber` bool |
| `lib/services/economy_service.dart` | Delegate `isPremium` to check both trial expiry AND RevenueCat entitlement; add `claimDailyOpalReward()` |
| `lib/main.dart` | Init `SubscriptionService` at app startup alongside Supabase |
| `lib/screens/dashboard_screen.dart` | Add `TrialNudgeBanner` widget below header; check for paywall trigger on init |
| `lib/widgets/out_of_opals_dialog.dart` | Add "Go Premium" third button |
| `supabase_monetization_tables.sql` | Add `subscription_status`, `subscription_expires_at`, `premium_source` columns; add RevenueCat webhook handler |

### 7d. Data Model Addition (`user_economy` table)

```sql
ALTER TABLE public.user_economy
  ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(20) DEFAULT 'free',
  -- values: 'free' | 'trial' | 'active' | 'expired' | 'cancelled'
  ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS premium_source VARCHAR(20) DEFAULT 'none';
  -- values: 'none' | 'trial' | 'revenuecat'
```

### 7e. RevenueCat Webhook → Supabase Edge Function

RevenueCat sends webhook events (`INITIAL_PURCHASE`, `RENEWAL`, `CANCELLATION`, `EXPIRATION`) to a Supabase Edge Function (`/functions/v1/revenuecat-webhook`) which updates `user_economy.subscription_status` accordingly.

### 7f. `SubscriptionService` Public API

```dart
class SubscriptionService {
  Future<void> init(String userId);
  Future<bool> isPremiumActive();                  // checks RC entitlement
  Future<bool> purchaseMonthly();
  Future<bool> purchaseAnnual();
  Future<bool> restorePurchases();
  String get activeProductId;                      // which plan is active
}
```

---

## 8. `EconomyService.isPremium` Logic (Updated)

```
isPremium = 
  (premiumTrialEnd != null AND now < premiumTrialEnd)   // trial active
  OR
  SubscriptionService.isPremiumActive()                  // paid subscription active
```

This ensures both paths are honoured with a single `isPremium` check throughout the app — no changes needed in `GameScreen`, `SettingsScreen`, `ForestScreen`, etc.

---

## 9. Implementation Phases

### Phase 1 — Infrastructure
1. Add `purchases_flutter` to `pubspec.yaml`
2. Create `SubscriptionService` with RevenueCat init + entitlement check
3. Update `EconomyState` model with `premiumSource` enum
4. Update `EconomyService.isPremium` to delegate to `SubscriptionService`
5. Add Supabase SQL migration for new columns
6. Create Supabase Edge Function for RevenueCat webhook

### Phase 2 — Paywall Screen
7. Build `PaywallScreen` with blurred forest background, two pricing tiers, and forced choice UX
8. Wire "Subscribe" buttons to `SubscriptionService.purchaseMonthly/Annual()`
9. Wire "Restore Purchases" button
10. Wire "Continue Free" explicit downgrade path

### Phase 3 — Nudge System
11. Build `TrialNudgeBanner` widget
12. Build `TrialNudgeModal` widget
13. Add both to `DashboardScreen` with Day 3 logic and `SharedPreferences` flags

### Phase 4 — Re-engagement Loop
14. Add `claimDailyOpalReward()` to `EconomyService` with streak-scaling table
15. Add "Go Premium" button to `OutOfOpalsDialog`
16. Wire locked Legacy Forest cells to `PaywallScreen`

---

## 10. Google Play Setup Checklist (Pre-Launch)

- [ ] Create app in Google Play Console
- [ ] Set up two subscription products: `zenforest_premium_monthly` ($9.99) and `zenforest_premium_annual` ($59.99)
- [ ] Configure 5-day free trial on both products in Play Console
- [ ] Add RevenueCat as a Real-Time Developer Notification endpoint in Play Console
- [ ] Set `REVENUECAT_API_KEY` in app (store securely — not committed to repo)
- [ ] Configure RevenueCat webhook URL pointing to Supabase Edge Function
- [ ] Test full purchase → entitlement → webhook → Supabase flow in sandbox

---

## 11. Design Tokens (Consistent with Existing Design System)

All new screens and widgets use the existing design system from `DESIGN.md`:

| Token | Value |
|-------|-------|
| Background | `#1A233A` → `#2D1B4E` radial gradient |
| Primary Accent / CTA | `#FF8A66` (Soft Coral) |
| Glass Surface | `rgba(255,255,255,0.05)` + `BackdropFilter blur(12px)` |
| Text Primary | `#F8F9FA` |
| Text Secondary | `#B0BEC4` |
| Annual Highlight | `rgba(255,138,102,0.2)` border + `#FF8A66` badge |
| Font | Quicksand (existing Google Fonts) |

---

*This document serves as the single source of truth for the premium subscription feature. All implementation work should reference this plan. Code generation follows the `generating-mobile-code` skill workflow.*
