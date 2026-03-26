# mindaware — Flutter Project

This is the Flutter application sub-project for ZenForest. For full project context, see the [root README](../README.md).

## Setup

```bash
flutter pub get
flutter run -d <device_id>
```

## Project Structure

```
lib/
├── main.dart                     # App entry, theme, router
├── models/                       # Pure data models (no Flutter deps)
│   ├── zen_tree.dart             # ZenTreeData — daily tree state
│   ├── game_metrics.dart         # PresenceLevel, DeepFocus
│   ├── game_settings.dart        # GridSize, difficulty
│   └── economy_state.dart        # Coin/leaf economy
├── services/                     # Business logic
│   ├── progress_service.dart     # FIFO presence queue, session tracking
│   ├── economy_service.dart      # Leaf/coin economy + Supabase sync
│   ├── multiplayer_service.dart  # Supabase Realtime co-op
│   ├── notification_service.dart # Daily reminder scheduling
│   ├── background_task_service.dart # Workmanager jobs
│   └── soundscape_engine.dart    # Ambient audio
├── screens/                      # Page-level widgets
│   ├── onboarding_screen.dart
│   ├── dashboard_screen.dart     # Home with game entry
│   ├── forest_screen.dart        # Legacy Forest 3D grid
│   ├── coop_game_screen.dart     # Co-op multiplayer gameplay
│   ├── multiplayer_lobby_screen.dart
│   └── settings_screen.dart
└── widgets/                      # Reusable components

assets/
├── 3D/                           # .glb models (tree_gn, opal, maple_tree)
├── audio/                        # Ambient soundscape tracks
└── web/                          # Three.js shader assets (WebView)
```

## Running Tests

```bash
flutter analyze
flutter test
```

Feature tracking: `docs/zen-forest-features.json`
