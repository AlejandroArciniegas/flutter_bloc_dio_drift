import 'dart:async';

import 'package:euro_explorer/utils/flag_precache_service.dart';
import 'package:euro_explorer/utils/performance_monitor.dart';
import 'package:flutter/material.dart';

/// Comprehensive flag performance optimization service
/// Combines all optimization strategies for maximum performance
class FlagPerformanceOptimizer {
  static const int _maxConcurrentLoads = 3;
  static const Duration _batchDelay = Duration(milliseconds: 100);

  static final Map<String, Timer> _loadingTimers = {};
  static final Set<String> _currentlyLoading = {};
  static bool _isOptimizationEnabled = true;

  /// Enable or disable performance optimizations (useful for testing)
  // ignore: avoid_positional_boolean_parameters
  static void setOptimizationEnabled(bool enabled) {
    _isOptimizationEnabled = enabled;
    if (!enabled) {
      _clearAllTimers();
    }
  }

  /// Optimize flag loading for a batch of URLs with intelligent scheduling
  static Future<void> optimizeFlagBatch(
    BuildContext context,
    List<String> flagUrls, {
    VoidCallback? onProgress,
    VoidCallback? onComplete,
  }) async {
    if (!_isOptimizationEnabled || flagUrls.isEmpty) {
      onComplete?.call();
      return;
    }

    await PerformanceMonitor.measure('flag_batch_optimization', () async {
      // Filter out already loaded flags
      final precacheStats = FlagPrecacheService.getStats();
      final unloadedUrls = flagUrls
          .where((url) => !precacheStats.precachedUrls.contains(url))
          .toList();

      if (unloadedUrls.isEmpty) {
        onComplete?.call();
        return;
      }

      // Sort URLs by priority (smaller flags first, common formats first)
      unloadedUrls.sort(_prioritizeUrls);

      // Load in controlled batches
      await _loadUrlsInBatches(context, unloadedUrls, onProgress);
      onComplete?.call();
    });
  }

  /// Preload critical flags immediately (visible viewport)
  static Future<void> preloadCriticalFlags(
    BuildContext context,
    List<String> criticalUrls,
  ) async {
    if (!_isOptimizationEnabled) return;

    await PerformanceMonitor.measure('critical_flags_preload', () async {
      // Load critical flags with minimal delay
      for (final url in criticalUrls.take(_maxConcurrentLoads)) {
        unawaited(_loadFlagWithRetry(context, url));
      }

      // Wait briefly to ensure critical flags start loading
      await Future.delayed(const Duration(milliseconds: 50));
    });
  }

  /// Get optimization recommendations based on current state
  static FlagOptimizationReport getOptimizationReport() {
    final performanceStats = PerformanceMonitor.getRecordedOperations()
        .where((op) => op.contains('flag'))
        .map(PerformanceMonitor.getStats)
        .toList();

    final precacheStats = FlagPrecacheService.getStats();

    return FlagOptimizationReport(
      totalFlagsWarmedUp: precacheStats.totalPrecached,
      averageLoadTime: performanceStats.isNotEmpty
          ? performanceStats.map((s) => s.averageMs).reduce((a, b) => a + b) /
              performanceStats.length
          : 0,
      currentlyLoading: _currentlyLoading.length,
      optimizationEnabled: _isOptimizationEnabled,
      recommendations:
          _generateRecommendations(performanceStats, precacheStats),
    );
  }

