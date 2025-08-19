import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  static String supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String googleSignInServerClientId = dotenv.env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID'] ?? '';
  static String scraperApiKey = dotenv.env['SCRAPER_API_KEY'] ?? '';
}