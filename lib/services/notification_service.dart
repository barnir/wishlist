import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:wishlist_app/services/fcm_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';

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
      debugPrint('=== NotificationService: Initialize ===');

      // Código otimizado apenas para Android - verificação de plataforma removida

      await _initializeLocalNotifications();
      await _fcmService.initialize();
      await _setupMessageListeners();

      _isInitialized = true;
      debugPrint('NotificationService: Initialization completed successfully');
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
      MonitoringService.logErrorStatic('NotificationService_initialize', e);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      debugPrint('NotificationService: Initializing local notifications');

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
      );

      await _createNotificationChannels();
      debugPrint('NotificationService: Local notifications initialized');
    } catch (e) {
      debugPrint('NotificationService local notifications error: $e');
      MonitoringService.logErrorStatic('NotificationService_initializeLocalNotifications', e);
      rethrow;
    }
  }

  Future<void> _createNotificationChannels() async {
    try {
      debugPrint('NotificationService: Creating notification channels');

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

      debugPrint('NotificationService: Notification channels created');
    } catch (e) {
      debugPrint('NotificationService channels error: $e');
      MonitoringService.logErrorStatic('NotificationService_createNotificationChannels', e);
      rethrow;
    }
  }

  Future<void> _setupMessageListeners() async {
    try {
      debugPrint('NotificationService: Setting up message listeners');

      _fcmService.onMessage.listen(_handleForegroundMessage);
      _fcmService.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      final initialMessage = await _fcmService.getInitialMessage();
      if (initialMessage != null) {
        _handleInitialMessage(initialMessage);
      }

      debugPrint('NotificationService: Message listeners configured');
    } catch (e) {
      debugPrint('NotificationService message listeners error: $e');
      MonitoringService.logErrorStatic('NotificationService_setupMessageListeners', e);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      debugPrint('NotificationService: Handling foreground message');
      debugPrint('Message title: ${message.notification?.title}');
      debugPrint('Message body: ${message.notification?.body}');

      final payload = NotificationPayload.fromRemoteMessage(message);
      await _showLocalNotification(payload);

      HapticService.lightImpact();
    } catch (e) {
      debugPrint('NotificationService foreground message error: $e');
      MonitoringService.logErrorStatic('NotificationService_handleForegroundMessage', e);
    }
  }

  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    try {
      debugPrint('NotificationService: Handling message opened app');
      final payload = NotificationPayload.fromRemoteMessage(message);
      await _handleNotificationAction(payload);
    } catch (e) {
      debugPrint('NotificationService message opened app error: $e');
      MonitoringService.logErrorStatic('NotificationService_handleMessageOpenedApp', e);
    }
  }

  Future<void> _handleInitialMessage(RemoteMessage message) async {
    try {
      debugPrint('NotificationService: Handling initial message');
      final payload = NotificationPayload.fromRemoteMessage(message);
      await _handleNotificationAction(payload);
    } catch (e) {
      debugPrint('NotificationService initial message error: $e');
      MonitoringService.logErrorStatic('NotificationService_handleInitialMessage', e);
    }
  }

  Future<void> _showLocalNotification(NotificationPayload payload) async {
    try {
      debugPrint('NotificationService: Showing local notification');

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

      debugPrint('NotificationService: Local notification shown');
    } catch (e) {
      debugPrint('NotificationService show local notification error: $e');
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
      debugPrint('NotificationService encode payload error: $e');
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
      debugPrint('NotificationService decode payload error: $e');
      return null;
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('NotificationService: Notification tapped');
    final payload = _decodePayload(response.payload);
    if (payload != null) {
      _handleNotificationAction(payload);
    }
  }

  static void _onBackgroundNotificationTap(NotificationResponse response) {
    debugPrint('NotificationService: Background notification tapped');
  }

  Future<void> _handleNotificationAction(NotificationPayload payload) async {
    try {
      debugPrint('NotificationService: Handling notification action for type: ${payload.type}');

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
      debugPrint('NotificationService notification action error: $e');
      MonitoringService.logErrorStatic('NotificationService_handleNotificationAction', e);
    }
  }

  Future<void> _handlePriceDropAction(NotificationPayload payload) async {
    debugPrint('NotificationService: Handling price drop action');
    debugPrint('NotificationService: Price drop notification tapped');
  }

  Future<void> _handleWishlistShareAction(NotificationPayload payload) async {
    debugPrint('NotificationService: Handling wishlist share action');
    debugPrint('NotificationService: Wishlist share notification tapped');
  }

  Future<void> _handleNewFavoriteAction(NotificationPayload payload) async {
    debugPrint('NotificationService: Handling new favorite action');
    debugPrint('NotificationService: New favorite notification tapped');
  }

  Future<void> _handleGiftHintAction(NotificationPayload payload) async {
    debugPrint('NotificationService: Handling gift hint action');
    debugPrint('NotificationService: Gift hint notification tapped');
  }

  Future<void> _handleGeneralAction(NotificationPayload payload) async {
    debugPrint('NotificationService: Handling general action');
    debugPrint('NotificationService: General notification tapped');
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
      debugPrint('Error getting notification status: $e');
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
      debugPrint('NotificationService: Subscribed to user topic: user_$userId');
    } catch (e) {
      debugPrint('NotificationService subscribe to user topic error: $e');
      MonitoringService.logErrorStatic('NotificationService_subscribeToUserTopic', e);
    }
  }

  Future<void> unsubscribeFromUserTopic(String userId) async {
    try {
      await _fcmService.unsubscribeFromTopic('user_$userId');
      debugPrint('NotificationService: Unsubscribed from user topic: user_$userId');
    } catch (e) {
      debugPrint('NotificationService unsubscribe from user topic error: $e');
      MonitoringService.logErrorStatic('NotificationService_unsubscribeFromUserTopic', e);
    }
  }

  bool get isInitialized => _isInitialized;

  void dispose() {
    debugPrint('NotificationService: Disposing resources');
    _fcmService.dispose();
    _isInitialized = false;
  }
}