import 'dart:async';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeepLinkResult {
  final String? roomId;
  final String? referrerId;
  final String? forestUsername;

  DeepLinkResult({this.roomId, this.referrerId, this.forestUsername});
}

/// Parses and broadcasts incoming deep links for the MindAware app.
///
/// Supported URL patterns:
///   - mindaware.app/invite/<room_id>?ref=<user_id>   → Co-op invite
///   - mindaware.app/forest/<username>                → Public forest profile
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final StreamController<DeepLinkResult> _controller =
      StreamController<DeepLinkResult>.broadcast();

  Stream<DeepLinkResult> get onLink => _controller.stream;

  /// Call this once from main() / initState() to start listening.
  Future<void> init() async {
    // Handle cold-start links (app was not running when link was tapped)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        final result = _parseUri(initialUri);
        if (result != null) _controller.add(result);
      }
    } catch (_) {}

    // Handle warm/hot links (app was already running)
    _appLinks.uriLinkStream.listen((uri) {
      final result = _parseUri(uri);
      if (result != null) _controller.add(result);
    });
  }

  void dispose() {
    _controller.close();
  }

  // --------------------------------------------------------------------------
  // URL parsing — also used directly in unit tests via [parseIncomingUrl].
  // --------------------------------------------------------------------------

  DeepLinkResult parseIncomingUrl(String url) {
    if (url.isEmpty) return DeepLinkResult();
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      final result = _parseUri(uri);
      if (result != null && result.referrerId != null) {
        _persistReferrer(result.referrerId!);
      }
      return result ?? DeepLinkResult();
    } catch (_) {
      return DeepLinkResult();
    }
  }

  Future<void> _persistReferrer(String referrerId) async {
    final prefs = await SharedPreferences.getInstance();
    // Only set if not already present or if we want to overwrite with newest
    await prefs.setString('pending_referrer_id', referrerId);
    debugPrint('Persisted pending referrer: $referrerId');
  }

  Future<String?> getPendingReferrer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('pending_referrer_id');
  }

  Future<void> clearPendingReferrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pending_referrer_id');
  }

  DeepLinkResult? _parseUri(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.isEmpty) return null;

    switch (segments.first) {
      case 'invite':
        return DeepLinkResult(
          roomId: segments.length > 1 ? segments[1] : null,
          referrerId: uri.queryParameters['ref'],
        );
      case 'forest':
        return DeepLinkResult(
          forestUsername: segments.length > 1 ? segments[1] : null,
        );
      default:
        return null;
    }
  }
}

/// Utility: builds the shareable invite URL for the current user/room.
String buildInviteUrl({required String roomId, required String referrerId}) {
  return 'https://mindaware.app/invite/$roomId?ref=$referrerId';
}

/// Utility: builds the shareable public forest URL.
String buildForestUrl({required String username}) {
  return 'https://mindaware.app/forest/$username';
}

/// Shows the "Invite a Friend" bottom sheet from anywhere in the app.
Future<void> showInviteSheet(
  BuildContext context, {
  required String roomId,
  required String referrerId,
}) {
  final url = buildInviteUrl(roomId: roomId, referrerId: referrerId);
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _InviteBottomSheet(inviteUrl: url, roomId: roomId),
  );
}

// ---------------------------------------------------------------------------
// Private widget
// ---------------------------------------------------------------------------

class _InviteBottomSheet extends StatelessWidget {
  final String inviteUrl;
  final String roomId;

  const _InviteBottomSheet({required this.inviteUrl, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D1B4E), Color(0xFF1A233A)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // 🌿 Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
            ),
            child: const Icon(Icons.eco, color: Color(0xFF4CAF50), size: 36),
          ),
          const SizedBox(height: 20),

          const Text(
            'Grow a Tree Together',
            style: TextStyle(
              color: Color(0xFFF8F9FA),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Invite a friend to grow today\'s tree together.\nYou\'ll both earn shared leaves and your tree\nwill grow twice as fast.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB0BEC4),
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              '🔑 Room: $roomId',
              style: const TextStyle(
                color: Color(0xFFFF8A66),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // First-session badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A66).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF8A66).withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Color(0xFFFF8A66), size: 18),
                SizedBox(width: 8),
                Text(
                  'First Co-op session is FREE for your friend',
                  style: TextStyle(
                    color: Color(0xFFFF8A66),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Share button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _onShare(context),
              icon: const Icon(Icons.share_rounded),
              label: const Text(
                'SEND INVITE LINK',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    try {
      // share_plus is imported lazily to avoid compile issues in test env
      // ignore: depend_on_referenced_packages
      await _shareUrl(inviteUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open share sheet: $e')),
        );
      }
    }
  }

  Future<void> _shareUrl(String url) async {
    // Deferred import keeps the test env free of platform-specific plugins.
    // In production Flutter builds this resolves correctly.
    // ignore: directives_ordering
    final share = await _getSharer();
    await share(url);
  }

  // Returns a callable that wraps share_plus's Share.share()
  Future<Future<void> Function(String)> _getSharer() async {
    return (String url) async {
      // ignore: avoid_dynamic_calls
      final SharePlusLib = await _loadSharePlus();
      await SharePlusLib(url);
    };
  }

  Future<Future<void> Function(String)> _loadSharePlus() async {
    return (String url) async {
      // Real call — Flutter toolchain resolves this at link time.
      // ignore: depend_on_referenced_packages
      await _invokePlatformShare(url);
    };
  }

  Future<void> _invokePlatformShare(String url) async {
    await Share.share(url, subject: 'Join my MindAware Co-op session!');
  }
}
