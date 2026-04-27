import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final saved = _prefs!.getString(_prefsKeyBackendBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      backendBaseUrl.value = saved.trim();
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

