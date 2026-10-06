import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class Env {
  static final Map<String, String> _env = {};

  @visibleForTesting
  static void parse(String content) {
    for (final line in content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        var value = parts.sublist(1).join('=').trim();
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1).trim();
        }
        _env[key] = value;
      }
    }
  }

  @visibleForTesting
  static void reset() {
    _env.clear();
  }

  static Future<void> load() async {
    try {
      final content = await rootBundle.loadString('.env');
      parse(content);
    } catch (_) {
      // Gracefully handled if .env is missing
    }
  }

  static String get(String key, {String defaultValue = ''}) =>
      _env[key] ?? defaultValue;

  static String get supabaseUrl => get('SUPABASE_URL');
  static String get supabaseAnonKey => get('SUPABASE_ANON_KEY');
  static String get groqApiKey => get('GROQ_API_KEY');
  static String get googleMapsApiKey => get('GOOGLE_MAPS_API_KEY');
}
