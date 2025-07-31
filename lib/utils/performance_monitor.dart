import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance monitoring utility for isolate optimization testing
class PerformanceMonitor {
  static final Map<String, List<Duration>> _measurements = {};
  
  /// Measure execution time of a function
  static Future<T> measure<T>(
    String operation,
    Future<T> Function() function,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await function();
      stopwatch.stop();
      
      _recordMeasurement(operation, stopwatch.elapsed);
      
      if (kDebugMode) {
        print('$operation completed in ${stopwatch.elapsedMilliseconds}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      if (kDebugMode) {
        print('$operation failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      }
      rethrow;
    }
  }
  
  /// Record a measurement
  static void _recordMeasurement(String operation, Duration duration) {
    _measurements.putIfAbsent(operation, () => []);
    _measurements[operation]!.add(duration);
    
    // Keep only the last 10 measurements to avoid memory bloat
    if (_measurements[operation]!.length > 10) {
      _measurements[operation]!.removeAt(0);
    }
  }
  
  /// Get performance statistics for an operation
  static PerformanceStats getStats(String operation) {
    final measurements = _measurements[operation] ?? [];
    if (measurements.isEmpty) {
      return PerformanceStats.empty(operation);
    }
    
    final sortedTimes = measurements.map((d) => d.inMilliseconds).toList()..sort();
    final count = sortedTimes.length;
    
    final average = sortedTimes.reduce((a, b) => a + b) / count;
    final min = sortedTimes.first;
    final max = sortedTimes.last;
    final median = count.isEven
        ? (sortedTimes[count ~/ 2 - 1] + sortedTimes[count ~/ 2]) / 2
        : sortedTimes[count ~/ 2].toDouble();
    
    return PerformanceStats(
      operation: operation,
      count: count,
      averageMs: average,
      minMs: min,
      maxMs: max,
      medianMs: median,
    );
  }
  
  /// Get all recorded operations
  static List<String> getRecordedOperations() {
    return _measurements.keys.toList();
  }
  
  /// Clear all measurements
  static void clear() {
    _measurements.clear();
  }
  
  /// Compare performance between two operations
  static PerformanceComparison compare(String operation1, String operation2) {
    final stats1 = getStats(operation1);
    final stats2 = getStats(operation2);
    
    return PerformanceComparison(
      operation1: stats1,
      operation2: stats2,
      improvementPercent: stats1.averageMs > 0 
          ? ((stats1.averageMs - stats2.averageMs) / stats1.averageMs * 100)
          : 0,
    );
  }
  
  /// Print performance summary
  static void printSummary() {
    if (!kDebugMode) return;
    for (final operation in getRecordedOperations()) {
      getStats(operation);
    }
  }
}

/// Performance statistics for an operation
class PerformanceStats {
  const PerformanceStats({
    required this.operation,
    required this.count,
    required this.averageMs,
    required this.minMs,
    required this.maxMs,
    required this.medianMs,
  });
  
  const PerformanceStats.empty(this.operation)
      : count = 0,
        averageMs = 0,
        minMs = 0,
        maxMs = 0,
        medianMs = 0;
  
  final String operation;
  final int count;
  final double averageMs;
  final int minMs;
  final int maxMs;
  final double medianMs;
  
  bool get hasData => count > 0;
}

/// Performance comparison between two operations
class PerformanceComparison {
  const PerformanceComparison({
    required this.operation1,
    required this.operation2,
    required this.improvementPercent,
  });
  
  final PerformanceStats operation1;
  final PerformanceStats operation2;
  final double improvementPercent;
  
  bool get isImprovement => improvementPercent > 0;
  bool get isRegression => improvementPercent < 0;
  
  String get summaryText {
    if (isImprovement) {
      return '${operation2.operation} is ${improvementPercent.toStringAsFixed(1)}% faster than ${operation1.operation}';
    } else if (isRegression) {
      return '${operation2.operation} is ${(-improvementPercent).toStringAsFixed(1)}% slower than ${operation1.operation}';
    } else {
      return '${operation1.operation} and ${operation2.operation} have similar performance';
    }
  }
}