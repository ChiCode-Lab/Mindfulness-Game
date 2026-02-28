# PRD: Zen Forest & Daily Tree Evolution

## App Overview & Objectives
The "Zen Forest" feature is designed to gamify mindfulness through organic growth. It visualizes a user's daily progress as a single 3D Tree that grows in size throughout the day and takes its place in a "Legacy Forest" (a historical record of the past 12 days).

**Key Goals:**
- Provide immediate visual gratification for meditation sessions.
- Implement more rigorous mindfulness metrics (Presence & Deep Focus).
- Establish a clear retention loop through daily "Forest" building.

## Target Audience
- **General Users:** Seeking a calm, peaceful way to track habits.
- **Premium Users:** Power users who want long-term visualization (12 days vs. 5 days) and deeper data insights.

---

## Core Features & Functionality

### 1. The Daily Tree (3D Evolution)
- **Asset:** `tree_gn.glb` (3D Model).
- **Growth Logic:**
  - Starts as a small sapling every midnight.
  - **Scaling:** Scales up continuously based on `leafCount` gattered in Solo and Cooperative sessions.
  - **Animation:** When entering the "Forest" or completing a session, a "Leaf Infusion" animation occurs where new leaves visibly scale the tree up from its previous state.
- **Interactivity:**
  - **Spin/Orbit:** Users can rotate the 3D model.
  - **Tapping:** Tapping the tree opens a "Daily Insight" glassmorphic overlay.

### 2. The Legacy Forest (FIFO Queue)
- **Layout:** A grid-like layout (Bento Grid style) representing the historical record.
- **FIFO Management:** 
  - As a new day's tree is finished, the oldest tree in the forest is removed (13th day out).
  - **Tiered Access:** 
    - **Free:** View past 5 days.
    - **Premium:** View past 12 days.
- **Visuals:** Each grid cell features a "miniature" version of that day's tree with its total leaf count displayed.

### 3. Advanced Mindfulness Metrics (Calculation Update)
- **Presence Level:**
  - **Initial State:** 100.
  - **Logic:** Points system reflected in a **FIFO Queue of size [N]** (e.g., last 50 interactions).
  - **Input:** Successful detection = +1; Miss = -1.
  - **Output:** Sum of points normalized to a 0-100 scale.
- **Deep Focus:**
  - **Calculation:** Moving average of **Reaction Time** during detection events.
  - **Visualization:** Shown as a secondary metric on the Tree Detail overlay.

---

## Technical Stack Recommendations
- **Frontend:** Flutter
- **3D Rendering:** `flutter_3d_controller` (Rendering `tree_gn.glb`)
- **Animation:** `Implicit Animations` (AnimatedScale, AnimatedPositioned) for growth transitions.
- **Data Persistence:** `SharedPreferences` (Local stats) & `Supabase` (Global sync & Level-ups).
- **UI System:** Glassmorphism (Frosted glass effects, `BackdropFilter`, 15-20px blur).

---

## Conceptual Data Model
### `ZenTreeData` (Updated)
| Field | Type | Description |
| :--- | :--- | :--- |
| `date` | DateTime | The specific day for the tree. |
| `leafCount` | int | Total leaves accumulated today. |
| `soloLeaves` | int | Leaves from solo sessions. |
| `coopLeaves` | int | Leaves from cooperative sessions. |
| `presenceHistory` | List<int> | FIFO Queue storage for presence calculation. |
| `avgReactionTime` | double | Average reaction time for Deep Focus. |

---

## UI Design Principles (UI-UX Pro Max)
- **Style:** **Glassmorphism**. High use of `rgba(255, 255, 255, 0.15)` with backdrop blurs.
- **Typography:** **Quicksand** (Soft/Rounded) for numbers; **Inter** for descriptions.
- **Color Palette:** Zen Greens (`#2D5A27`), Morning Frost (`#E0F2F1`), and Dark Base (`#121212`).
- **Interactivity Checklist:**
  - [ ] Use `cursor-pointer` (for web/desktop builds).
  - [ ] Hover states on forest grid items to reveal leaf counts.
  - [ ] Respect `prefers-reduced-motion` for leaf scaling animations.

---

## Development Phases

### Phase 1: Mechanics Overhaul
- Update `ProgressService` to implement the FIFO Presence Level logic.
- Implement the Point System (+1/-1) during active meditation.

### Phase 2: 3D Tree Evolution
- Integrate `tree_gn.glb`.
- Create the scaling logic in `ZenTreeRenderer`.
- Implement the "Growth Animation" controller.

### Phase 3: The Forest UI
- Build the Grid/Bento layout for the forest.
- Add the subscription-check for 5-day vs. 12-day visibility.
- Implement the "Daily Insight" glassmorphic tap-reveals.

---

## Potential Challenges & Solutions
- **Performance:** 12 active 3D models in a grid can be heavy.
  - *Solution:* Use static 2D snapshots for the "Forest Grid" and only render the real 3D model for the "Today" tree or when a specific day is tapped.
- **Data Integrity:** Ensuring the FIFO queue doesn't bloat.
  - *Solution:* Hard-limit the history list to the most recent 100 interaction points.

---

## Future Expansion Possibilities
- **Seasonal Trees:** Different `.glb` models for different seasons or weather.
- **Shared Forests:** A cooperative "Grove" where groups of friends grow one massive forest together.
- **Soundscape Linking:** Tree size affecting the richness of the ambient soundscape.
