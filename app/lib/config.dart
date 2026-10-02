/// Supabase dev project. The anon key is public by design (row-level security
/// protects the data). Override at build time with --dart-define if needed.
/// Never put the service-role key or database password here.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL',
      defaultValue: 'https://kduqwkutzyxljhlktuwi.supabase.co');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkdXF3a3V0enl4bGpobGt0dXdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA5MzI0OTQsImV4cCI6MjEwNjUwODQ5NH0.Xm21yiNWTy_tVSuUYfGexOUTlemCyoFNh8r76H-sF9I');
}
