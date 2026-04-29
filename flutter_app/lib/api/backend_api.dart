import 'dart:convert';

import 'package:http/http.dart' as http;

import 'dtos.dart';

class BackendApi {
  const BackendApi();

  Exception _wrapHttpError({
    required String method,
    required Uri uri,
    required Object error,
  }) {
    return Exception('$method $uri failed. Error: $error');
  }

  Exception _wrapHttpStatus({
    required String method,
    required Uri uri,
    required int statusCode,
    required String body,
  }) {
    return Exception('$method $uri failed. HTTP $statusCode. Body: $body');
  }

  Future<DeviceStateDto> getDeviceState({
    required String baseUrl,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/state');
    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 3));
    } catch (e) {
      throw _wrapHttpError(method: 'GET', uri: uri, error: e);
    }
    if (res.statusCode != 200) {
      throw _wrapHttpStatus(
        method: 'GET',
        uri: uri,
        statusCode: res.statusCode,
        body: res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return DeviceStateDto.fromJson(data);
  }

  Future<DeviceCapabilitiesDto> getCapabilities({
    required String baseUrl,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/capabilities');
    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 3));
    } catch (e) {
      throw _wrapHttpError(method: 'GET', uri: uri, error: e);
    }
    if (res.statusCode != 200) {
      throw _wrapHttpStatus(
        method: 'GET',
        uri: uri,
        statusCode: res.statusCode,
        body: res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return DeviceCapabilitiesDto.fromJson(data);
  }

  Future<void> setWaterValve({
    required String baseUrl,
    required String deviceId,
    required bool value,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/actions');
    http.Response res;
    try {
      res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'target': 'water_valve', 'value': value}),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      throw _wrapHttpError(method: 'POST', uri: uri, error: e);
    }

    if (res.statusCode != 200 && res.statusCode != 202) {
      throw _wrapHttpStatus(
        method: 'POST',
        uri: uri,
        statusCode: res.statusCode,
        body: res.body,
      );
    }
  }

  Future<SystemStatusDto> getSystemStatus({
    required String baseUrl,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/status');
    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 3));
    } catch (e) {
      throw _wrapHttpError(method: 'GET', uri: uri, error: e);
    }
    if (res.statusCode != 200) {
      throw _wrapHttpStatus(
        method: 'GET',
        uri: uri,
        statusCode: res.statusCode,
        body: res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return SystemStatusDto.fromJson(data);
  }

  Future<DeviceSettingsKvDto> getDeviceSettings({
    required String baseUrl,
    required String deviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/settings');
    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 3));
    } catch (e) {
      throw _wrapHttpError(method: 'GET', uri: uri, error: e);
    }
    if (res.statusCode != 200) {
      throw _wrapHttpStatus(
        method: 'GET',
        uri: uri,
        statusCode: res.statusCode,
        body: res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return DeviceSettingsKvDto.fromJson(data);
  }

  Future<DeviceSettingsKvDto> updateDeviceSettings({
    required String baseUrl,
    required String deviceId,
    required int autoOffSeconds,
    required int moistureThresholdRaw,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/settings');
    http.Response res;
    try {
      res = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'patch': [
                {
                  'key': 'irrigation.auto_off_seconds',
                  'type': 'int',
                  'value': autoOffSeconds,
                },
                {
                  'key': 'irrigation.moisture_threshold_raw',
                  'type': 'int',
                  'value': moistureThresholdRaw,
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      throw _wrapHttpError(method: 'PUT', uri: uri, error: e);
    }

    if (res.statusCode != 200) {
      throw _wrapHttpStatus(
        method: 'PUT',
        uri: uri,
        statusCode: res.statusCode,
        body: res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return DeviceSettingsKvDto.fromJson(data);
  }

  Future<HistoryTimelineDto> getDeviceHistoryTimeline({
    required String baseUrl,
    required String deviceId,
    required DateTime from,
    required DateTime to,
    required bool humidity,
    required bool valve,
    required int offset,
  }) async {
    final uri = Uri.parse('$baseUrl/devices/$deviceId/history/timeline').replace(
      queryParameters: <String, String>{
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        'humidity': humidity.toString(),
        'valve': valve.toString(),
        'offset': offset.toString(),
      },
    );
    http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw _wrapHttpError(method: 'GET', uri: uri, error: e);
    }
    if (res.statusCode != 200) {
      throw _wrapHttpStatus(
        method: 'GET',
        uri: uri,
        statusCode: res.statusCode,
        body: res.body,
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return HistoryTimelineDto.fromJson(data);
  }
}

