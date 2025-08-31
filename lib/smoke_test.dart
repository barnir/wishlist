import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/analytics/analytics_service.dart';
import 'utils/app_logger.dart';

/// Executa um conjunto mínimo de operações para validar integração Firebase após upgrades.
Future<void> runSmokeTest() async {
  final results = <String, Object?>{};
  final swTotal = Stopwatch()..start();
  try {
    // Auth (signin existente ou anónimo)
    final auth = firebase_auth.FirebaseAuth.instance;
    final swAuth = Stopwatch()..start();
    firebase_auth.User? user = auth.currentUser;
    if (user == null) {
      try {
        final cred = await auth.signInAnonymously();
        user = cred.user;
        results['auth_mode'] = 'anonymous';
      } catch (e) {
        results['auth_error'] = e.toString();
      }
    } else {
      results['auth_mode'] = 'existing';
    }
    results['auth_ms'] = swAuth.elapsedMilliseconds;

    // Firestore read
    final swFs = Stopwatch()..start();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('wish_items')
          .limit(1)
          .get();
      results['firestore_docs'] = snap.docs.length;
    } catch (e) {
      results['firestore_error'] = e.toString();
    }
    results['firestore_ms'] = swFs.elapsedMilliseconds;

    // Messaging token
    final swMsg = Stopwatch()..start();
    try {
      final token = await FirebaseMessaging.instance.getToken();
      results['messaging_token_present'] = token != null && token.isNotEmpty;
    } catch (e) {
      results['messaging_error'] = e.toString();
    }
    results['messaging_ms'] = swMsg.elapsedMilliseconds;

    // Cloud Function (opcional) - tentar callable 'ping' se existir
    final swFn = Stopwatch()..start();
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('ping');
      final resp = await callable.call();
      results['functions_ping'] = resp.data;
    } catch (e) {
      results['functions_ping_error'] = e.toString();
    }
    results['functions_ms'] = swFn.elapsedMilliseconds;

    // Analytics evento
    final swAn = Stopwatch()..start();
    try {
      await AnalyticsService().log('smoke_test', properties: {
        'auth_mode': results['auth_mode'] ?? 'unknown',
        'fs_docs': results['firestore_docs'] ?? -1,
        'has_token': results['messaging_token_present'] ?? false,
        'has_fn': results.containsKey('functions_ping')
      });
      results['analytics_logged'] = true;
    } catch (e) {
      results['analytics_error'] = e.toString();
    }
    results['analytics_ms'] = swAn.elapsedMilliseconds;
  } finally {
    results['total_ms'] = swTotal.elapsedMilliseconds;
    appLog('SMOKE_TEST_RESULTS', tag: 'SMOKE', data: results);
  }
}
