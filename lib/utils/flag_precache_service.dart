// ignore_for_file: use_if_null_to_convert_nulls_to_bools

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Service for precaching flag images to warm up shaders
class FlagPrecacheService {
  static final Map<String, bool> _precachedUrls = {};

  /// Preload flag image to warm up shaders before display
  static Future<void> precacheFlag(BuildContext context, String imageUrl) async {
    if (_precachedUrls.containsKey(imageUrl)) return;

    try {
      if (imageUrl.toLowerCase().endsWith('.svg')) {
        // For SVG, use SvgPicture precaching
        await _precacheSvg(context, imageUrl);
      } else {
        // For PNG/JPG, use standard Flutter precaching
        await precacheImage(
          CachedNetworkImageProvider(imageUrl),
          context,
        );
      }
      _precachedUrls[imageUrl] = true;
    } catch (e) {
      debugPrint('Failed to precache flag $imageUrl: $e');
      // Mark as attempted to avoid repeated failures
      _precachedUrls[imageUrl] = false;
    }
  }

  /// Batch preload multiple flag images with controlled timing
  static Future<void> precacheFlags(
    BuildContext context, 
    List<String> imageUrls, {
    Duration delayBetween = const Duration(milliseconds: 50),
  }) async {
    for (var i = 0; i < imageUrls.length; i++) {
      try {
        await precacheFlag(context, imageUrls[i]);
        if (i < imageUrls.length - 1) {
          await Future.delayed(delayBetween);
        }
      } catch (e) {
        // Continue with next image if one fails
        debugPrint('Failed to precache flag ${imageUrls[i]}: $e');
      }
    }
  }

  /// Check if a flag has been precached
  static bool isPrecached(String imageUrl) {
    return _precachedUrls[imageUrl] == true;
  }

  /// Get precache statistics
  static FlagPrecacheStats getStats() {
    final precached = _precachedUrls.values.where((success) => success).length;
    final failed = _precachedUrls.values.where((success) => !success).length;
    
    return FlagPrecacheStats(
      totalPrecached: precached,
      totalFailed: failed,
      precachedUrls: _precachedUrls.keys.where((url) => _precachedUrls[url] == true).toList(),
    );
  }

  /// Clear precache cache
  static void clearCache() {
    _precachedUrls.clear();
  }

  /// Private method to precache SVG images
  static Future<void> _precacheSvg(BuildContext context, String imageUrl) async {
    // Create a temporary widget to trigger SVG parsing and rendering
    final completer = Completer<void>();
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: -1000, // Off-screen
        top: -1000,
        child: SvgPicture.network(
          imageUrl,
          width: 60,
          height: 40,
          placeholderBuilder: (context) => const SizedBox(),
        ),
      ),
    );

    try {
      Overlay.of(context).insert(overlayEntry);
      
      // Wait briefly for SVG to load and render
      await Future.delayed(const Duration(milliseconds: 100));
      
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    } finally {
      overlayEntry.remove();
    }

    return completer.future;
  }
}

/// Statistics about flag precaching
class FlagPrecacheStats {
  const FlagPrecacheStats({
    required this.totalPrecached,
    required this.totalFailed,
    required this.precachedUrls,
  });

  final int totalPrecached;
  final int totalFailed;
  final List<String> precachedUrls;

  int get totalAttempted => totalPrecached + totalFailed;
  double get successRate => totalAttempted > 0 ? totalPrecached / totalAttempted : 0.0;

  @override
  String toString() {
    return 'FlagPrecacheStats(precached: $totalPrecached, failed: $totalFailed, '
           'success rate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}
