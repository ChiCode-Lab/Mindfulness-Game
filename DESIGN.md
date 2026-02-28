# Design System: Mindfulness App
**Project ID:** 8679560881075306253

## 1. Visual Theme & Atmosphere
The atmosphere is profoundly "Ethereal, Calming, and Minimal." The application acts as a digital sanctuary, encouraging mindfulness and presence. It relies heavily on soft, diffused lighting (glassmorphism), slow twilight gradients, and organic contrast. The density is extremely low, favoring generous whitespace and clean typography to avoid cognitive overload. The interface embraces a twilight-inspired calm, where the primary mechanic—identifying subtle visual changes—is supported by high contrast yet gentle glowing highlights.

## 2. Color Palette & Roles
- **Deep Twilight Blue (#1A233A):** The foundational dark background color. It serves as the base of the radial twilight gradient, creating depth and a sense of calm nightfall.
- **Deep Lavender Ambient (#2D1B4E):** The upper core of the radial gradient, blending into the twilight blue to create a glowing sky effect.
- **Soft Coral / Glowing Peach (#FF8A66):** The primary accent and interactive color. Used for the prominent gameplay target highlights, action buttons (like "Hint" or "Next Level"), streaks, and progress indicators.
- **Off-White (#F8F9FA):** The primary text color. High luminosity for clear readability against the dark backgrounds, without the harshness of pure white.
- **Muted Lavender / Slate (#B0BEC4 / #475569):** Used for secondary text, labels, hints, and inactive UI states.
- **Soft Midnight / Dark Glass (#222E4A / rgba(255,255,255,0.05)):** The surface color for glassmorphic elements, modal cards (like the "Level Complete" or "Daily Zen Quote" modals), and shape grid backgrounds.

## 3. Typography Rules
- **Primary Font Family:** "Manrope" (a modern, clean geometric sans-serif).
- **Weights:** Uses Light (200) or Regular (400) for calming body text and descriptions. Semi-Bold (500) or Bold (700) are reserved for key metrics (Streaks, Focus Session percentages) and primary CTA buttons.
- **Letter Spacing:** Liberal use of tracking (`tracking-wider` to `tracking-widest`) on small uppercase labels (e.g., "FOCUS SESSION", "SOLO") to create a breathable, airy feel.

## 4. Component Stylings
- **Buttons / Controls:** Completely pill-shaped (generously rounded corners). Active buttons rely on the solid Soft Coral background with dark text. Inactive or secondary toggles (e.g., Solo vs. Multiplayer) sit within a dark glass pill (`bg-slate-900/40`) and highlight with a soft primary glow (`bg-primary/20`) when active.
- **Cards / Containers (Modals):** Gently rounded corners (16px to 24px). Modals (like the Level Complete stats, Daily Zen Quotes, or Ambient Sound settings) utilize a soft glassmorphic surface over the blurred background, accompanied by very soft, diffused shadows.
- **Game Grid Elements:** The 4x4 or 5x5 shapes are constructed using the `.glass-shape` pattern: `rgba(255, 255, 255, 0.05)` background, an `8px` backdrop blur, and a delicate `1px` semi-transparent white border. The target shape employs a subtle Soft Coral border and a soft `15px` outer glow.
- **Ambient Decorations:** Large, extremely blurred (`blur-100px`) accent circles (Soft Coral or Purple) are placed behind the UI elements to cast a soft light onto the screen frame. 

## 5. Layout Principles
- **Grid Alignment:** The core interactive visual field is perfectly centered and locked into a responsive 1:1 aspect ratio grid (e.g., a perfect square for the 4x4 shapes). 
- **Whitespace Strategy:** High padding and margins separate the header, game area, and floating footer. Elements gracefully float above the background rather than filling the screen.
- **Modularity:** Popups and features brainstormed previously (e.g., Daily Zen Quote modal, Ambient Sound toggles, Multiplayer leaderboards) must float as soft-shadowed cards in the center of the screen, overlaying a heavily blurred version of the Twilight UI.
