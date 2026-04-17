class DeviceStateDto {
  final bool? waterValve;
  final int? humidityRaw;
  final int? timestampUptimeS;
  final bool stale;
  final double updatedAtEpochS;
  final double humidityUpdatedAtEpochS;
  final Map<String, dynamic> readings;
  final Map<String, double> readingsUpdatedAt;
  final Map<String, dynamic> outputs;

  DeviceStateDto({
    required this.waterValve,
    required this.humidityRaw,
    required this.timestampUptimeS,
    required this.stale,
    required this.updatedAtEpochS,
    required this.humidityUpdatedAtEpochS,
    required this.readings,
    required this.readingsUpdatedAt,
    required this.outputs,
  });

  factory DeviceStateDto.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> readMap(String key) {
      final raw = json[key];
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return const {};
    }

    Map<String, double> readDoubleMap(String key) {
      final raw = json[key];
      if (raw is! Map) return const {};
      final out = <String, double>{};
      for (final e in raw.entries) {
        final k = e.key;
        final v = e.value;
        if (k is String && v is num) out[k] = v.toDouble();
      }
      return out;
    }

    return DeviceStateDto(
      waterValve: json['water_valve'] as bool?,
      humidityRaw: json['humidity_raw'] as int?,
      timestampUptimeS: json['timestamp'] as int?,
      stale: (json['stale'] as bool?) ?? true,
      updatedAtEpochS: (json['updated_at'] as num?)?.toDouble() ?? 0,
      humidityUpdatedAtEpochS:
          (json['humidity_updated_at'] as num?)?.toDouble() ?? 0,
      readings: readMap('readings'),
      readingsUpdatedAt: readDoubleMap('readings_updated_at'),
      outputs: readMap('outputs'),
    );
  }
}

class DeviceCapabilitiesDto {
  final String deviceId;
  final List<String> actuators;
  final List<String> sensors;
  final List<String> settingsPrefixes;

  DeviceCapabilitiesDto({
    required this.deviceId,
    required this.actuators,
    required this.sensors,
    required this.settingsPrefixes,
  });

  factory DeviceCapabilitiesDto.fromJson(Map<String, dynamic> json) {
    List<String> readStringList(String key) {
      final raw = json[key];
      if (raw is List) {
        return raw.whereType<String>().toList();
      }
      return const [];
    }

    return DeviceCapabilitiesDto(
      deviceId: (json['device_id'] as String?) ?? '',
      actuators: readStringList('actuators'),
      sensors: readStringList('sensors'),
      settingsPrefixes: readStringList('settings_prefixes'),
    );
  }
}

class SystemStatusDto {
  final bool mqttConnected;
  final double lastStateAgeS;
  final bool deviceStale;

  SystemStatusDto({
    required this.mqttConnected,
    required this.lastStateAgeS,
    required this.deviceStale,
  });

  factory SystemStatusDto.fromJson(Map<String, dynamic> json) {
    final age = json['last_state_age_s'];
    return SystemStatusDto(
      mqttConnected: (json['mqtt_connected'] as bool?) ?? false,
      lastStateAgeS: age is num ? age.toDouble() : double.infinity,
      deviceStale: (json['device_stale'] as bool?) ?? true,
    );
  }
}

class SettingValueDto {
  final String key;
  final String type;
  final Object? value;
  final double updatedAtEpochS;

  SettingValueDto({
    required this.key,
    required this.type,
    required this.value,
    required this.updatedAtEpochS,
  });

  factory SettingValueDto.fromJson(Map<String, dynamic> json) {
    return SettingValueDto(
      key: (json['key'] as String?) ?? '',
      type: (json['type'] as String?) ?? '',
      value: json['value'],
      updatedAtEpochS: (json['updated_at'] as num?)?.toDouble() ?? 0,
    );
  }
}

class DeviceSettingsKvDto {
  final String deviceId;
  final List<SettingValueDto> settings;

  DeviceSettingsKvDto({
    required this.deviceId,
    required this.settings,
  });

  factory DeviceSettingsKvDto.fromJson(Map<String, dynamic> json) {
    final raw = json['settings'];
    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          list.add(Map<String, dynamic>.from(e));
        }
      }
    }
    return DeviceSettingsKvDto(
      deviceId: (json['device_id'] as String?) ?? '',
      settings: list.map(SettingValueDto.fromJson).toList(),
    );
  }

  SettingValueDto? find(String key) {
    for (final s in settings) {
      if (s.key == key) return s;
    }
    return null;
  }

  int getInt(String key, int fallback) {
    final s = find(key);
    final v = s?.value;
    if (v is num) return v.toInt();
    return fallback;
  }
}

