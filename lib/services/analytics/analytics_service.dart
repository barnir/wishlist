import 'analytics_provider.dart';
import 'package:mywishstash/services/auth_service.dart';

/// Facade for analytics operations used across the app.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  AnalyticsProvider _provider = NoOpAnalyticsProvider();

  /// Configure a real provider (call early in app bootstrap).
  void configure(AnalyticsProvider provider) {
    _provider = provider;
  }

  Future<void> log(String name, {Map<String, Object?> properties = const {}}) async {
    await _provider.logEvent(name, properties: properties);
  }

  Future<void> identify(String? userId) async {
    await _provider.setUserId(userId);
  }

  Future<void> setUserProps(Map<String, Object?> props) async {
    await _provider.setUserProperties(props);
  }

  Future<void> flush() async => _provider.flush();

  /// Convenience to sync current auth user.
  Future<void> syncAuthUser() async => identify(AuthService.getCurrentUserId());
}