// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VuonRau';

  @override
  String get dashboardTitle => 'Garden dashboard';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get fullscreenCameraTooltip => 'Fullscreen camera';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get deviceInfoTooltip => 'Device info';

  @override
  String get historyDetailButton => 'Details';

  @override
  String get historyTitle => 'Humidity & valve history';

  @override
  String get historyFromLabel => 'From';

  @override
  String get historyToLabel => 'To';

  @override
  String get historyIncludeHumidity => 'Humidity';

  @override
  String get historyIncludeValve => 'Valve';

  @override
  String get historySearchButton => 'Search';

  @override
  String get historyLoadMore => 'Load more';

  @override
  String get historyColumnTime => 'Date & time';

  @override
  String get historyColumnValue => 'Reading';

  @override
  String get historyRangeMax3Days => 'You can view at most 3 days per search.';

  @override
  String get historySelectOneType => 'Select humidity and/or valve.';

  @override
  String get waterValveSectionTitle => 'Water valve control';

  @override
  String humidityRawLabel(Object value) {
    return 'Humidity (raw): $value';
  }

  @override
  String lastUpdatedLabel(Object value) {
    return 'Last updated: $value';
  }

  @override
  String get waterValveSwitchLabel => 'Water valve';

  @override
  String get pressRefreshHint => 'Press refresh to load state.';

  @override
  String valveStateLabel(Object value) {
    return 'Valve: $value';
  }

  @override
  String uptimeTimestampLabel(Object value) {
    return 'Uptime timestamp: $value';
  }

  @override
  String lastUpdatedBackendLabel(Object value) {
    return 'Last updated (backend): $value';
  }

  @override
  String get valveOn => 'ON';

  @override
  String get valveOff => 'OFF';

  @override
  String get unknownState => 'Unknown';

  @override
  String get missingLabel => '(missing)';

  @override
  String get statusCannotReachBackendTitle => 'Cannot reach Backend';

  @override
  String statusCannotReachBackendSubtitle(Object baseUrl, Object error) {
    return 'Base URL: $baseUrl\n$error';
  }

  @override
  String get statusBackendCannotReachMqttTitle =>
      'Backend cannot reach MQTT broker';

  @override
  String statusBackendCannotReachMqttSubtitle(Object baseUrl) {
    return 'Base URL: $baseUrl\nCheck broker / network. Device commands may fail (503).';
  }

  @override
  String get statusDeviceNotReportingTitle => 'Device not reporting state';

  @override
  String statusDeviceNotReportingSubtitle(Object baseUrl, Object ageLabel) {
    return 'Base URL: $baseUrl\nLast state age: $ageLabel. Check ESP32 power/Wi‑Fi/MQTT topics.';
  }

  @override
  String get statusAllSystemsOkTitle => 'All systems OK';

  @override
  String statusAllSystemsOkSubtitle(Object baseUrl) {
    return 'Base URL: $baseUrl\nBackend reachable. MQTT connected. Device state is fresh.';
  }

  @override
  String get retryButton => 'Retry';

  @override
  String get backendBaseUrlLabel => 'Backend base URL';

  @override
  String get backendBaseUrlHint => 'http://192.168.1.10:8000';

  @override
  String get ezvizAccessTokenLabel => 'EZVIZ access token';

  @override
  String get ezvizAccessTokenHint => 'Paste token from EZVIZ OpenAPI / console';

  @override
  String get ezvizAccessTokenHelper =>
      'Leave empty to use the token from build (--dart-define), if configured.';

  @override
  String get technicalInfoTitle => 'Technical info';

  @override
  String deviceLabel(Object deviceId) {
    return 'Device: $deviceId';
  }

  @override
  String backendToMqttLabel(Object value) {
    return 'Backend→MQTT: $value';
  }

  @override
  String get connectedLabel => 'Connected';

  @override
  String get disconnectedLabel => 'Disconnected';

  @override
  String get unknownLabel => '-';

  @override
  String stateAgeLabel(Object value) {
    return 'State age: $value';
  }

  @override
  String staleLabel(Object value) {
    return 'Stale: $value';
  }

  @override
  String get yesLabel => 'Yes';

  @override
  String get noLabel => 'No';

  @override
  String get expandTitle => 'More';

  @override
  String get automationSoon => 'Automation (coming soon)';

  @override
  String get notificationsSoon => 'Notifications (coming soon)';

  @override
  String get ezvizCameraTitle => 'EZVIZ Camera';

  @override
  String ptzStartFailed(Object message) {
    return 'PTZ start failed: $message';
  }

  @override
  String ptzError(Object message) {
    return 'PTZ error: $message';
  }

  @override
  String get startCamera => 'Start camera';

  @override
  String get cameraPausedLabel => 'Paused';

  @override
  String get ezvizNotSupportedWeb => 'EZVIZ view is not supported on Web';

  @override
  String get ezvizOnlyAndroidIos =>
      'EZVIZ view is only supported on Android/iOS';

  @override
  String get stopTooltip => 'Stop';

  @override
  String get missingAccessTokenBanner =>
      'No EZVIZ token: open Settings and paste access token (or build with --dart-define=EZVIZ_ACCESS_TOKEN=...).';

  @override
  String cameraSourceLabel(Object value) {
    return 'Source: $value';
  }

  @override
  String cameraApiAuthLabel(Object apiUrl, Object authUrl) {
    return 'API: $apiUrl   AUTH: $authUrl';
  }

  @override
  String cameraAppKeyTokenLabel(Object appKeyPrefix, Object tokenPrefix) {
    return 'AppKey: $appKeyPrefix…   Token: $tokenPrefix';
  }
}
