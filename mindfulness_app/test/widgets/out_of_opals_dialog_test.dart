import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindfulness_app/services/economy_service.dart';
import 'package:mindfulness_app/widgets/out_of_opals_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Need a dummy initialization to bypass the assertion
    await Supabase.initialize(
      url: 'https://dummy.supabase.co',
      anonKey: 'dummy_key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Dialog renders correctly and triggers callbacks', (WidgetTester tester) async {
    final EconomyService mockService = EconomyService();
    await mockService.init();

    bool adWatched = false;
    bool premiumStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => OutOfOpalsDialog(
                    economyService: mockService,
                    onAdWatched: () => adWatched = true,
                    onPremiumStarted: () => premiumStarted = true,
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Not Enough Opals'), findsOneWidget);
    expect(find.text('Watch Ad (+50 Opals)'), findsOneWidget);
    expect(find.text('Start 5-Day Free Trial'), findsOneWidget);

    // Tap Ad button
    await tester.tap(find.text('Watch Ad (+50 Opals)'));
    await tester.pumpAndSettle();
    
    expect(adWatched, true);
    expect(premiumStarted, false);
    
    // Open Dialog again to test Premium button
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();
    
    // Tap premium button
    await tester.tap(find.text('Start 5-Day Free Trial'));
    await tester.pumpAndSettle();

    expect(premiumStarted, true);
  });
}
