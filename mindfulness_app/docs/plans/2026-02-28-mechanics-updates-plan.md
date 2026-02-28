# Mechanics Updates Implementation Plan

**Goal:** Implement lower bound clamping, vector reversal, and max scale limits for game mutations to ensure Opals remain bounded, visible, and contained within their grid boxes.
**Architecture Fusion:** Refactors the mutation state and application logic in `main.dart` to track vector directions and enforce absolute boundaries per mutation cycle. 
**Scalability Strategy:** Constraints use relative unit boundaries instead of hardcoded screen coordinates, easily adapting across grid configurations.

---

### Task 1: Implement Boundary State tracking in `ShapeBaseAttributes`
**Engineering Paths:**
- Leverage: `c:\Users\user\Desktop\ChiCode\Apps\Minfulness App\mindfulness_app\lib\main.dart:lines` (ShapeBaseAttributes class)
- Test: `c:\Users\user\Desktop\ChiCode\Apps\Minfulness App\mindfulness_app\test\mechanics_bounds_test.dart`

**Step 1: Red Stage** (Write failing test)
```dart
// test/mechanics_bounds_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness_app/main.dart';
import 'dart:ui';

void main() {
  test('Opacity triggers isFadingIn when hitting lower bound of 0.3', () {
    // We will simulate the opacity dropping to 0.3 or below and verifying the direction flag flips.
  });

  test('Position mutation reverses vector when hitting +/- 40 bounds', () {
    // Simulate position offset reaching 40 on X axis, verify next mutation reverses direction.
  });
}
```

**Step 2: Verification**
Run `flutter test test/mechanics_bounds_test.dart` and confirm failure.

**Step 3: Green Stage** (Minimal implementation)
Update `ShapeBaseAttributes` in `lib/main.dart` to add tracked flags for physics/reversals:
```dart
class ShapeBaseAttributes {
  // Add:
  final bool isFadingIn;
  final Offset positionDirection;
  final double scaleDirection;
  // Constructor updates and copyWith updates
}
```

**Step 4: Validation**
Run `flutter test test/mechanics_bounds_test.dart` and confirm "Precision Success."

---

### Task 2: Implement Clamping and Reversal Logic in `_applyMutation`
**Engineering Paths:**
- Leverage: `c:\Users\user\Desktop\ChiCode\Apps\Minfulness App\mindfulness_app\lib\main.dart` (`_applyMutation` function)
- Test: `c:\Users\user\Desktop\ChiCode\Apps\Minfulness App\mindfulness_app\test\mechanics_bounds_test.dart`

**Step 1: Red Stage** (Expand failing test)
Update the test to apply consecutive mutations and assert the bounds:
- Opacity doesn't go below 0.3.
- Offset X and Y do not exceed ±40.0.
- Scale stays between 0.5 and (Grid Box Size constraint, roughly 1.2).

**Step 2: Verification**
Run `flutter test test/mechanics_bounds_test.dart` and confirm failure.

**Step 3: Green Stage** (Minimal implementation)
Refactor `_applyMutation` logic:
```dart
// Pseudo-code implementation structure
case MutationType.opacity:
  double newOp = base.isFadingIn ? base.opacityMultiplier + 0.3 : base.opacityMultiplier - 0.3;
  bool fadingIn = base.isFadingIn;
  if (newOp <= 0.3) {
    newOp = 0.3;
    fadingIn = true;
  } else if (newOp >= 1.0) {
    newOp = 1.0;
    fadingIn = false;
  }
  return base.copyWith(opacityMultiplier: newOp, isFadingIn: fadingIn);
```
Apply similar clamping logic for `position` with ±40.0 limits and `scale` with 1.2 max ceiling.

**Step 4: Validation**
Run `flutter test test/mechanics_bounds_test.dart` and confirm "Precision Success."

---

### Task 3: Render Subsystem Update
**Engineering Paths:**
- Leverage: `c:\Users\user\Desktop\ChiCode\Apps\Minfulness App\mindfulness_app\lib\main.dart` (`_ModelShapeRendererState.build`)

**Step 1: Visual Regression Prep**
Review current render logic. The renderer currently adds multipliers locally.

**Step 3: Green Stage**
Refactor `_ModelShapeRendererState` to interpolate purely from the updated bounds-constrained values passed from `ShapeBaseAttributes`.

**Step 4: Validation**
Run `flutter run -d chrome` and visually verify Opals stay inside grid boxes, bounce back, and don't disappear.

**Step 5: Commit**
`git add . && git commit -m "feat: Implement bounded mechanics (clamping, reversal, max scale)"`
