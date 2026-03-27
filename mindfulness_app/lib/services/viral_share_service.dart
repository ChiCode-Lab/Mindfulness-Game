import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ViralShareService {
  static final GlobalKey boundaryKey = GlobalKey();

  /// Captures a widget wrapped in a RepaintBoundary and shares it.
  static Future<void> shareSession({
    required int leafCount,
    required String mode,
    String? username,
  }) async {
    try {
      RenderRepaintBoundary? boundary = 
          boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) return;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/mindaware_session.png').create();
      await file.writeAsBytes(pngBytes);

      final String shareText = username != null 
          ? "I just grew $leafCount leaves in MindAware with my friend! Join me: mindaware.app/forest/$username"
          : "Just finished a $mode session on MindAware. Feel the presence: mindaware.app";

      await Share.shareXFiles(
        [XFile(file.path)],
        text: shareText,
        subject: 'My Mindfulness Journey',
      );
    } catch (e) {
      debugPrint('Error sharing session: $e');
    }
  }

  /// Generates viral share text based on performance/presence score.
  static String generateShareText(String name, int presenceScore) {
    if (presenceScore > 90) {
      return "$name is thinking of you. They just finished a mindfulness session (Presence: $presenceScore) and wanted to share some calm. Start your journey: MindAware.app/invite/$name";
    }
    return "$name ended a deep meditation and thought of you. Tap here: MindAware.app";
  }

  /// Builds the aesthetic shareable card (to be used inside a hidden RepaintBoundary or Dialog)
  static Widget buildShareCard({
    required int leafCount,
    required String mode,
    required String date,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B4E), Color(0xFF0D1B2A)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFFF8A66), size: 40),
          const SizedBox(height: 16),
          const Text(
            'MINDAWARE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$leafCount',
            style: const TextStyle(
              color: Color(0xFFFF8A66),
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'LEAVES GROWN',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallStat('MODE', mode),
              _buildSmallStat('DATE', date),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'mindaware.app',
            style: TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
