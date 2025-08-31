import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'analytics_provider.dart';

class FirebaseAnalyticsProvider implements AnalyticsProvider {
  final FirebaseAnalytics _analytics;
  FirebaseAnalyticsProvider({FirebaseAnalytics? analytics}) : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> logEvent(String name, {Map<String, Object?> properties = const {}}) async {
  final cleaned = cleanParameters(properties);
    await _analytics.logEvent(name: name, parameters: cleaned.isEmpty ? null : cleaned);
  }

  @override
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  @override
  Future<void> setUserProperties(Map<String, Object?> props) async {
    for (final entry in props.entries) {
      final value = entry.value;
      if (value == null) continue;
      await _analytics.setUserProperty(name: entry.key, value: value.toString());
    }
  }

  @override
  Future<void> flush() async {
    // Firebase Analytics SDK batches automatically; no explicit flush.
  }

  /// Normaliza propriedades removendo valores nulos e garantindo Map<String,Object>.
  @visibleForTesting
  static Map<String, Object> cleanParameters(Map<String, Object?> input) {
    final out = <String, Object>{};
    input.forEach((key, value) {
      if (value != null) out[key] = value; // mantém tipo dinâmico seguro
    });
    return out;
  }
}
