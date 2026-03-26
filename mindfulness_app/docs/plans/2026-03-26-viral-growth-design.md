# Product-Led Viral Growth System Design

## 1. The Cooperative Invitation Loop (The Biggest Unlock)
**Objective**: Transform the unused Co-op mode into an acquisition engine by reducing friction.
**Architecture & Data Flow**:
- **Deep Linking**: The app will intercept links (e.g., `mindaware.app/invite/<room_id>?ref=<user_id>`) using native App Links/Universal Links.
- **Fast-Track Auth**: When a new user opens solving the link, they bypass standard onboarding (no long questionnaires) and are immediately presented with a 1-tap social login (Apple/Google/Facebook) bottom sheet. 
- **First-Time User Training (FTUE)**: After 1-tap auth, before plunging into the live Co-op game, the user enters a 30-60 second interactive tutorial bridging them into the gameplay. They learn the `ShapeCell` game mechanics ("Tap the pulsing glowing shape") without the pressure of the live match.
- **Cost Bypass**: The `MultiplayerService` will verify if this is the user's first game. If so, it overrides the typical Opal cost, letting them play an immediate 3-minute demo session entirely for free. 
- **The Invite UI**: Inside the app, when a user is alone in the `MultiplayerLobbyScreen`, they see a loud call-to-action: "Invite a friend to grow today's tree together. You'll both earn shared leaves and your tree will grow twice as fast." Tapping this opens the native share sheet with the deep link.

## 2. The Referral System: "Plant a Tree for Someone"
**Objective**: A meaningful, legacy-driven reward for referring friends.
**Architecture & Data Flow**:
- **Referrer Tracking**: The deep-link naturally carries the `ref=<user_id>` parameter. Upon sign-up during Fast-Track Auth, this ID is saved to the new user's Supabase profile under `referred_by`.
- **The Reward Trigger**: When the new user completes their *first standard solo mindfulness session* (recorded in `ProgressService`), a Supabase webhook / trigger fires:
  1. Deposits +100 Opals to the Inviter's account.
  2. Deposits +50 Opals to the Friend's account.
  3. Spawns a unique "Tree" record in the Inviter's Legacy Forest flagged with the metadata `gifted_by: Friend's Name`. The UI will label it "*[Friend's Name]'s first tree*".

## 3. Gifting Feelings (Post-Session Viral Component)
**Objective**: Capitalize on the user's dopamine and calm post-session state to drive social sharing onto Facebook and other platforms.
**Architecture & Data Flow**:
- **Condition**: Triggers at the end of a session if `presence_score > threshold` or `streak > threshold`. 
- **Prompt**: A beautiful modal states: *"You're in a really calm state right now. Send that to someone who might need it."* 
- **The Mechanism**: Tapping "Share" generates an aesthetic screenshot (using a hidden `RepaintBoundary` widget containing the user's glowing session stats or tree) and passes it to the native OS share sheet via the `share_plus` package, alongside the pre-filled text: *"[Name] is thinking of you. They just finished a mindfulness session and wanted to share some calm."* 
- **Facebook Integration**: Using the platform's native share mechanisms allows seamless Facebook sharing, which deep-links back into the app for potential new users or sends a push notification if the friend is already connected in the app.

## 4. The Legacy Forest as a Public Profile
**Objective**: Create a living, web-accessible "mindfulness portfolio" that generates passive, organic social traffic via bio links.
**Architecture & Data Flow**:
- **Optional Public Toggle**: Within the Legacy Forest screen, users will find a toggle to make their forest "Public". This sets a boolean `is_public` flag on their Supabase user profile.
- **The Unique URL**: Each user claims a unique username/slug (e.g. `MindAware.app/forest/username`). Users can generate an in-app QR code or copy this link.
- **The Web Viewer (Next.js/Flutter Web)**: When a friend clicks the link in an Instagram bio, Whatsapp, or Facebook post, they are taken to a read-only, browser-based 3D view of the user's 12-day forest. They can see the user's total leaf count and recent presence scores without authenticating.
- **The Call To Action**: Displayed prominently underneath the 3D web scene: *"Plant your first tree →"*. Tapping this behaves exactly as the Deep Links in Section 1, deferring directly to the App Store or bypassing onboarding if they already have the app.

## Technical Integrity & Security
- **Anti-Fraud**: The Supabase triggers ensure that users cannot farm Opals by creating multiple accounts; a solo session MUST be completed authentically to trigger the "Plant a Tree" reward.
- **Seamless Integrations**: Expanding the `MultiplayerService` guarantees it gracefully handles the "tutorial state" of the remote second player before finalizing the connection.
- **Data Privacy**: The public forest URL fetches strictly read-only, non-PII data (tree shapes, colors, presence scores) governed by Row Level Security in Supabase ensuring `is_public == true`.
