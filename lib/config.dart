import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String googleSignInServerClientId =
      dotenv.env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID'] ?? '';
}
