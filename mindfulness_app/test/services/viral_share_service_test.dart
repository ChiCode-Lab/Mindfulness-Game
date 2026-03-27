import 'package:flutter_test/flutter_test.dart';
import 'package:mindaware/services/viral_share_service.dart';

void main() {
  test('ViralShareService constructs facebook friendly sharing text', () {
    final text = ViralShareService.generateShareText('Alice', 95);
    expect(text.contains('Alice is thinking of you'), true);
    expect(text.contains('Presence: 95'), true);
  });
}
