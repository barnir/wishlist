/// Abstraction layer for analytics events.
/// Allows swapping underlying implementation (Firebase Analytics, Segment, etc.).
abstract class AnalyticsProvider {
  /// Log a generic event with optional properties.
  Future<void> logEvent(String name, {Map<String, Object?> properties = const {}});

  /// Set the current user identifier (after login).
  Future<void> setUserId(String? userId);

  /// Set user properties (non PII where possible).
  Future<void> setUserProperties(Map<String, Object?> props);

  /// Flush buffered events if backend supports it. Optional.
  Future<void> flush() async {}
}

/// A no-op implementation used by default so calls are safe even if no backend wired.
class NoOpAnalyticsProvider implements AnalyticsProvider {
  @override
  Future<void> logEvent(String name, {Map<String, Object?> properties = const {}}) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperties(Map<String, Object?> props) async {}

  @override
  Future<void> flush() async {}
}
