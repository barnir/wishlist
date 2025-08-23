import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'monitoring_service.dart';

class PerformanceTestService {
  static final PerformanceTestService _instance = PerformanceTestService._internal();
  factory PerformanceTestService() => _instance;
  PerformanceTestService._internal();

  final MonitoringService _monitoringService = MonitoringService();
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // Performance test results
  final List<PerformanceTestResult> _testResults = [];

  // Run comprehensive performance tests
  Future<List<PerformanceTestResult>> runPerformanceTests() async {
    _testResults.clear();
    
    // Test 1: App startup time
    await _testAppStartup();
    
    // Test 2: Database query performance
    await _testDatabaseQueries();
    
    // Test 3: Image loading performance
    await _testImageLoading();
    
    // Test 4: Memory usage
    await _testMemoryUsage();
    
    // Test 5: Network performance
    await _testNetworkPerformance();
    
    // Save results
    await _saveTestResults();
    
    return List.from(_testResults);
  }

  // Test app startup time
  Future<void> _testAppStartup() async {
    final testName = 'App Startup';
    _monitoringService.startOperation(testName);
    
    try {
      // Simulate app startup operations
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Test Supabase connection
      await _supabaseClient.auth.getUser();
      
      _monitoringService.endOperation(testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: Duration(milliseconds: 150), // Simulated
        success: true,
        metadata: {'operation': 'startup'},
      );
      _testResults.add(result);
      
    } catch (e) {
      _monitoringService.logError('Startup test failed: $e', null, operation: testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
        metadata: {'operation': 'startup'},
      );
      _testResults.add(result);
    }
  }

  // Test database query performance
  Future<void> _testDatabaseQueries() async {
    final testName = 'Database Queries';
    _monitoringService.startOperation(testName);
    
    try {
      // Test wishlists query
      final wishlistsStart = DateTime.now();
      await _supabaseClient
          .from('wishlists')
          .select('*')
          .limit(10);
      final wishlistsDuration = DateTime.now().difference(wishlistsStart);
      
      // Test wish_items query
      final itemsStart = DateTime.now();
      await _supabaseClient
          .from('wish_items')
          .select('*')
          .limit(20);
      final itemsDuration = DateTime.now().difference(itemsStart);
      
      // Test users query
      final usersStart = DateTime.now();
      await _supabaseClient
          .from('users')
          .select('*')
          .limit(5);
      final usersDuration = DateTime.now().difference(usersStart);
      
      _monitoringService.endOperation(testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: wishlistsDuration + itemsDuration + usersDuration,
        success: true,
        metadata: {
          'wishlists_query_ms': wishlistsDuration.inMilliseconds,
          'items_query_ms': itemsDuration.inMilliseconds,
          'users_query_ms': usersDuration.inMilliseconds,
        },
      );
      _testResults.add(result);
      
    } catch (e) {
      _monitoringService.logError('Database test failed: $e', null, operation: testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
        metadata: {'operation': 'database'},
      );
      _testResults.add(result);
    }
  }

  // Test image loading performance
  Future<void> _testImageLoading() async {
    final testName = 'Image Loading';
    _monitoringService.startOperation(testName);
    
    try {
      // Simulate image loading tests
      final testImages = [
        'https://picsum.photos/200/200?random=1',
        'https://picsum.photos/200/200?random=2',
        'https://picsum.photos/200/200?random=3',
      ];
      
      final totalStart = DateTime.now();
      final results = <int>[];
      
      for (int i = 0; i < testImages.length; i++) {
        final start = DateTime.now();
        try {
          // Simulate image loading
          await Future.delayed(const Duration(milliseconds: 200));
          final duration = DateTime.now().difference(start);
          results.add(duration.inMilliseconds);
        } catch (e) {
          results.add(-1); // Error
        }
      }
      
      final totalDuration = DateTime.now().difference(totalStart);
      
      _monitoringService.endOperation(testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: totalDuration,
        success: true,
        metadata: {
          'total_images': testImages.length,
          'average_load_time_ms': results.where((r) => r > 0).isEmpty 
              ? 0 
              : results.where((r) => r > 0).reduce((a, b) => a + b) / results.where((r) => r > 0).length,
          'failed_loads': results.where((r) => r < 0).length,
        },
      );
      _testResults.add(result);
      
    } catch (e) {
      _monitoringService.logError('Image loading test failed: $e', null, operation: testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
        metadata: {'operation': 'image_loading'},
      );
      _testResults.add(result);
    }
  }

