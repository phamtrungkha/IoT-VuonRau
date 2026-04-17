import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig._();

  static const deviceId = 'water_controller';

  /// In-memory config for now. Later we can persist (e.g. shared_preferences).
  static final backendBaseUrl = ValueNotifier<String>('http://192.168.1.92:8000');

  /// Backend-stored settings (cached in-memory).
  static final autoOffSeconds = ValueNotifier<int>(30);
  static final moistureThresholdRaw = ValueNotifier<int>(2000);
}

