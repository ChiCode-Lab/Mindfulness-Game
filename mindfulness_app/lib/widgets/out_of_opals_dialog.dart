import 'package:flutter/material.dart';
import 'package:mindfulness_app/services/economy_service.dart';
import 'package:mindfulness_app/services/ad_service.dart';

class OutOfOpalsDialog extends StatelessWidget {
  final EconomyService economyService;
  final VoidCallback onAdWatched;
  final VoidCallback onPremiumStarted;

  const OutOfOpalsDialog({
    super.key,
    required this.economyService,
    required this.onAdWatched,
    required this.onPremiumStarted,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A233A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Text(
        'Not Enough Opals',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      content: const Text(
        'You need more Opals to start this session. Choose an option below to continue your journey.',
        style: TextStyle(color: Color(0xFFB0BEC4), fontSize: 16),
      ),
      actionsPadding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 8),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await AdService().showRewardedAd(
                  // onRewarded: user completed watching — grant the Opals
                  onRewarded: onAdWatched,
                  // onFailed: no ad available — still grant Opals as graceful fallback
                  // to avoid blocking the user. Log this for analytics.
                  onFailed: () {
                    debugPrint('AdService: Rewarded ad unavailable — granting Opals as fallback');
                    onAdWatched();
                  },
                );
              },
              icon: const Icon(Icons.play_circle_outline, color: Colors.white),
              label: const Text('Watch Ad (+50 Opals)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50).withAlpha(200),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onPremiumStarted();
              },
              icon: const Icon(Icons.star, color: Color(0xFFFF8A66)),
              label: const Text('Start 5-Day Free Trial'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(20),
                foregroundColor: const Color(0xFFFF8A66),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF778DA9)),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