  /// Monitor flag loading performance in real-time
  static StreamSubscription<FlagLoadingMetrics> monitorFlagLoading() {
    final controller = StreamController<FlagLoadingMetrics>();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (controller.isClosed) {
        timer.cancel();
        return;
      }

      final metrics = FlagLoadingMetrics(
        activeLoads: _currentlyLoading.length,
        queuedLoads: _loadingTimers.length,
        timestamp: DateTime.now(),
        memoryPressure: _estimateMemoryPressure(),
      );

      controller.add(metrics);
    });

    return controller.stream.listen(null);
  }

  // Private helper methods

  static int _prioritizeUrls(String a, String b) {
    // Prioritize PNG over SVG (faster shader compilation)
    final aIsPng = !a.toLowerCase().endsWith('.svg');
    final bIsPng = !b.toLowerCase().endsWith('.svg');

    if (aIsPng && !bIsPng) return -1;
    if (!aIsPng && bIsPng) return 1;

    // Then by URL length (shorter URLs often load faster)
    return a.length.compareTo(b.length);
  }

  static Future<void> _loadUrlsInBatches(
    BuildContext context,
    List<String> urls,
    VoidCallback? onProgress,
  ) async {
    final batches = <List<String>>[];
    for (var i = 0; i < urls.length; i += _maxConcurrentLoads) {
      batches.add(urls.skip(i).take(_maxConcurrentLoads).toList());
    }

    for (var batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];

      // Load batch concurrently
      await Future.wait(
        batch.map((url) => _loadFlagWithRetry(context, url)),
      );

      onProgress?.call();

      // Brief pause between batches to prevent overwhelming the system
      if (batchIndex < batches.length - 1) {
        await Future.delayed(_batchDelay);
      }
    }
  }

  static Future<void> _loadFlagWithRetry(
    BuildContext context,
    String url, {
    int maxRetries = 2,
  }) async {
    if (_currentlyLoading.contains(url)) return;

    _currentlyLoading.add(url);

    try {
      for (var attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          await FlagPrecacheService.precacheFlag(context, url);
          break;
        } catch (e) {
          if (attempt == maxRetries) {
            debugPrint(
                'Failed to load flag $url after $maxRetries attempts: $e',);
          }
          await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
        }
      }
    } finally {
      _currentlyLoading.remove(url);
    }
  }

  static void _clearAllTimers() {
    for (final timer in _loadingTimers.values) {
      timer.cancel();
    }
    _loadingTimers.clear();
    _currentlyLoading.clear();
  }

  static double _estimateMemoryPressure() {
    // Simple heuristic based on active loads
    return (_currentlyLoading.length / _maxConcurrentLoads).clamp(0.0, 1.0);
  }

  static List<String> _generateRecommendations(
    List<PerformanceStats> performanceStats,
    FlagPrecacheStats precacheStats,
  ) {
    final recommendations = <String>[];

    if (performanceStats.isNotEmpty) {
      final avgLoadTime =
          performanceStats.map((s) => s.averageMs).reduce((a, b) => a + b) /
              performanceStats.length;

      if (avgLoadTime > 100) {
        recommendations.add(
            'Consider reducing flag image sizes or implementing more aggressive caching',);
      }

      if (avgLoadTime > 50) {
        recommendations.add(
            'Enable more aggressive preloading for frequently viewed flags',);
      }
    }

    if (precacheStats.totalPrecached < 10) {
      recommendations.add(
          'Increase shader warmup coverage for better initial load performance',);
    }

    if (_currentlyLoading.length > _maxConcurrentLoads) {
      recommendations.add(
          'Consider increasing max concurrent flag loads for faster batch processing',);
    }

    if (recommendations.isEmpty) {
      recommendations.add('Flag loading performance is optimal');
    }

    return recommendations;
  }
}

/// Report on flag optimization performance and recommendations
class FlagOptimizationReport {
  const FlagOptimizationReport({
    required this.totalFlagsWarmedUp,
    required this.averageLoadTime,
    required this.currentlyLoading,
    required this.optimizationEnabled,
    required this.recommendations,
  });

  final int totalFlagsWarmedUp;
  final double averageLoadTime;
  final int currentlyLoading;
  final bool optimizationEnabled;
  final List<String> recommendations;

  @override
  String toString() {
    return '''
Flag Optimization Report:
- Flags warmed up: $totalFlagsWarmedUp
- Average load time: ${averageLoadTime.toStringAsFixed(1)}ms
- Currently loading: $currentlyLoading
- Optimization enabled: $optimizationEnabled
- Recommendations: ${recommendations.join(', ')}
''';
  }
}

/// Real-time metrics for flag loading performance
class FlagLoadingMetrics {
  const FlagLoadingMetrics({
    required this.activeLoads,
    required this.queuedLoads,
    required this.timestamp,
    required this.memoryPressure,
  });

  final int activeLoads;
  final int queuedLoads;
  final DateTime timestamp;
  final double memoryPressure; // 0.0 to 1.0

  bool get isUnderLoad => activeLoads > 0 || queuedLoads > 0;
  bool get isHighMemoryPressure => memoryPressure > 0.7;
}
