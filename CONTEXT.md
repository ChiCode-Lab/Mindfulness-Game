# Project Context
**Goal:** Build a gamified mindfulness application where users identify subtle visual changes in a grid of shapes (Solo and Multiplayer modes).
*(Note: To increase visual engagement, use 3D items for the grid shapes—e.g. 3D pebbles, leaves, or trees—rendered in Flutter.)*
**Tech Stack:** React Native / Flutter (Mobile-first)

## Current Status
- [x] Initial Context Bridge Setup
- [x] Gather brainstorming requirements
- [x] Create Stitch Design Prompt (`next-prompt.md`)
- [x] Generate UI designs in Stitch based on the prompt
- [x] Generate `DESIGN.md` from Stitch screen
- [x] Begin Front-End Implementaton
- [ ] Implement responsive Flutter app with `ui-ux-pro-max` guidelines
- [ ] Connect Android emulator and test out the front-end

## ⚡ CURRENT TASK FOR TERMINAL AGENT
**Instructions:**
1. A new Flutter project `mindfulness_app` was created. Configure the app to run on the Android Emulator.
2. The user has requested to incorporate **3D elements** (like pebbles, leaves, and trees) in the gameplay grid. **Crucially, these 3D assets must look like the reference image:** a glowing, highly complex translucent/glass material featuring internal color swirls (e.g. deep pink, vibrant orange, purple) and bright light refraction. The user does NOT have `.glb` models. Instead, implement a **programmatic approximation using Three.js**. You will likely need to use a package like `webview_flutter` or `flutter_inappwebview` to host the Three.js canvas, and write custom WebGL shaders to simulate the glowing glass refraction and internal swirling colors.
3. Consult the generated `DESIGN.md` and use the `ui-ux-pro-max` skills workspace to structure the Flutter UI.
4. Open the Android emulator and launch the app via `flutter run` / `launch_app`. Test the layout.

## Architecture Notes
- The interface relies heavily on a soft, ethereal vibe to promote mindfulness.
- Design elements are minimal, using frosted glass effects (glassmorphism) over a deep, calming background gradient.
- Core interactive area is a responsive 4x4 or 5x5 shape grid containing 3D models (pebbles/leaves/trees).
