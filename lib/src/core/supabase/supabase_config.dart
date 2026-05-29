import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and initialization.
class SupabaseConfig {
  static const String supabaseUrl = 'https://cmntfqsruljhlgqirtkw.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtbnRmcXNydWxqaGxncWlydGt3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk5NzYwMzAsImV4cCI6MjA5NTU1MjAzMH0.lUPybkYCQthYP3uzHbCja4SK51rqecPd6DBTwwU0NI4';

  /// Initialize Supabase. Call in main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Quick accessor for the Supabase client.
  static SupabaseClient get client => Supabase.instance.client;

  /// Quick accessor for auth.
  static GoTrueClient get auth => client.auth;
}
