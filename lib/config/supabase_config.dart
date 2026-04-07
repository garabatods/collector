abstract final class SupabaseConfig {
  static const _defaultUrl = 'https://cnteujrruvqizxfsyogp.supabase.co';
  static const _defaultPublishableKey =
      'sb_publishable_0PMT-YxZAcCldmsVPca-ow_r5g844EZ';

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _publishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String get url => _url.isNotEmpty ? _url : _defaultUrl;

  static String get anonKey {
    if (_publishableKey.isNotEmpty) {
      return _publishableKey;
    }

    if (_anonKey.isNotEmpty) {
      return _anonKey;
    }

    return _defaultPublishableKey;
  }

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
