import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'VuonRau'**
  String get appTitle;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Garden dashboard'**
  String get dashboardTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @fullscreenCameraTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen camera'**
  String get fullscreenCameraTooltip;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @deviceInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Device info'**
  String get deviceInfoTooltip;

  /// No description provided for @historyDetailButton.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get historyDetailButton;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Humidity & valve history'**
  String get historyTitle;

  /// No description provided for @historyFromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get historyFromLabel;

  /// No description provided for @historyToLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get historyToLabel;

  /// No description provided for @historyIncludeHumidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get historyIncludeHumidity;

  /// No description provided for @historyIncludeValve.
  ///
  /// In en, this message translates to:
  /// **'Valve'**
  String get historyIncludeValve;

  /// No description provided for @historySearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get historySearchButton;

  /// No description provided for @historyLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get historyLoadMore;

  /// No description provided for @historyColumnTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get historyColumnTime;

  /// No description provided for @historyColumnValue.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get historyColumnValue;

  /// No description provided for @historyRangeMax3Days.
  ///
  /// In en, this message translates to:
  /// **'You can view at most 3 days per search.'**
  String get historyRangeMax3Days;

  /// No description provided for @historySelectOneType.
  ///
  /// In en, this message translates to:
  /// **'Select humidity and/or valve.'**
  String get historySelectOneType;

  /// No description provided for @waterValveSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Water valve control'**
  String get waterValveSectionTitle;

  /// No description provided for @humidityRawLabel.
  ///
  /// In en, this message translates to:
  /// **'Humidity (raw): {value}'**
  String humidityRawLabel(Object value);

  /// No description provided for @lastUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {value}'**
  String lastUpdatedLabel(Object value);

  /// No description provided for @waterValveSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Water valve'**
  String get waterValveSwitchLabel;

  /// No description provided for @pressRefreshHint.
  ///
  /// In en, this message translates to:
  /// **'Press refresh to load state.'**
  String get pressRefreshHint;

  /// No description provided for @valveStateLabel.
  ///
  /// In en, this message translates to:
  /// **'Valve: {value}'**
  String valveStateLabel(Object value);

  /// No description provided for @uptimeTimestampLabel.
  ///
  /// In en, this message translates to:
  /// **'Uptime timestamp: {value}'**
  String uptimeTimestampLabel(Object value);

  /// No description provided for @lastUpdatedBackendLabel.
  ///
  /// In en, this message translates to:
  /// **'Last updated (backend): {value}'**
  String lastUpdatedBackendLabel(Object value);

  /// No description provided for @valveOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get valveOn;

  /// No description provided for @valveOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get valveOff;

  /// No description provided for @unknownState.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownState;

  /// No description provided for @missingLabel.
  ///
  /// In en, this message translates to:
  /// **'(missing)'**
  String get missingLabel;

  /// No description provided for @statusCannotReachBackendTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach Backend'**
  String get statusCannotReachBackendTitle;

  /// No description provided for @statusCannotReachBackendSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Base URL: {baseUrl}\n{error}'**
  String statusCannotReachBackendSubtitle(Object baseUrl, Object error);

  /// No description provided for @statusBackendCannotReachMqttTitle.
  ///
  /// In en, this message translates to:
  /// **'Backend cannot reach MQTT broker'**
  String get statusBackendCannotReachMqttTitle;

  /// No description provided for @statusBackendCannotReachMqttSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Base URL: {baseUrl}\nCheck broker / network. Device commands may fail (503).'**
  String statusBackendCannotReachMqttSubtitle(Object baseUrl);

  /// No description provided for @statusDeviceNotReportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Device not reporting state'**
  String get statusDeviceNotReportingTitle;

  /// No description provided for @statusDeviceNotReportingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Base URL: {baseUrl}\nLast state age: {ageLabel}. Check ESP32 power/Wi‑Fi/MQTT topics.'**
  String statusDeviceNotReportingSubtitle(Object baseUrl, Object ageLabel);

  /// No description provided for @statusAllSystemsOkTitle.
  ///
  /// In en, this message translates to:
  /// **'All systems OK'**
  String get statusAllSystemsOkTitle;

  /// No description provided for @statusAllSystemsOkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Base URL: {baseUrl}\nBackend reachable. MQTT connected. Device state is fresh.'**
  String statusAllSystemsOkSubtitle(Object baseUrl);

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @backendBaseUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Backend base URL'**
  String get backendBaseUrlLabel;

  /// No description provided for @backendBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'http://192.168.1.10:8000'**
  String get backendBaseUrlHint;

  /// No description provided for @ezvizAccessTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'EZVIZ access token'**
  String get ezvizAccessTokenLabel;

  /// No description provided for @ezvizAccessTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Paste token from EZVIZ OpenAPI / console'**
  String get ezvizAccessTokenHint;

  /// No description provided for @ezvizAccessTokenHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the token from build (--dart-define), if configured.'**
  String get ezvizAccessTokenHelper;

  /// No description provided for @technicalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Technical info'**
  String get technicalInfoTitle;

  /// No description provided for @deviceLabel.
  ///
  /// In en, this message translates to:
  /// **'Device: {deviceId}'**
  String deviceLabel(Object deviceId);

  /// No description provided for @backendToMqttLabel.
  ///
  /// In en, this message translates to:
  /// **'Backend→MQTT: {value}'**
  String backendToMqttLabel(Object value);

  /// No description provided for @connectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connectedLabel;

  /// No description provided for @disconnectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnectedLabel;

  /// No description provided for @unknownLabel.
  ///
  /// In en, this message translates to:
  /// **'-'**
  String get unknownLabel;

  /// No description provided for @stateAgeLabel.
  ///
  /// In en, this message translates to:
  /// **'State age: {value}'**
  String stateAgeLabel(Object value);

  /// No description provided for @staleLabel.
  ///
  /// In en, this message translates to:
  /// **'Stale: {value}'**
  String staleLabel(Object value);

  /// No description provided for @yesLabel.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesLabel;

  /// No description provided for @noLabel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noLabel;

  /// No description provided for @expandTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get expandTitle;

  /// No description provided for @automationSoon.
  ///
  /// In en, this message translates to:
  /// **'Automation (coming soon)'**
  String get automationSoon;

  /// No description provided for @notificationsSoon.
  ///
  /// In en, this message translates to:
  /// **'Notifications (coming soon)'**
  String get notificationsSoon;

  /// No description provided for @ezvizCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'EZVIZ Camera'**
  String get ezvizCameraTitle;

  /// No description provided for @ptzStartFailed.
  ///
  /// In en, this message translates to:
  /// **'PTZ start failed: {message}'**
  String ptzStartFailed(Object message);

  /// No description provided for @ptzError.
  ///
  /// In en, this message translates to:
  /// **'PTZ error: {message}'**
  String ptzError(Object message);

  /// No description provided for @startCamera.
  ///
  /// In en, this message translates to:
  /// **'Start camera'**
  String get startCamera;

  /// No description provided for @cameraPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get cameraPausedLabel;

  /// No description provided for @ezvizNotSupportedWeb.
  ///
  /// In en, this message translates to:
  /// **'EZVIZ view is not supported on Web'**
  String get ezvizNotSupportedWeb;

  /// No description provided for @ezvizOnlyAndroidIos.
  ///
  /// In en, this message translates to:
  /// **'EZVIZ view is only supported on Android/iOS'**
  String get ezvizOnlyAndroidIos;

  /// No description provided for @stopTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopTooltip;

  /// No description provided for @missingAccessTokenBanner.
  ///
  /// In en, this message translates to:
  /// **'No EZVIZ token: open Settings and paste access token (or build with --dart-define=EZVIZ_ACCESS_TOKEN=...).'**
  String get missingAccessTokenBanner;

  /// No description provided for @cameraSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source: {value}'**
  String cameraSourceLabel(Object value);

  /// No description provided for @cameraApiAuthLabel.
  ///
  /// In en, this message translates to:
  /// **'API: {apiUrl}   AUTH: {authUrl}'**
  String cameraApiAuthLabel(Object apiUrl, Object authUrl);

  /// No description provided for @cameraAppKeyTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'AppKey: {appKeyPrefix}…   Token: {tokenPrefix}'**
  String cameraAppKeyTokenLabel(Object appKeyPrefix, Object tokenPrefix);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
