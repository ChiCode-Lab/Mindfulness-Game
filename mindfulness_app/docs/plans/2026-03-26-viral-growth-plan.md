# Viral Growth System Implementation Plan

**Goal:** Transform the MindAware app into a product-led viral ecosystem by integrating a frictionless co-op loop, an aesthetic referral structure, one-tap social sharing, and shareable 3D web legacy forests.
**Architecture Fusion:** Bypassing onboarding via `app_links` and deep-linking directly into a 1-tap fast track auth module (`supabase_flutter`). Refactoring `MultiplayerService` to support FTUE status, adding Edge Function webhooks for referrals, utilizing `share_plus` for OS-level viral screenshots, and setting up an isolated web-reader route or separate Next.js web portal for the public portfolio.
**Scalability Strategy:** Rely heavily on Supabase RLS (Row Level Security) and Edge Functions to handle referral reward distribution cleanly, preventing client-side abuse. Using a hidden `RepaintBoundary` for the Screenshot ensures the core rendering pipeline is unimpeded. The Public Forest dashboard must fetch strictly read-only, non-authed records.

---

### Task 1: Zero-Friction Invites & App Links Interceptor
**Engineering Paths:**
- Create: `lib/services/deep_link_service.dart`
- Leverage: `lib/main.dart`, `lib/screens/multiplayer_lobby_screen.dart`
- Test: `test/services/deep_link_service_test.dart`

**Step 1: Red Stage**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/services/deep_link_service.dart';

void main() {
  test('Parses invite room id and referral id from mindaware.app/invite url', () {
    final service = DeepLinkService();
    final result = service.parseIncomingUrl('mindaware.app/invite/abc-123?ref=usr_999');
    
    expect(result.roomId, 'abc-123');
    expect(result.referrerId, 'usr_999');
  });
}
```

**Step 2: Verification**
Run `flutter test test/services/deep_link_service_test.dart` and confirm failure.

**Step 3: Green Stage**
```dart
class DeepLinkResult {
  final String? roomId;
  final String? referrerId;
  DeepLinkResult({this.roomId, this.referrerId});
}

class DeepLinkService {
  DeepLinkResult parseIncomingUrl(String url) {
    var uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'invite') {
      return DeepLinkResult(
          roomId: uri.pathSegments.length > 1 ? uri.pathSegments[1] : null,
          referrerId: uri.queryParameters['ref'],
      );
    }
    return DeepLinkResult();
  }
}
```

**Step 4: Validation**
Run `flutter test test/services/deep_link_service_test.dart` and confirm "Precision Success."

**Step 5: Commit**
`git add ... && git commit -m "feat: setup deep link parser for co-op invites and referral params"`

---

### Task 2: Supabase Referral Reward Webhook (DB Trigger)
**Engineering Paths:**
- Create: `supabase/migrations/2026_03_26_viral_rewards.sql`
- Leverage: `supabase/functions/handle_referral/index.ts` (if Edge Function) or Postgres Triggers.

**Step 1: Red Stage**
```sql
-- Attempt to create a user and spoof a completed progress session, expect an error indicating missing referring components or failing test cases (using pgTap in normal Supabase testing).
```

**Step 2: Verification**
Run `supabase db test` to confirm lack of trigger function.

**Step 3: Green Stage**
```sql
-- Create trigger on progress table insertion
CREATE OR REPLACE FUNCTION public.handle_referral_rewards()
RETURNS TRIGGER AS $$
DECLARE
  inviter_id UUID;
BEGIN
  -- Check if this is their first session
  IF (SELECT COUNT(*) FROM progress WHERE user_id = NEW.user_id) = 1 THEN
    -- Find if they were referred
    SELECT referred_by INTO inviter_id FROM users WHERE id = NEW.user_id;

    IF inviter_id IS NOT NULL THEN
      -- Deposit 100 to Inviter
      UPDATE users SET opals = opals + 100 WHERE id = inviter_id;
      -- Deposit 50 to Friend
      UPDATE users SET opals = opals + 50 WHERE id = NEW.user_id;
      -- Spawn special tree for inviter
      INSERT INTO legacy_trees (user_id, status, gifted_by) VALUES (inviter_id, 'planted', NEW.user_id);
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_first_session_complete
AFTER INSERT ON progress
FOR EACH ROW EXECUTE FUNCTION handle_referral_rewards();
```

**Step 4: Validation**
Run Database Tests and verify trigger logic deposits precisely 150 opals globally.

**Step 5: Commit**
`git add supabase/ && git commit -m "feat: postgres trigger handling plant-a-tree referral loop"`

---

### Task 3: Gifting Feelings (Native Screenshot Sharing)
**Engineering Paths:**
- Leverage: `lib/screens/dashboard_screen.dart` (inject the RepaintBoundary)
- Create: `lib/services/viral_share_service.dart`

**Step 1: Red Stage**
```dart
void main() {
  test('ViralShareService constructs facebook friendly sharing text', () {
    final text = ViralShareService.generateShareText('Alice', 95);
    expect(text.contains('Alice is thinking of you'), true);
    expect(text.contains('presence score of 95'), true);
  });
}
```

**Step 2: Verification**
Run `flutter test test/services/viral_share_service_test.dart` and confirm failure.

**Step 3: Green Stage**
```dart
class ViralShareService {
  static String generateShareText(String name, int presenceScore) {
    if (presenceScore > 90) {
      return "$name is thinking of you. They just finished a mindfulness session (Presence: $presenceScore) and wanted to share some calm. Start your journey: MindAware.app/invite/$name";
    }
    return "$name ended a deep meditation and thought of you. Tap here: MindAware.app";
  }
}
```

**Step 4: Validation**
Confirm test passes.

**Step 5: Commit**
`git add ... && git commit -m "feat: implement viral feeling sharing copy and native hooks logic"`

---

### Task 4: Public Legacy Forest Profile
**Engineering Paths:**
- Leverage: `lib/screens/legacy_forest_screen.dart`
- Create: `lib/screens/public_forest_web_screen.dart` (for Flutter Web usage)

**Step 1: Red Stage**
```dart
void main() {
  testWidgets('Displays Public Toggle Switch', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LegacyForestScreen()));
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Make Forest Public'), findsOneWidget);
  });
}
```

**Step 2: Verification**
Run Widget Test and confirm lack of Switch component.

**Step 3: Green Stage**
```dart
// Within LegacyForestScreen build structure:
SwitchListTile(
  title: const Text('Make Forest Public', style: TextStyle(color: Colors.white)),
  subtitle: const Text('MindAware.app/forest/username'),
  value: _isPublic, // Handled by Profile service
  onChanged: (val) {
     setState(() => _isPublic = val);
     _supabase.from('users').update({'is_public': val}).eq('id', myId);
  },
  activeColor: const Color(0xFFFF8A66),
)
```

**Step 4: Validation**
Run test and confirm "Precision Success".

**Step 5: Commit**
`git add lib/screens/legacy_forest_screen.dart && git commit -m "feat: add public forest toggle switch"`
