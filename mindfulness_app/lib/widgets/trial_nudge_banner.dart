import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/economy_service.dart';
import '../screens/paywall_screen.dart';

class TrialNudgeBanner extends StatelessWidget {
  final EconomyService economyService;

  const TrialNudgeBanner({super.key, required this.economyService});

  @override
  Widget build(BuildContext context) {
    final state = economyService.state;

    // Only show when user is on trial AND has 2 or fewer days remaining.
    // Day 3 of 5 = 2 days remaining. Also shows on days 4 and 5.
    if (!state.isOnTrial || state.trialDaysRemaining > 2) {
      return const SizedBox.shrink();
    }

    final daysLeft = state.trialDaysRemaining;
    final label = daysLeft == 1
        ? 'Your Zen sanctuary expires tomorrow — lock it in ✨'
        : 'Your Zen sanctuary expires in $daysLeft days — lock it in ✨';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaywallScreen(
              economyService: economyService,
              isMandatory: false,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A66).withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF8A66).withOpacity(0.35),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8A66).withOpacity(0.08),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Color(0xFFFF8A66),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFFF8F9FA),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFFF8A66),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
