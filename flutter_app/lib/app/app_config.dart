import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ezviz/ezviz_config.dart';

class AppConfig {
  AppConfig._();

  static const deviceId = 'water_controller';

  /// Google Apps Script Web App URL (endpoint độc lập để lấy public IP).
  ///
  /// Ví dụ:
  /// `https://script.google.com/macros/s/<DEPLOYMENT_ID>/exec`
  static const publicIpEndpoint =
      'https://script.google.com/macros/s/AKfycbyCWLppAfCVZ3Uk65mXO2yaJWU69N39f8v__pVvpvchvaA-Eadd8SyIhe601NB4CtrDIw/exec';

  /// Shared secret `key` để GET/POST lên GAS.
  static const publicIpKey = 'vuonrauiotip';

  /// Port mặc định nếu baseUrl hiện tại không có `:PORT`.
  static const defaultBackendPort = 8000;

  static const _prefsKeyBackendBaseUrl = 'app.backendBaseUrl';
  static const _prefsKeyEzvizAccessToken = 'app.ezvizAccessToken';

  static SharedPreferences? _prefs;

  /// Token nhập trong Cài đặt. Chuỗi rỗng = không ghi đè, dùng [ezvizAccessTokenEffective].
  static final ezvizAccessTokenOverride = ValueNotifier<String>('');

  static String get ezvizAccessTokenEffective {
    final saved = ezvizAccessTokenOverride.value.trim();
    if (saved.isNotEmpty) return saved;
    return EzvizConfig.accessTokenFromEnvironment;
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString(_prefsKeyBackendBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      backendBaseUrl.value = saved.trim();
    }
    final ezvizSaved = _prefs!.getString(_prefsKeyEzvizAccessToken);
    if (ezvizSaved != null && ezvizSaved.trim().isNotEmpty) {
      ezvizAccessTokenOverride.value = ezvizSaved.trim();
    }
  }

  /// Lưu token EZVIZ. Truyền chuỗi rỗng để xoá và quay về `--dart-define` (nếu có).
  static Future<void> setEzvizAccessToken(String value) async {
    final next = value.trim();
    ezvizAccessTokenOverride.value = next;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    if (next.isEmpty) {
      await prefs.remove(_prefsKeyEzvizAccessToken);
    } else {
      await prefs.setString(_prefsKeyEzvizAccessToken, next);
    }
  }

  static final backendBaseUrl = ValueNotifier<String>('http://192.168.1.92:8000');

  static Future<void> setBackendBaseUrl(String value) async {
    final next = value.trim();
    if (next.isEmpty) return;
    backendBaseUrl.value = next;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString(_prefsKeyBackendBaseUrl, next);
  }

  /// Backend-stored settings (cached in-memory).
  static final autoOffSeconds = ValueNotifier<int>(30);
  static final moistureThresholdRaw = ValueNotifier<int>(2000);
}

