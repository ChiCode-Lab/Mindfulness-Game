# 🌿 ZenForest — Mindfulness Game

> A gamified mindfulness Flutter app where players identify subtle visual changes in a 3D shape grid — solo or cooperatively. Progress grows a daily 3D tree inside a personal "Legacy Forest".

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Repository Structure](#repository-structure)
4. [Architecture](#architecture)
5. [Key Features & Game Loop](#key-features--game-loop)
6. [Getting Started (Dev Setup)](#getting-started-dev-setup)
7. [Agent / AI Coding Collaboration](#agent--ai-coding-collaboration)
8. [Roadmap & Current Status](#roadmap--current-status)
9. [Design System](#design-system)
10. [Environment Variables & Secrets](#environment-variables--secrets)

---

## Project Overview

ZenForest is a mobile-first **Flutter** app designed to make mindfulness accessible through gentle gameplay. The core mechanic is a **4×4 or 5×5 grid** of 3D-rendered shapes (opal gems, trees, pebbles) where one shape subtly changes — the player must spot it before time runs out.

Every correct detection earns **leaves**, which grow a 3D tree. After 24 hours, that tree takes its place in a scrollable **Legacy Forest** — a visual diary of the last 5 (free) or 12 (premium) days.

**Design ethos:** Ethereal, calming, minimal. Glassmorphism over a deep twilight gradient (`#1A233A` → `#2D1B4E`). Primary accent: Coral/Peach (`#FF8A66`).

---

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **UI Framework** | Flutter 3.x (Dart `^3.11.0`) | Cross-platform mobile (Android primary) |
| **3D Rendering** | `flutter_3d_controller ^2.3.0` | Renders `.glb` models (tree, opal) |
| **Backend / DB** | Supabase (`supabase_flutter ^2.12.0`) | Auth, global scores, multiplayer sync |
| **Local Storage** | `shared_preferences ^2.5.4` | Session stats, presence queue |
| **Audio** | `audioplayers ^5.2.1` | Ambient soundscape engine |
| **Fonts** | `google_fonts ^8.0.2` | Manrope (primary), Inter (secondary) |
| **Notifications** | `flutter_local_notifications ^20.1.0` | Daily mindfulness reminders |
| **Background** | `workmanager ^0.9.0+3` | Periodic tree-growth background tasks |

---

## Repository Structure

```
Mindfulness App/              ← Repo root
├── .agent/                   ← AI agent workspace (skills & workflows)
│   ├── skills/               ← Agent skills (brand-identity, planning, ui-ux-pro-max, etc.)
│   └── workflows/            ← Slash-command workflows for AI agents
├── mindfulness_app/          ← The Flutter project
│   ├── lib/
│   │   ├── main.dart                 ← App entry point, theme, routing
│   │   ├── models/                   ← Data models
│   │   │   ├── zen_tree.dart         ← ZenTreeData (daily tree state)
│   │   │   ├── game_metrics.dart     ← PresenceLevel, DeepFocus metrics
│   │   │   ├── game_settings.dart    ← Grid size, difficulty config
│   │   │   └── economy_state.dart    ← Coin/leaf economy state
│   │   ├── services/                 ← Business logic layer
│   │   │   ├── progress_service.dart ← FIFO presence queue, session stats
│   │   │   ├── economy_service.dart  ← Coin/leaf economy & supabase sync
│   │   │   ├── multiplayer_service.dart ← Supabase realtime co-op sessions
│   │   │   ├── notification_service.dart ← Local daily reminders
│   │   │   ├── background_task_service.dart ← Workmanager background jobs
│   │   │   └── soundscape_engine.dart ← Ambient audio playback
│   │   ├── screens/                  ← Full-page UI screens
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── dashboard_screen.dart ← Home + game trigger
│   │   │   ├── forest_screen.dart    ← Legacy Forest (3D tree grid)
│   │   │   ├── coop_game_screen.dart ← Cooperative multiplayer gameplay
│   │   │   ├── multiplayer_lobby_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/                  ← Reusable UI components
│   ├── assets/
│   │   ├── 3D/                       ← GLB models: tree_gn.glb, opal.glb, maple_tree.glb
│   │   ├── audio/                    ← Ambient soundscape audio files
│   │   └── web/                      ← WebView assets (Three.js shaders for opal grid)
│   ├── test/                         ← Unit & widget tests
│   ├── docs/                         ← Per-project PRD, feature tracker, activity log
│   │   ├── PRD-ZenForest-2026-02-28.md
│   │   ├── zen-forest-features.json  ← Feature tracker (passes: true/false)
│   │   ├── plan.md                   ← Session-based implementation plan
│   │   └── activity.md               ← Dev activity log
│   └── pubspec.yaml
├── PRD-ZenForest-2026-02-28.md  ← Root copy of the PRD
├── DESIGN.md                    ← Design system (colors, typography, components)
├── CONTEXT.md                   ← Context Bridge file for AI agent handoffs
├── plan.md                      ← Harness-style implementation plan
├── supabase_monetization_tables.sql ← SQL for premium/economy Supabase tables
└── README.md                    ← This file
```

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter UI Layer                   │
│  Screens: Dashboard, Forest, CoopGame, Settings     │
│  Widgets: GameGrid, ZenTreeRenderer, GlassCard      │
└─────────────────┬───────────────────────────────────┘
                  │ calls
┌─────────────────▼───────────────────────────────────┐
│               Services Layer                        │
│  ProgressService  │  EconomyService  │  MultiService│
│  (FIFO queue)     │  (coins/leaves)   │  (Supabase) │
│  SoundscapeEngine │  NotificationSvc │  BgTaskSvc   │
└─────────────────┬───────────────────────────────────┘
                  │ persists to
        ┌─────────┴──────────┐
        │  SharedPreferences  │    ↔    Supabase (remote)
        └─────────────────────┘
```

### Core Data Flow (Solo Session)
1. User starts a session → `ProgressService.startSession()`
2. Grid renders 3D shapes via `flutter_3d_controller`
3. User taps changed shape → `+1` to FIFO presence queue → leaf awarded
4. Miss → `-1` to FIFO queue
5. Session end → `EconomyService.addLeaves()` → Supabase sync
6. `ZenTreeData` updated → tree grows in `ForestScreen`

---

## Key Features & Game Loop

### 🎮 Gameplay
- **Solo Mode:** Race against a timer to spot the changed 3D shape
- **Co-op Mode:** Real-time multiplayer via Supabase Realtime channels — share a board, combine leaf counts

### 🌳 Zen Forest (Gamification Layer)
- **Daily Tree:** Grows in real-time based on `leafCount`; resets at midnight
- **Legacy Forest:** Bento-grid of the last 5 (free) or 12 (premium) days of trees
- **Leaf Infusion Animation:** AnimatedScale pulse when new leaves are added

### 📊 Mindfulness Metrics
- **Presence Level (0–100):** FIFO queue of last 50 interactions (+1 hit / -1 miss), sum normalized to 0–100
- **Deep Focus:** Rolling average of reaction time (ms) across detection events

### 💰 Economy
- Leaves → in-app currency
- `EconomyService` handles coin purchases, leaf-to-coin conversion, and Supabase sync

---

## Getting Started (Dev Setup)

### Prerequisites
- Flutter SDK `3.x` with Dart `^3.11.0`
- Android Studio with an Android emulator configured (see `emulators.txt`)
- A Supabase project with the schema from `mindfulness_app/supabase_schema.sql`

### 1. Clone & Install
```bash
git clone https://github.com/ChiCode-Lab/Mindfulness-Game.git
cd "Mindfulness-Game/mindfulness_app"
flutter pub get
```

### 2. Configure Supabase
Create a file at `mindfulness_app/lib/supabase_config.dart` (not committed — add to `.gitignore`):
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Apply the schema:
```bash
# In your Supabase dashboard SQL editor, run:
# mindfulness_app/supabase_schema.sql
# supabase_monetization_tables.sql  (root of repo)
```

### 3. Run
```bash
# List available emulators
flutter emulators

# Launch on Android emulator
flutter run -d <emulator_id>
```

### 4. Test
```bash
flutter analyze
flutter test
```

---

## Agent / AI Coding Collaboration

This repo is designed to be worked on collaboratively with AI coding agents (e.g., Antigravity, OpenCode, etc.).

### Key Files for AI Agents
| File | Purpose |
|---|---|
| `CONTEXT.md` | **Context Bridge** — current task, status checklist, architecture notes |
| `plan.md` | Session harness protocol: start/end steps, phases, feature tracking |
| `mindfulness_app/docs/zen-forest-features.json` | Feature tracker (`passes: true/false`) — pick the next `false` feature |
| `mindfulness_app/docs/activity.md` | Activity log of what has been done |
| `DESIGN.md` | Full design system — colors, typography, component rules |
| `PRD-ZenForest-2026-02-28.md` | Full product requirements document |
| `.agent/skills/` | Agent skills for UI/UX, planning, brainstorming, brand identity, etc. |
| `.agent/workflows/` | Slash-command workflows: `/ui-ux-pro-max` |

### Session Start Protocol (for AI Agents)
> Always follow this before writing code:

1. Read `CONTEXT.md` for current state
2. Read `mindfulness_app/docs/zen-forest-features.json` — pick highest-priority `passes: false` feature
3. Run `flutter analyze` — confirm baseline is clean
4. Read the relevant `lib/` files for the feature area
5. Implement → test → update `zen-forest-features.json`
6. Commit with a descriptive message: `feat: <feature-slug> – <short description>`

### Agent Skills Available
Navigate into `.agent/skills/<skill-name>/SKILL.md` to read each skill:
- `brand-identity` — design tokens, color palette, voice/tone
- `ui-ux-pro-max` — 50 styles, color palettes, font pairings
- `planning` — precision engineering plan creation
- `brainstorming` — Socratic feature refinement
- `task-board` — `TASKS.md` management
- `context-bridge` — `CONTEXT.md` handoff management
- `troubleshooting-applications` — systematic debugging
- `web-design-guidelines` — UI audit checklist

---

## Roadmap & Current Status

See `mindfulness_app/docs/zen-forest-features.json` for fine-grained feature status.

| Phase | Goal | Status |
|---|---|---|
| **Phase 1** | FIFO Presence Level queue in `ProgressService` | ✅ Done |
| **Phase 2** | 3D `tree_gn.glb` integration + `ZenTreeRenderer` scaling | ✅ Done |
| **Phase 3** | Legacy Forest Bento-grid (5-day free / 12-day premium) | ✅ Done |
| **Phase 4** | Glassmorphic Daily Insight tap overlay | 🔄 In Progress |
| **Phase 5** | Economy (coins, supabase sync) | 🔄 In Progress |
| **Next** | Polish: onboarding, settings, ambient soundscape | ⏳ Pending |

---

## Design System

Full details in `DESIGN.md`. Summary:

| Token | Value |
|---|---|
| Background | `#1A233A` → `#2D1B4E` (radial gradient) |
| Primary Accent | `#FF8A66` (Coral/Peach) |
| Text | `#F8F9FA` (Off-White) |
| Secondary Text | `#B0BEC4` (Muted Lavender) |
| Glass Surface | `rgba(255,255,255,0.05)` + `8px backdrop-filter blur` |
| Primary Font | **Manrope** (Light 200, Regular 400, Bold 700) |
| Radius | `16px–24px` (cards), `pill` (buttons) |

---

## Environment Variables & Secrets

> 🔒 **Never commit secrets.** The following are required but NOT in the repo:

- `SUPABASE_URL` — your project URL
- `SUPABASE_ANON_KEY` — public anon key (safe for client, but keep in config file)

Create `mindfulness_app/lib/supabase_config.dart` locally (already `.gitignore`'d via `.env` pattern — confirm this file is excluded).

---

*Built with 💚 by ChiCode Lab*
