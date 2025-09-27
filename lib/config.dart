import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String googleSignInServerClientId =
      dotenv.env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID'] ?? '';
  // Enable forwarding of performance samples to analytics provider (kept off by default to reduce noise)
  static bool enablePerfAnalytics =
      (dotenv.env['ENABLE_PERF_ANALYTICS'] == 'true');
}
