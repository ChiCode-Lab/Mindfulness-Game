# Implementation Plan: Zen Forest & Metrics Overhaul

This plan follows the "Effective Harnesses for Long-Running Agents" pattern to ensure incremental, stable progress across coding sessions.

## 🛠 Session Start Protocol (The Harness)
Every new session MUST follow these steps before writing code:
1.  **Check Local State**: Run `pwd` and `ls -R` to verify environment.
2.  **Read Progress**: Read `zen-forest-progress.json` and recent git logs.
3.  **Choose Feature**: Pick the highest priority `passes: false` feature from the JSON list.
4.  **Baseline Test**: Run `flutter analyze` and `flutter test` (if applicable) to ensure the app isn't already broken.
5.  **Initialize**: Run any required setup (mocking 3D assets or services).

## 📋 Feature Tracking (High-Level)
We use `zen-forest-features.json` to track individual end-to-end features. An agent is successful only when all tests in that file mark `passes: true` after manual or automated verification.

## 🏗 Development Phases

### Phase 1: The Metrics Engine (Presence & Focus)
- **Goal**: Implement the FIFO queue for Presence Level (+1/-1 point system).
- **Verification**: Unit tests for the `ProgressService` queue logic.

### Phase 2: 3D Asset & Rendering 
- **Goal**: Integrate `tree_gn.glb` and create the `ZenTreeRenderer` with dynamic scaling.
- **Verification**: Visual check via Flutter Driver or manual inspection.

### Phase 3: The Forest Grid (Historical View)
- **Goal**: Build the Bento-style grid for the Legacy Forest.
- **Verification**: Verify 5-day limit for free users and 12-day display for premium.

### Phase 4: Interactive Overlays
- **Goal**: Tapping a tree reveals the Glassmorphic Daily Insight.
- **Verification**: Ensure Solo vs. Coop breakdown matches stored data.

## 🧼 Session End Protocol
1.  **Update JSON**: Change `passes: false` to `true` for completed features.
2.  **Clean State**: Run `flutter analyze` to ensure no new warnings/errors.
3.  **Git Commit**: Commit changes with a descriptive message (e.g., `feat: implemented FIFO presence queue`).
4.  **Handover**: Summarize remaining work for the next session.
