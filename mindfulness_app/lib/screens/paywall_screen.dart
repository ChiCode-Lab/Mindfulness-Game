import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/economy_service.dart';
import '../services/subscription_service.dart';
import '../models/economy_state.dart';

class PaywallScreen extends StatefulWidget {
  final EconomyService economyService;

  // If true, shown on first open after trial expiry — user MUST choose.
  // If false, navigated to from a banner/locked cell — can be popped.
  final bool isMandatory;

  const PaywallScreen({
    super.key,
    required this.economyService,
    this.isMandatory = false,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

enum _SelectedPlan { monthly, annual }

class _PaywallScreenState extends State<PaywallScreen> {
  _SelectedPlan _selectedPlan = _SelectedPlan.annual; // Annual pre-selected
  bool _isPurchasing = false;
  bool _isRestoring = false;
  String? _errorMessage;

  Future<void> _onSubscribe() async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    final success = _selectedPlan == _SelectedPlan.annual
        ? await SubscriptionService().purchaseAnnual()
        : await SubscriptionService().purchaseMonthly();

    if (!mounted) return;

    if (success) {
      // Sync the new entitlement into EconomyService so isPremium
      // returns true immediately throughout the app without a restart.
      await widget.economyService.syncSubscriptionStatus();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _isPurchasing = false;
        _errorMessage = 'Purchase could not be completed. Please try again.';
      });
    }
  }

  Future<void> _onRestore() async {
    setState(() {
      _isRestoring = true;
      _errorMessage = null;
    });

    final success = await SubscriptionService().restorePurchases();
    if (!mounted) return;

    if (success) {
      await widget.economyService.syncSubscriptionStatus();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _isRestoring = false;
        _errorMessage = 'No active subscription found to restore.';
      });
    }
  }

  void _onContinueFree() {
    // Explicit free choice — pop back to Dashboard with no changes.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Prevent Android back gesture on mandatory paywall — user must
      // explicitly tap "Continue Free" to acknowledge their choice.
      canPop: !widget.isMandatory,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(),
            _buildContent(),
          ],
        ),
      ),
    );
  }

  // Blurred gradient background — evokes the Legacy Forest the user
  // has grown, making the loss of premium access feel tangible.
  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            Color(0xFF2D1B4E),
            Color(0xFF1A233A),
          ],
          stops: [0.1, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Ambient forest glow blobs — mirrors DashboardScreen aesthetic
          Positioned(
            top: -60,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4CAF50).withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF8A66).withOpacity(0.07),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final state = widget.economyService.state;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildHeader(state),
            const SizedBox(height: 40),
            _buildForestStatChip(state),
            const SizedBox(height: 40),
            _buildPlanCard(
              plan: _SelectedPlan.monthly,
              title: 'MONTHLY',
              price: '\$9.99',
              sub: 'per month',
              badge: null,
            ),
            const SizedBox(height: 14),
            _buildPlanCard(
              plan: _SelectedPlan.annual,
              title: 'ANNUAL',
              price: '\$59.99',
              sub: '~\$5.00 / month · Save 50%',
              badge: 'BEST VALUE',
            ),
            const SizedBox(height: 36),
            _buildSubscribeButton(),
            const SizedBox(height: 16),
            _buildRestoreButton(),
            const SizedBox(height: 16),
            _buildContinueFreeButton(),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFEF5350),
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _buildLegalLinks(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(EconomyState state) {
    final isExpired = !state.isOnTrial && !state.isPaidSubscriber;

    return Column(
      children: [
        // Park icon with coral glow
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFF8A66).withOpacity(0.12),
            border: Border.all(
              color: const Color(0xFFFF8A66).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.park_rounded,
            color: Color(0xFFFF8A66),
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          isExpired ? 'Your Sanctuary Awaits' : 'Unlock Your Full Sanctuary',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFF8F9FA),
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isExpired
              ? 'Your trial has ended. Keep your forest\ngrowing with Premium.'
              : 'Remove all limits. Grow your forest\nwithout boundaries.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFB0BEC4),
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  // Personal stat hook — shows the user's own tree count so the
  // loss of Legacy Forest access feels concrete, not abstract.
  Widget _buildForestStatChip(EconomyState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.eco_rounded, color: Color(0xFF66BB6A), size: 20),
              const SizedBox(width: 10),
              const Text(
                'You\'ve grown trees in your forest.',
                style: TextStyle(
                  color: Color(0xFFB0BEC4),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required _SelectedPlan plan,
    required String title,
    required String price,
    required String sub,
    required String? badge,
  }) {
    final isSelected = _selectedPlan == plan;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF8A66).withOpacity(0.12)
              : const Color(0xFF222E4A).withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF8A66)
                : Colors.white.withOpacity(0.10),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFFFF8A66)
                    : Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF8A66)
                      : Colors.white.withOpacity(0.25),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 13)
                  : null,
            ),
            const SizedBox(width: 16),
            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFFFF8A66)
                              : const Color(0xFFB0BEC4),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A66),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Color(0xFF1A233A),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              price,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFF8F9FA)
                    : const Color(0xFFB0BEC4),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return ElevatedButton(
      onPressed: _isPurchasing ? null : _onSubscribe,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8A66),
        foregroundColor: const Color(0xFF1A233A),
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 10,
        shadowColor: const Color(0xFFFF8A66).withOpacity(0.4),
      ),
      child: _isPurchasing
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF1A233A),
                strokeWidth: 2.5,
              ),
            )
          : Text(
              _selectedPlan == _SelectedPlan.annual
                  ? 'START ANNUAL — \$59.99 / YEAR'
                  : 'START MONTHLY — \$9.99 / MO',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                fontSize: 15,
              ),
            ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _isRestoring ? null : _onRestore,
      child: _isRestoring
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Color(0xFFB0BEC4),
                strokeWidth: 2,
              ),
            )
          : const Text(
              'Restore Purchases',
              style: TextStyle(
                color: Color(0xFFB0BEC4),
                fontSize: 13,
              ),
            ),
    );
  }

  Widget _buildContinueFreeButton() {
    return OutlinedButton(
      onPressed: _onContinueFree,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFB0BEC4),
        minimumSize: const Size(double.infinity, 52),
        side: BorderSide(color: Colors.white.withOpacity(0.15)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Continue Free →',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLegalLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {/* navigate to Privacy Policy WebView */},
          child: const Text(
            'Privacy Policy',
            style: TextStyle(color: Color(0xFF778DA9), fontSize: 11),
          ),
        ),
        const Text(
          '·',
          style: TextStyle(color: Color(0xFF778DA9), fontSize: 11),
        ),
        TextButton(
          onPressed: () {/* navigate to Terms of Use WebView */},
          child: const Text(
            'Terms of Use',
            style: TextStyle(color: Color(0xFF778DA9), fontSize: 11),
          ),
        ),
      ],
    );
  }
}