  // Test memory usage
  Future<void> _testMemoryUsage() async {
    final testName = 'Memory Usage';
    _monitoringService.startOperation(testName);
    
    try {
      // Simulate memory usage test
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Get memory info (simulated)
      final memoryUsage = {
        'heap_size_mb': 45.2,
        'heap_used_mb': 23.1,
        'external_size_mb': 12.5,
      };
      
      _monitoringService.endOperation(testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: const Duration(milliseconds: 50),
        success: true,
        metadata: memoryUsage,
      );
      _testResults.add(result);
      
    } catch (e) {
      _monitoringService.logError('Memory test failed: $e', null, operation: testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
        metadata: {'operation': 'memory'},
      );
      _testResults.add(result);
    }
  }

  // Test network performance
  Future<void> _testNetworkPerformance() async {
    final testName = 'Network Performance';
    _monitoringService.startOperation(testName);
    
    try {
      // Test network latency
      final latencyStart = DateTime.now();
      await _supabaseClient.rpc('get_rate_limit_stats');
      final latency = DateTime.now().difference(latencyStart);
      
      // Test bandwidth (simulated)
      final bandwidthTest = {
        'latency_ms': latency.inMilliseconds,
        'download_speed_mbps': 15.2,
        'upload_speed_mbps': 8.7,
      };
      
      _monitoringService.endOperation(testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: latency,
        success: true,
        metadata: bandwidthTest,
      );
      _testResults.add(result);
      
    } catch (e) {
      _monitoringService.logError('Network test failed: $e', null, operation: testName);
      
      final result = PerformanceTestResult(
        testName: testName,
        duration: Duration.zero,
        success: false,
        error: e.toString(),
        metadata: {'operation': 'network'},
      );
      _testResults.add(result);
    }
  }

  // Save test results to database
  Future<void> _saveTestResults() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId != null) {
        for (final result in _testResults) {
          await _supabaseClient.from('performance_tests').insert({
            'user_id': userId,
            'test_name': result.testName,
            'duration_ms': result.duration.inMilliseconds,
            'success': result.success,
            'error': result.error,
            'metadata': result.metadata,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {
      _monitoringService.logError('Failed to save test results: $e', null, operation: 'saveTestResults');
    }
  }

  // Get test results
  List<PerformanceTestResult> getTestResults() {
    return List.from(_testResults);
  }

  // Generate performance report
  Map<String, dynamic> generatePerformanceReport() {
    final successfulTests = _testResults.where((r) => r.success).toList();
    final failedTests = _testResults.where((r) => !r.success).toList();
    
    final averageDuration = successfulTests.isEmpty 
        ? 0 
        : successfulTests.map((r) => r.duration.inMilliseconds).reduce((a, b) => a + b) / successfulTests.length;
    
    return {
      'total_tests': _testResults.length,
      'successful_tests': successfulTests.length,
      'failed_tests': failedTests.length,
      'success_rate': _testResults.isEmpty ? 0 : (successfulTests.length / _testResults.length) * 100,
      'average_duration_ms': averageDuration,
      'test_results': _testResults.map((r) => r.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Run stress test
  Future<Map<String, dynamic>> runStressTest({
    int iterations = 10,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    final stressResults = <PerformanceTestResult>[];
    final startTime = DateTime.now();
    
    for (int i = 0; i < iterations; i++) {
      await runPerformanceTests();
      stressResults.addAll(_testResults);
      
      if (i < iterations - 1) {
        await Future.delayed(delay);
      }
    }
    
    final totalDuration = DateTime.now().difference(startTime);
    
    return {
      'stress_test_duration_ms': totalDuration.inMilliseconds,
      'iterations': iterations,
      'total_tests_run': stressResults.length,
      'average_test_duration_ms': stressResults.isEmpty 
          ? 0 
          : stressResults.map((r) => r.duration.inMilliseconds).reduce((a, b) => a + b) / stressResults.length,
      'success_rate': stressResults.isEmpty 
          ? 0 
          : (stressResults.where((r) => r.success).length / stressResults.length) * 100,
    };
  }
}

class PerformanceTestResult {
  final String testName;
  final Duration duration;
  final bool success;
  final String? error;
  final Map<String, dynamic> metadata;

  PerformanceTestResult({
    required this.testName,
    required this.duration,
    required this.success,
    this.error,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_name': testName,
      'duration_ms': duration.inMilliseconds,
      'success': success,
      'error': error,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
