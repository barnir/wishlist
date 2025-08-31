import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:wishlist_app/services/fcm_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/utils/app_logger.dart';

enum NotificationType {
  priceDrop,
  wishlistShare,
  newFavorite,
  giftHint,
  general,
}

class NotificationPayload {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;

  NotificationPayload({
    required this.type,
    required this.title,
    required this.body,
    this.data,
  });

  factory NotificationPayload.fromRemoteMessage(RemoteMessage message) {
    final typeString = message.data['type'] ?? 'general';
    final type = NotificationType.values.firstWhere(
      (e) => e.name == typeString,
      orElse: () => NotificationType.general,
    );

    return NotificationPayload(
      type: type,
      title: message.notification?.title ?? 'Wishlist App',
      body: message.notification?.body ?? '',
      data: message.data,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FCMService _fcmService = FCMService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      logI('Initialize', tag: 'NOTIF');

      // Código otimizado apenas para Android - verificação de plataforma removida

      await _initializeLocalNotifications();
      await _fcmService.initialize();
      await _setupMessageListeners();

  _isInitialized = true;
  logI('Initialization completed', tag: 'NOTIF');
    } catch (e) {
  logE('Initialization error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_initialize', e);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      logD('Initializing local notifications', tag: 'NOTIF');

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
      );

  // NOTE (v19 upgrade): If targeting Android 13+ and needing to proactively request
  // POST_NOTIFICATIONS permission, delegate to FCMService.requestNotificationPermission()
  // which already handles runtime permission via firebase_messaging.

      await _createNotificationChannels();
  logI('Local notifications initialized', tag: 'NOTIF');
    } catch (e) {
  logE('Local notifications error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_initializeLocalNotifications', e);
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      logD('Creating notification channels', tag: 'NOTIF');

      const highImportanceChannel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const priceDropChannel = AndroidNotificationChannel(
        'price_drop_channel',
        'Price Drop Alerts',
        description: 'Notifications for price drops on wishlist items.',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const socialChannel = AndroidNotificationChannel(
        'social_channel',
        'Social Updates',
        description: 'Notifications for wishlist shares and social interactions.',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: false,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(highImportanceChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(priceDropChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(socialChannel);

  logI('Notification channels created', tag: 'NOTIF');
    } catch (e) {
  logE('Create channels error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_createNotificationChannels', e);
      rethrow;
    }
  }

  Future<void> _setupMessageListeners() async {
    try {
      logD('Setting up message listeners', tag: 'NOTIF');

      _fcmService.onMessage.listen(_handleForegroundMessage);
      _fcmService.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _fcmService.getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }

  logI('Message listeners configured', tag: 'NOTIF');
    } catch (e) {
  logE('Message listeners error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_setupMessageListeners', e);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      logD('Foreground message', tag: 'NOTIF', data: {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'type': message.data['type']
      });

      final payload = NotificationPayload.fromRemoteMessage(message);
      await _showLocalNotification(payload);

      HapticService.lightImpact();
    } catch (e) {
      logE('Foreground message error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_handleForegroundMessage', e);
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      logD('Message opened app', tag: 'NOTIF');
      final payload = NotificationPayload.fromRemoteMessage(message);
      await _handleNotificationAction(payload);
    } catch (e) {
      logE('Message opened app error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_handleMessageOpenedApp', e);
    }
  }

  Future<void> _handleInitialMessage(RemoteMessage message) async {
    try {
      logD('Initial message', tag: 'NOTIF');
      final payload = NotificationPayload.fromRemoteMessage(message);
      await _handleNotificationAction(payload);
    } catch (e) {
      logE('Initial message error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_handleInitialMessage', e);
    }
  }

  Future<void> _showLocalNotification(NotificationPayload payload) async {
    try {
      logD('Show local notification', tag: 'NOTIF', data: {
        'type': payload.type.name,
        'title': payload.title
      });

      final channelId = _getChannelIdForType(payload.type);
      final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

      final androidDetails = AndroidNotificationDetails(
        channelId,
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      final notificationDetails = NotificationDetails(android: androidDetails);

      await _localNotifications.show(
        notificationId,
        payload.title,
        payload.body,
        notificationDetails,
        payload: _encodePayload(payload),
      );

  logI('Local notification shown', tag: 'NOTIF');
    } catch (e) {
  logE('Show local notification error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_showLocalNotification', e);
    }
  }

  String _getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.priceDrop:
        return 'price_drop_channel';
      case NotificationType.wishlistShare:
      case NotificationType.newFavorite:
      case NotificationType.giftHint:
        return 'social_channel';
      case NotificationType.general:
        return 'high_importance_channel';
    }
  }

  String _encodePayload(NotificationPayload payload) {
    try {
      return '${payload.type.name}|${payload.data?.toString() ?? ''}';
    } catch (e) {
      logE('Encode payload error', tag: 'NOTIF', error: e);
      return payload.type.name;
    }
  }

  NotificationPayload? _decodePayload(String? encoded) {
    try {
      if (encoded == null || encoded.isEmpty) return null;
      
      final parts = encoded.split('|');
      if (parts.isEmpty) return null;

      final type = NotificationType.values.firstWhere(
        (e) => e.name == parts[0],
        orElse: () => NotificationType.general,
      );

      return NotificationPayload(
        type: type,
        title: '',
        body: '',
        data: parts.length > 1 ? {'raw': parts[1]} : null,
      );
    } catch (e) {
      logE('Decode payload error', tag: 'NOTIF', error: e);
      return null;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
  logD('Notification tapped', tag: 'NOTIF');
    final payload = _decodePayload(response.payload);
    if (payload != null) {
      _handleNotificationAction(payload);
    }
  }

  static void _onBackgroundNotificationTap(NotificationResponse response) {
  logD('Background notification tapped', tag: 'NOTIF');
  }

  Future<void> _handleNotificationAction(NotificationPayload payload) async {
    try {
      logD('Handle notification action', tag: 'NOTIF', data: {'type': payload.type.name});

      HapticService.selectionClick();

      switch (payload.type) {
        case NotificationType.priceDrop:
          await _handlePriceDropAction(payload);
          break;
        case NotificationType.wishlistShare:
          await _handleWishlistShareAction(payload);
          break;
        case NotificationType.newFavorite:
          await _handleNewFavoriteAction(payload);
          break;
        case NotificationType.giftHint:
          await _handleGiftHintAction(payload);
          break;
        case NotificationType.general:
          await _handleGeneralAction(payload);
          break;
      }
    } catch (e) {
      logE('Notification action error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_handleNotificationAction', e);
    }
  }

  Future<void> _handlePriceDropAction(NotificationPayload payload) async {
  logD('Price drop action', tag: 'NOTIF');
  }

  Future<void> _handleWishlistShareAction(NotificationPayload payload) async {
  logD('Wishlist share action', tag: 'NOTIF');
  }

  Future<void> _handleNewFavoriteAction(NotificationPayload payload) async {
  logD('New favorite action', tag: 'NOTIF');
  }

  Future<void> _handleGiftHintAction(NotificationPayload payload) async {
  logD('Gift hint action', tag: 'NOTIF');
  }

  Future<void> _handleGeneralAction(NotificationPayload payload) async {
  logD('General notification action', tag: 'NOTIF');
  }

  Future<String?> getDeviceToken() async {
    return await _fcmService.getToken();
  }

  Future<bool> hasPermission() async {
    return await _fcmService.isPermissionGranted();
  }

  /// Request notification permissions with detailed feedback
  Future<NotificationPermissionResult> requestPermission() async {
    return await _fcmService.requestNotificationPermission();
  }

  /// Get detailed permission status
  Future<AuthorizationStatus> getPermissionStatus() async {
    return await _fcmService.getPermissionStatus();
  }

  /// Check if notifications are enabled and provide user-friendly status
  Future<Map<String, dynamic>> getNotificationStatus(BuildContext? context) async {
    final l10n = (context != null) ? AppLocalizations.of(context) : null; // resolve antes dos awaits
    try {
      final status = await getPermissionStatus();
      final isEnabled = await hasPermission();
      return {
        'enabled': isEnabled,
        'status': status.name,
        'canRequest': status == AuthorizationStatus.notDetermined,
        'needsSettings': status == AuthorizationStatus.denied,
        'message': _getStatusMessage(status, l10n),
      };
    } catch (e) {
  logE('Get notification status error', tag: 'NOTIF', error: e);
      return {
        'enabled': false,
        'status': 'error',
        'canRequest': false,
        'needsSettings': false,
        'message': l10n?.notificationsError ?? 'Erro ao verificar estado das notificações',
      };
    }
  }

  String _getStatusMessage(AuthorizationStatus status, AppLocalizations? l10n) {
    if (l10n == null) {
      // Fallback para português se não tiver contexto
      switch (status) {
        case AuthorizationStatus.authorized:
          return 'Notificações ativadas';
        case AuthorizationStatus.denied:
          return 'Notificações desativadas - ativar nas configurações';
        case AuthorizationStatus.notDetermined:
          return 'Permissão de notificações não solicitada';
        case AuthorizationStatus.provisional:
          return 'Notificações silenciosas ativadas';
      }
    }
    // Localized
    switch (status) {
      case AuthorizationStatus.authorized:
        return l10n.notificationsActive;
      case AuthorizationStatus.denied:
        return l10n.notificationsDisabledGoSettings;
      case AuthorizationStatus.notDetermined:
        return l10n.notificationsNotRequested;
      case AuthorizationStatus.provisional:
        return l10n.notificationsSilent;
    }

  // (Unreachable fallback removed)
  }


  Future<void> subscribeToUserTopic(String userId) async {
    try {
      await _fcmService.subscribeToTopic('user_$userId');
  logI('Subscribed to user topic', tag: 'NOTIF', data: {'userTopic': 'user_$userId'});
    } catch (e) {
  logE('Subscribe user topic error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_subscribeToUserTopic', e);
    }
  }

  Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      await _fcmService.unsubscribeFromTopic('user_$userId');
  logI('Unsubscribed from user topic', tag: 'NOTIF', data: {'userTopic': 'user_$userId'});
    } catch (e) {
  logE('Unsubscribe user topic error', tag: 'NOTIF', error: e);
      MonitoringService.logErrorStatic('NotificationService_unsubscribeFromUserTopic', e);
    }
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
  logD('Disposing resources', tag: 'NOTIF');
    _fcmService.dispose();
    _isInitialized = false;
  }
}