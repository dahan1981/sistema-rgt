class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://libpncdxxgwshnlxicbt.supabase.co',
  );

  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static const updateManifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
  );

  static bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;
}
