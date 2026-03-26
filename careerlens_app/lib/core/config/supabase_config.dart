import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static String get url => dotenv.env['SUPABASE_URL']?.trim() ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL']?.trim() ?? '';
  static const authCallbackScheme = 'careerlens';
  static const mobileRedirectUrl = '$authCallbackScheme://login-callback/';

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
