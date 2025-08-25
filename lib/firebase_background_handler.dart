import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('=== Background Message Handler ===');
    debugPrint('Background message received');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    final type = message.data['type'] ?? 'general';
    debugPrint('Notification type: $type');

    switch (type) {
      case 'price_drop':
        debugPrint('Background: Handling price drop notification');
        break;
      case 'wishlist_share':
        debugPrint('Background: Handling wishlist share notification');
        break;
      case 'new_favorite':
        debugPrint('Background: Handling new favorite notification');
        break;
      case 'gift_hint':
        debugPrint('Background: Handling gift hint notification');
        break;
      case 'general':
      default:
        debugPrint('Background: Handling general notification');
        break;
    }

    debugPrint('Background message handling completed');
  } catch (e) {
    debugPrint('Background message handler error: $e');
  }
}