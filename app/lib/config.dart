/// Supabase dev project. The anon key is public by design (row-level security
/// protects the data). Override at build time with --dart-define if needed.
/// Never put the service-role key or database password here.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kduqwkutzyxljhlktuwi.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkdXF3a3V0enl4bGpobGt0dXdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5MzI0OTQsImV4cCI6MjEwNjUwODQ5NH0.Xm21yiNWTy_tVSuUYfGexOUTlemCyoFNh8r76H-sF9I',
  );

  /// Google OAuth Web client (project maidan-510416). Public; its secret lives
  /// only in the Supabase Google provider settings.
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '164033398684-rnq9johc16njao3rsp2i677i2vqf0ouv.apps.googleusercontent.com',
  );
}
