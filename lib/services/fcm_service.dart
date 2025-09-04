import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mywishstash/services/monitoring_service.dart';
import 'package:mywishstash/utils/app_logger.dart';

enum NotificationPermissionResult {
  granted,
  denied,
  notDetermined,
  provisional,
  error,
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _cachedToken;

  Future<void> initialize() async {
    try {
      logI('Initialize', tag: 'FCM');
      
      // Código otimizado apenas para Android - verificação de plataforma removida

      final permissionResult = await _requestPermissions();
      
      if (permissionResult == NotificationPermissionResult.granted || 
          permissionResult == NotificationPermissionResult.provisional) {
        await _configureMessageHandling();
        await _getAndCacheToken();
        _setupTokenRefreshListener();
        logI('Initialization completed', tag: 'FCM');
      } else {
        logW('Notifications not permitted', tag: 'FCM');
      }
    } catch (e) {
      logE('Initialization error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_initialize', e);
    }
  }

  Future<NotificationPermissionResult> _requestPermissions() async {
    try {
      
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          logI('Permission granted', tag: 'FCM');
          return NotificationPermissionResult.granted;
          
        case AuthorizationStatus.denied:
          logW('Permission denied', tag: 'FCM');
          return NotificationPermissionResult.denied;
          
        case AuthorizationStatus.notDetermined:
          logW('Permission not determined', tag: 'FCM');
          return NotificationPermissionResult.notDetermined;
          
        case AuthorizationStatus.provisional:
      logI('Permission provisional', tag: 'FCM');
          return NotificationPermissionResult.provisional;
      }
    } catch (e) {
    logE('Permission request error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_requestPermissions', e);
      return NotificationPermissionResult.error;
    }
  }

  Future<void> _configureMessageHandling() async {
    try {

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

  logI('Message handling configured', tag: 'FCM');
    } catch (e) {
  logE('Message handling error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_configureMessageHandling', e);
      rethrow;
    }
  }

  Future<String?> _getAndCacheToken() async {
    try {
      
      _cachedToken = await _messaging.getToken();
      
      if (_cachedToken != null) {
  logI('Token obtained', tag: 'FCM');
      } else {
  logW('Failed to obtain token', tag: 'FCM');
      }
      
      return _cachedToken;
    } catch (e) {
  logE('Token error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_getAndCacheToken', e);
      return null;
    }
  }

  void _setupTokenRefreshListener() {
    try {
      
      _messaging.onTokenRefresh.listen((newToken) {
        logI('Token refreshed', tag: 'FCM');
        _cachedToken = newToken;
        _handleTokenRefresh(newToken);
      }, onError: (e) {
        logE('Token refresh error', tag: 'FCM', error: e);
        MonitoringService.logErrorStatic('FCMService_tokenRefresh', e);
      });
    } catch (e) {
      logE('Token refresh setup error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_setupTokenRefreshListener', e);
    }
  }

  void _handleTokenRefresh(String newToken) {
  }

  Future<String?> getToken() async {
    try {
      if (_cachedToken != null) {
        return _cachedToken;
      }
      
      return await _getAndCacheToken();
    } catch (e) {
      logE('Get token error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_getToken', e);
      return null;
    }
  }

  Future<bool> isPermissionGranted() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      logE('Permission check error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_isPermissionGranted', e);
      return false;
    }
  }

  /// Request notification permissions with detailed result
  Future<NotificationPermissionResult> requestNotificationPermission() async {
    return await _requestPermissions();
  }

  /// Get detailed permission status
  Future<AuthorizationStatus> getPermissionStatus() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      logE('Get permission status error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_getPermissionStatus', e);
      return AuthorizationStatus.notDetermined;
    }
  }

  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;
  Stream<RemoteMessage> get onMessageOpenedApp => FirebaseMessaging.onMessageOpenedApp;
  
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      return await FirebaseMessaging.instance.getInitialMessage();
    } catch (e) {
      logE('Get initial message error', tag: 'FCM', error: e);
      MonitoringService.logErrorStatic('FCMService_getInitialMessage', e);
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      logI('Subscribed to topic', tag: 'FCM', data: {'topic': topic});
    } catch (e) {
      logE('Subscribe topic error', tag: 'FCM', error: e, data: {'topic': topic});
      MonitoringService.logErrorStatic('FCMService_subscribeToTopic', e);
      rethrow;
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      logI('Unsubscribed from topic', tag: 'FCM', data: {'topic': topic});
    } catch (e) {
      logE('Unsubscribe topic error', tag: 'FCM', error: e, data: {'topic': topic});
      MonitoringService.logErrorStatic('FCMService_unsubscribeFromTopic', e);
      rethrow;
    }
  }

  void dispose() {
    _cachedToken = null;
  }
}
