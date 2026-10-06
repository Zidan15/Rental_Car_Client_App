import 'package:flutter_test/flutter_test.dart';
import 'package:client_app/services/env_service.dart';

void main() {
  setUp(() {
    Env.reset();
  });

  tearDown(() {
    Env.reset();
  });

  group('Env Service - Key-Value Parsing & Edge Cases', () {
    test('parses standard unquoted key-value pairs', () {
      const sampleEnv = '''
SUPABASE_URL=https://sample-project.supabase.co
SUPABASE_ANON_KEY=sample-anon-key-12345
''';

      Env.parse(sampleEnv);

      expect(Env.supabaseUrl, equals('https://sample-project.supabase.co'));
      expect(Env.supabaseAnonKey, equals('sample-anon-key-12345'));
    });

    test('strips double and single quotes around values', () {
      const sampleEnv = '''
GROQ_API_KEY="gsk_test_secret_double_quotes"
GOOGLE_MAPS_API_KEY='AIzaSy_test_single_quotes'
''';

      Env.parse(sampleEnv);

      expect(Env.groqApiKey, equals('gsk_test_secret_double_quotes'));
      expect(Env.googleMapsApiKey, equals('AIzaSy_test_single_quotes'));
    });

    test('ignores full line comments and blank lines', () {
      const sampleEnv = '''
# This is a comment at the top
# Another comment line

SUPABASE_URL=https://my-project.supabase.co

# Section comment
GROQ_API_KEY=gsk_valid_key
''';

      Env.parse(sampleEnv);

      expect(Env.supabaseUrl, equals('https://my-project.supabase.co'));
      expect(Env.groqApiKey, equals('gsk_valid_key'));
    });

    test('handles values containing multiple equals signs', () {
      const sampleEnv = '''
COMPLEX_TOKEN=YWJjZGVmZ2hpams===
''';

      Env.parse(sampleEnv);

      expect(Env.get('COMPLEX_TOKEN'), equals('YWJjZGVmZ2hpams==='));
    });

    test('returns custom default value when key is missing', () {
      expect(Env.get('NON_EXISTENT_KEY'), equals(''));
      expect(Env.get('NON_EXISTENT_KEY', defaultValue: 'default_val'), equals('default_val'));
    });

    test('handles whitespace around keys and values gracefully', () {
      const sampleEnv = '''
  SUPABASE_URL  =   https://spaced-url.supabase.co  
''';

      Env.parse(sampleEnv);

      expect(Env.supabaseUrl, equals('https://spaced-url.supabase.co'));
    });

    test('reset clears previously loaded configuration', () {
      Env.parse('SUPABASE_URL=https://initial.supabase.co');
      expect(Env.supabaseUrl, equals('https://initial.supabase.co'));

      Env.reset();
      expect(Env.supabaseUrl, equals(''));
    });
  });
}
