class EzvizConfig {
  // Prefer passing these via --dart-define to avoid committing secrets.
  static const appKey = String.fromEnvironment(
    'EZVIZ_APP_KEY',
    defaultValue: '37eca392a13640d180223f131bf05c17',
  );

  /// Token từ `--dart-define=EZVIZ_ACCESS_TOKEN=...` (tuỳ chọn nếu đã lưu trong Cài đặt).
  static const accessTokenFromEnvironment = String.fromEnvironment(
    'EZVIZ_ACCESS_TOKEN',
    defaultValue: '',
  );

  static const ezopenUrl = String.fromEnvironment(
    'EZVIZ_EZOPEN_URL',
    defaultValue: 'ezopen://open.ezviz.com/BH1541592/1.hd.live',
  );

  // International (EZVIZLife) defaults (Singapore / APAC):
  // - https://isgpopen.ezvizlife.com
  // - https://isgpauth.ezvizlife.com
  //
  // Override via --dart-define if your region differs.
  static const apiUrl = String.fromEnvironment(
    'EZVIZ_API_URL',
    defaultValue: 'https://isgpopen.ezvizlife.com',
  );

  static const authUrl = String.fromEnvironment(
    'EZVIZ_AUTH_URL',
    defaultValue: 'https://isgpauth.ezvizlife.com',
  );
}

