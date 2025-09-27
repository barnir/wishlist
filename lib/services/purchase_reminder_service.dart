import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/wish_item_status.dart';
import '../utils/app_logger.dart';

/// Serviço para gerir lembretes de compra de itens marcados como "vou comprar"
///
/// Funcionalidades:
/// - Agenda lembretes no 6º e 7º dia após marcar "vou comprar"
/// - Remove automaticamente status após 7 dias se não for atualizado
/// - Envia notificações através de Cloud Functions
class PurchaseReminderService {
  static final PurchaseReminderService _instance =
      PurchaseReminderService._internal();
  factory PurchaseReminderService() => _instance;
  PurchaseReminderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Agenda lembretes para um item marcado como "vou comprar"
  Future<void> scheduleReminders({
    required String wishItemId,
    required String userId,
    required String itemName,
    required String wishlistId,
  }) async {
    try {
      debugPrint('🔔 Scheduling reminders for item: $itemName');

      final now = DateTime.now();
      final reminder6Days = now.add(const Duration(days: 6));
      final reminder7Days = now.add(const Duration(days: 7));
      final expirationDate = now.add(const Duration(days: 7, hours: 1));

      // Criar documento de lembrete
      await _firestore
          .collection('purchase_reminders')
          .doc('${userId}_$wishItemId')
          .set({
            'user_id': userId,
            'wish_item_id': wishItemId,
            'item_name': itemName,
            'wishlist_id': wishlistId,
            'created_at': FieldValue.serverTimestamp(),
            'reminder_6_days': Timestamp.fromDate(reminder6Days),
            'reminder_7_days': Timestamp.fromDate(reminder7Days),
            'expiration_date': Timestamp.fromDate(expirationDate),
            'reminder_6_sent': false,
            'reminder_7_sent': false,
            'status': 'active',
          });

      logI(
        'Purchase reminder scheduled',
        tag: 'REMINDER',
        data: {
          'itemId': wishItemId,
          'userId': userId,
          'itemName': itemName,
          'reminder6Days': reminder6Days.toIso8601String(),
          'reminder7Days': reminder7Days.toIso8601String(),
        },
      );
    } catch (e) {
      logE(
        'Error scheduling reminders',
        tag: 'REMINDER',
        error: e,
        data: {'itemId': wishItemId, 'userId': userId},
      );
    }
  }

  /// Remove lembretes quando o item é marcado como comprado ou removido
  Future<void> cancelReminders({
    required String wishItemId,
    required String userId,
    String reason = 'status_updated',
  }) async {
    try {
      debugPrint('🔔 Cancelling reminders for item: $wishItemId');

      final docId = '${userId}_$wishItemId';
      await _firestore.collection('purchase_reminders').doc(docId).update({
        'status': 'cancelled',
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancel_reason': reason,
      });

      logI(
        'Purchase reminder cancelled',
        tag: 'REMINDER',
        data: {'itemId': wishItemId, 'userId': userId, 'reason': reason},
      );
    } catch (e) {
      logE(
        'Error cancelling reminders',
        tag: 'REMINDER',
        error: e,
        data: {'itemId': wishItemId, 'userId': userId},
      );
    }
  }

  /// Obter lembretes ativos do usuário atual
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      if (currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('purchase_reminders')
          .where('user_id', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      logE('Error getting active reminders', tag: 'REMINDER', error: e);
      return [];
    }
  }

  /// Processar lembretes expirados (usado por Cloud Functions)
  /// Este método será chamado por uma Cloud Function agendada
  static Future<void> processExpiredReminders() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // Buscar lembretes expirados
      final expiredQuery = await firestore
          .collection('purchase_reminders')
          .where('status', isEqualTo: 'active')
          .where(
            'expiration_date',
            isLessThanOrEqualTo: Timestamp.fromDate(now),
          )
          .get();

