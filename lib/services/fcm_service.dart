import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wishlist_app/services/monitoring_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _cachedToken;

  Future<void> initialize() async {
    try {
      debugPrint('=== FCMService: Initialize ===');
      
      // Código otimizado apenas para Android - verificação de plataforma removida

      await _requestPermissions();
      await _configureMessageHandling();
      await _getAndCacheToken();
      
      _setupTokenRefreshListener();

      debugPrint('FCMService: Initialization completed successfully');
    } catch (e) {
      debugPrint('FCMService initialization error: $e');
      MonitoringService.logErrorStatic('FCMService_initialize', e);
    }
  }

  Future<void> _requestPermissions() async {
    try {
      debugPrint('FCMService: Requesting permissions');
      
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCMService: Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCMService: Permissions denied by user');
        debugPrint('FCMService: User denied notification permissions');
      }
    } catch (e) {
      debugPrint('FCMService permission request error: $e');
      MonitoringService.logErrorStatic('FCMService_requestPermissions', e);
      rethrow;
    }
  }

  Future<void> _configureMessageHandling() async {
    try {
      debugPrint('FCMService: Configuring message handling');

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('FCMService: Message handling configured');
    } catch (e) {
      debugPrint('FCMService message handling error: $e');
      MonitoringService.logErrorStatic('FCMService_configureMessageHandling', e);
      rethrow;
    }
  }

  Future<String?> _getAndCacheToken() async {
    try {
      debugPrint('FCMService: Getting FCM token');
      
      _cachedToken = await _messaging.getToken();
      
      if (_cachedToken != null) {
        debugPrint('FCMService: Token obtained successfully');
        debugPrint('FCMService: Token: ${_cachedToken!.substring(0, 20)}...');
      } else {
        debugPrint('FCMService: Failed to obtain token');
      }
      
      return _cachedToken;
    } catch (e) {
      debugPrint('FCMService token error: $e');
      MonitoringService.logErrorStatic('FCMService_getAndCacheToken', e);
      return null;
    }
  }

  void _setupTokenRefreshListener() {
    try {
      debugPrint('FCMService: Setting up token refresh listener');
      
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCMService: Token refreshed');
        _cachedToken = newToken;
        _handleTokenRefresh(newToken);
      }, onError: (e) {
        debugPrint('FCMService token refresh error: $e');
        MonitoringService.logErrorStatic('FCMService_tokenRefresh', e);
      });
    } catch (e) {
      debugPrint('FCMService token refresh setup error: $e');
      MonitoringService.logErrorStatic('FCMService_setupTokenRefreshListener', e);
    }
  }

  void _handleTokenRefresh(String newToken) {
    debugPrint('FCMService: Handling token refresh');
    debugPrint('FCMService: Token refreshed, should update backend');
  }

  Future<String?> getToken() async {
    try {
      if (_cachedToken != null) {
        debugPrint('FCMService: Returning cached token');
        return _cachedToken;
      }
      
      debugPrint('FCMService: Getting fresh token');
      return await _getAndCacheToken();
    } catch (e) {
      debugPrint('FCMService getToken error: $e');
      MonitoringService.logErrorStatic('FCMService_getToken', e);
      return null;
    }
  }

  Future<bool> isPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('FCMService permission check error: $e');
      MonitoringService.logErrorStatic('FCMService_isPermissionGranted', e);
      return false;
    }
  }

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;
  
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await FirebaseMessaging.instance.getInitialMessage();
    } catch (e) {
      debugPrint('FCMService getInitialMessage error: $e');
      MonitoringService.logErrorStatic('FCMService_getInitialMessage', e);
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      debugPrint('FCMService: Subscribing to topic: $topic');
      await _messaging.subscribeToTopic(topic);
      debugPrint('FCMService: Successfully subscribed to topic: $topic');
    } catch (e) {
      debugPrint('FCMService subscribe to topic error: $e');
      MonitoringService.logErrorStatic('FCMService_subscribeToTopic', e);
      rethrow;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      debugPrint('FCMService: Unsubscribing from topic: $topic');
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('FCMService: Successfully unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('FCMService unsubscribe from topic error: $e');
      MonitoringService.logErrorStatic('FCMService_unsubscribeFromTopic', e);
      rethrow;
    }
  }

  void dispose() {
    debugPrint('FCMService: Disposing resources');
    _cachedToken = null;
  }
}