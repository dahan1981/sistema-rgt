class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://libpncdxxgwshnlxicbt.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;
}