      for (final doc in expiredQuery.docs) {
        final data = doc.data();
        final wishItemId = data['wish_item_id'] as String;
        final userId = data['user_id'] as String;

        // Remover o status "vou comprar" do item
        await firestore
            .collection('wish_item_statuses')
            .where('wish_item_id', isEqualTo: wishItemId)
            .where('user_id', isEqualTo: userId)
            .where('status', isEqualTo: 'will_buy')
            .get()
            .then((statusQuery) async {
              for (final statusDoc in statusQuery.docs) {
                await statusDoc.reference.delete();
              }
            });

        // Marcar lembrete como expirado
        await doc.reference.update({
          'status': 'expired',
          'expired_at': FieldValue.serverTimestamp(),
        });

        debugPrint(
          '🔔 Expired reminder processed: $wishItemId for user $userId',
        );
      }
    } catch (e) {
      debugPrint('❌ Error processing expired reminders: $e');
    }
  }

  /// Processar lembretes para envio (usado por Cloud Functions)
  /// Este método será chamado por uma Cloud Function agendada
  static Future<void> processPendingReminders() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now();

      // Buscar lembretes do 6º dia não enviados
      final reminder6Query = await firestore
          .collection('purchase_reminders')
          .where('status', isEqualTo: 'active')
          .where('reminder_6_sent', isEqualTo: false)
          .where(
            'reminder_6_days',
            isLessThanOrEqualTo: Timestamp.fromDate(now),
          )
          .get();

      for (final doc in reminder6Query.docs) {
        await _sendReminder(doc, 6);
        await doc.reference.update({'reminder_6_sent': true});
      }

      // Buscar lembretes do 7º dia não enviados
      final reminder7Query = await firestore
          .collection('purchase_reminders')
          .where('status', isEqualTo: 'active')
          .where('reminder_7_sent', isEqualTo: false)
          .where(
            'reminder_7_days',
            isLessThanOrEqualTo: Timestamp.fromDate(now),
          )
          .get();

      for (final doc in reminder7Query.docs) {
        await _sendReminder(doc, 7);
        await doc.reference.update({'reminder_7_sent': true});
      }
    } catch (e) {
      debugPrint('❌ Error processing pending reminders: $e');
    }
  }

  /// Enviar notificação de lembrete (usado por Cloud Functions)
  static Future<void> _sendReminder(
    QueryDocumentSnapshot doc,
    int dayNumber,
  ) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final userId = data['user_id'] as String;
      final itemName = data['item_name'] as String;
      final wishlistId = data['wishlist_id'] as String;

      // Buscar token FCM do usuário
      final userDoc = await FirebaseFirestore.instance
          .collection('user_profiles')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final fcmToken = userData['fcm_token'] as String?;

      if (fcmToken == null || fcmToken.isEmpty) return;

      final isLastDay = dayNumber == 7;
      final title = isLastDay
          ? '⚡ Último dia para comprar!'
          : '🔔 Lembrete de compra';

      final body = isLastDay
          ? 'Hoje é o último dia para marcar "$itemName" como comprado. Depois de hoje, a reserva será cancelada.'
          : 'Faltam ${8 - dayNumber} dias para completar a compra de "$itemName".';

      // Enviar notificação através de Cloud Messaging
      await FirebaseFirestore.instance.collection('notifications_queue').add({
        'user_id': userId,
        'fcm_token': fcmToken,
        'title': title,
        'body': body,
        'data': {
          'type': 'purchase_reminder',
          'wish_item_id': data['wish_item_id'],
          'wishlist_id': wishlistId,
          'day_number': dayNumber,
        },
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      debugPrint(
        '🔔 Reminder notification queued: $itemName (day $dayNumber) for user $userId',
      );
    } catch (e) {
      debugPrint('❌ Error sending reminder: $e');
    }
  }

  /// Atualizar lembrete quando status muda
  Future<void> updateReminderStatus({
    required String wishItemId,
    required String userId,
    required ItemPurchaseStatus newStatus,
  }) async {
    try {
      final docId = '${userId}_$wishItemId';

      if (newStatus == ItemPurchaseStatus.purchased) {
        // Cancelar lembrete se item foi comprado
        await cancelReminders(
          wishItemId: wishItemId,
          userId: userId,
          reason: 'item_purchased',
        );
      } else if (newStatus == ItemPurchaseStatus.willBuy) {
        // Verificar se já existe lembrete ativo
        final doc = await _firestore
            .collection('purchase_reminders')
            .doc(docId)
            .get();

        if (!doc.exists || doc.data()?['status'] != 'active') {
          // Obter informações do item para criar novo lembrete
          final itemDoc = await _firestore
              .collection('wish_items')
              .doc(wishItemId)
              .get();

          if (itemDoc.exists) {
            final itemData = itemDoc.data()!;
            await scheduleReminders(
              wishItemId: wishItemId,
              userId: userId,
              itemName: itemData['name'] ?? 'Item',
              wishlistId: itemData['wishlist_id'] ?? '',
            );
          }
        }
      }
    } catch (e) {
      logE(
        'Error updating reminder status',
        tag: 'REMINDER',
        error: e,
        data: {
          'itemId': wishItemId,
          'userId': userId,
          'newStatus': newStatus.name,
        },
      );
    }
  }
}
