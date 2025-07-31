import 'dart:async';

import 'package:euro_explorer/utils/flag_precache_service.dart';
import 'package:euro_explorer/utils/performance_monitor.dart';
import 'package:flutter/material.dart';

/// Service to handle shader warmup for preventing compilation jank
class ShaderWarmupService {
  static const Duration _warmupTimeout = Duration(seconds: 5);
  static bool _isWarmedUp = false;
  static final Map<String, bool> _warmedUpUrls = {};

  /// Check if shaders have been warmed up
  static bool get isWarmedUp => _isWarmedUp;

  /// Warm up common shaders used throughout the app
  static Future<void> warmupShaders(BuildContext context) async {
    if (_isWarmedUp) return;

    await PerformanceMonitor.measure('shader_warmup_total', () async {
      try {
        // Create a temporary overlay to perform shader warmup
        final overlay = Overlay.of(context);
        late OverlayEntry warmupOverlay;

        final completer = Completer<void>();

        warmupOverlay = OverlayEntry(
          builder: (context) => _WarmupWidget(
            onComplete: () {
              warmupOverlay.remove();
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          ),
        );

        overlay.insert(warmupOverlay);

        // Set timeout to prevent hanging
        Timer(_warmupTimeout, () {
          try {
            warmupOverlay.remove();
          } catch (e) {
            // Overlay might already be removed
          }
          if (!completer.isCompleted) {
            completer.complete();
          }
        });

        await completer.future;
      } catch (e) {
        debugPrint('Shader warmup error: $e');
      } finally {
        _isWarmedUp = true;
      }
    });
  }

  /// Warm up specific flag images
  static Future<void> warmupFlags(
    BuildContext context,
    List<String> flagUrls,
  ) async {
    final urlsToWarmup =
        flagUrls.where((url) => !_warmedUpUrls.containsKey(url)).toList();

    if (urlsToWarmup.isEmpty) return;

    await PerformanceMonitor.measure('flag_warmup_batch', () async {
      await FlagPrecacheService.precacheFlags(context, urlsToWarmup);

      // Mark URLs as warmed up
      for (final url in urlsToWarmup) {
        _warmedUpUrls[url] = true;
      }
    });
  }

  /// Warm up individual flag with performance tracking
  static Future<void> warmupFlag(BuildContext context, String flagUrl) async {
    if (_warmedUpUrls.containsKey(flagUrl)) return;

    await PerformanceMonitor.measure('flag_warmup_single', () async {
      await FlagPrecacheService.precacheFlag(context, flagUrl);
      _warmedUpUrls[flagUrl] = true;
    });
  }

  /// Reset warmup state (useful for testing)
  static void reset() {
    _isWarmedUp = false;
    _warmedUpUrls.clear();
  }

  /// Get warmup statistics
  static ShaderWarmupStats getStats() {
    return ShaderWarmupStats(
      isWarmedUp: _isWarmedUp,
      warmedUpUrlsCount: _warmedUpUrls.length,
      warmedUpUrls: List.from(_warmedUpUrls.keys),
    );
  }
}

/// Widget that performs shader warmup operations off-screen
class _WarmupWidget extends StatefulWidget {
  const _WarmupWidget({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_WarmupWidget> createState() => _WarmupWidgetState();
}

class _WarmupWidgetState extends State<_WarmupWidget> {
  @override
  void initState() {
    super.initState();
    _performWarmup();
  }

  Future<void> _performWarmup() async {
    try {
      // Give the widgets time to render and compile shaders
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('Warmup error: $e');
    } finally {
      // Always call onComplete to prevent hanging
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Render warmup widgets off-screen
    return Positioned(
      left: -1000,
      top: -1000,
      child: Material(
        child: Column(
          children: [
            // Card shapes and shadows
            const Card(
              child: SizedBox(
                width: 100,
                height: 100,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
            // Icons with different themes
            const Icon(Icons.flag, size: 48),
            const Icon(Icons.favorite, size: 24),
            const Icon(Icons.broken_image, size: 48),
            // Text with various styles
            const Text(
              'Sample Text',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Image placeholder containers
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            // SVG and image containers with ClipRRect
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 40,
                color: Colors.blue.shade100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistics about shader warmup status
class ShaderWarmupStats {
  const ShaderWarmupStats({
    required this.isWarmedUp,
    required this.warmedUpUrlsCount,
    required this.warmedUpUrls,
  });

  final bool isWarmedUp;
  final int warmedUpUrlsCount;
  final List<String> warmedUpUrls;

  @override
  String toString() {
    return 'ShaderWarmupStats(isWarmedUp: $isWarmedUp, '
        'warmedUpUrlsCount: $warmedUpUrlsCount)';
  }
}
