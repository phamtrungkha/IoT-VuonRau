import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vuonrau/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

import '../api/backend_api.dart';
import '../api/dtos.dart';
import '../app/app_config.dart';
import '../widgets/status_banner.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _api = BackendApi();

  late final TextEditingController _baseUrlController;
  late final TextEditingController _autoOffSecondsController;
  late final TextEditingController _moistureThresholdRawController;

  bool _loading = false;
  String? _error;
  bool? _mqttConnected;
  double? _lastStateAgeS;
  bool _stale = true;
  DeviceSettingsKvDto? _settings;

  bool _publicIpLoading = false;
  String? _publicIpError;
  String? _latestPublicIp;
  DateTime? _latestPublicIpAt;

  @override
  void initState() {
    super.initState();
    _baseUrlController = TextEditingController(text: AppConfig.backendBaseUrl.value);
    _autoOffSecondsController =
        TextEditingController(text: AppConfig.autoOffSeconds.value.toString());
    _moistureThresholdRawController =
        TextEditingController(text: AppConfig.moistureThresholdRaw.value.toString());
    _refreshAll();
    _refreshPublicIp();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _autoOffSecondsController.dispose();
    _moistureThresholdRawController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final status = await _api.getSystemStatus(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
      );
      final settings = await _api.getDeviceSettings(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
      );
      setState(() {
        _mqttConnected = status.mqttConnected;
        _lastStateAgeS = status.lastStateAgeS;
        _stale = status.deviceStale;
        _settings = settings;
      });
      final autoOff = settings.getInt('irrigation.auto_off_seconds', 30);
      final thr = settings.getInt('irrigation.moisture_threshold_raw', 2000);
      AppConfig.autoOffSeconds.value = autoOff;
      AppConfig.moistureThresholdRaw.value = thr;
      _autoOffSecondsController.text = autoOff.toString();
      _moistureThresholdRawController.text = thr.toString();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String _ageLabel() {
    if (_lastStateAgeS == null || _lastStateAgeS!.isInfinite) return '-';
    return '${_lastStateAgeS!.toStringAsFixed(1)}s';
  }

  Future<void> _applyBaseUrl(String value) async {
    final next = value.trim();
    if (next.isEmpty) return;
    await AppConfig.setBackendBaseUrl(next);
    await _refreshAll();
  }

  Future<void> _refreshPublicIp() async {
    setState(() {
      _publicIpLoading = true;
      _publicIpError = null;
    });

    final uri = Uri.parse(
      '${AppConfig.publicIpEndpoint}?key=${Uri.encodeQueryComponent(AppConfig.publicIpKey)}',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final ip = (data['ip'] as String?)?.trim();
      final updatedAtMs = data['updatedAt'];

      if (ip == null || ip.isEmpty) {
        throw Exception('Empty IP from GAS');
      }

      DateTime? updatedAt;
      if (updatedAtMs is num) {
        updatedAt = DateTime.fromMillisecondsSinceEpoch(updatedAtMs.toInt());
      }

      setState(() {
        _latestPublicIp = ip;
        _latestPublicIpAt = updatedAt;
      });
    } catch (e) {
      setState(() => _publicIpError = e.toString());
    } finally {
      setState(() => _publicIpLoading = false);
    }
  }

  int _inferBackendPort() {
    final raw = _baseUrlController.text.trim().isEmpty
        ? AppConfig.backendBaseUrl.value
        : _baseUrlController.text.trim();
    final withScheme = raw.contains('://') ? raw : 'http://$raw';
    final uri = Uri.tryParse(withScheme);
    if (uri != null && uri.hasPort) return uri.port;
    return AppConfig.defaultBackendPort;
  }

  String? _suggestedBaseUrl() {
    final ip = _latestPublicIp;
    if (ip == null || ip.isEmpty) return null;
    final port = _inferBackendPort();
    final host = ip.contains(':') ? '[$ip]' : ip;
    return 'http://$host:$port';
  }

  String _publicIpLabel() {
    if (_publicIpLoading) return 'Public IP: loading...';
    if (_publicIpError != null) return 'Public IP: error';
    if (_latestPublicIp == null) return 'Public IP: -';
    final at = _latestPublicIpAt;
    if (at == null) return 'Public IP: $_latestPublicIp';
    final ageS = DateTime.now().difference(at).inSeconds;
    return 'Public IP: $_latestPublicIp (${ageS}s ago)';
  }

  Future<void> _saveSettings() async {
    final autoOffSeconds = int.tryParse(_autoOffSecondsController.text.trim());
    final threshold = int.tryParse(_moistureThresholdRawController.text.trim());
    if (autoOffSeconds == null || threshold == null) {
      setState(() => _error = 'Invalid number(s).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updated = await _api.updateDeviceSettings(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
        autoOffSeconds: autoOffSeconds,
        moistureThresholdRaw: threshold,
      );
      setState(() => _settings = updated);
      final autoOff = updated.getInt('irrigation.auto_off_seconds', 30);
      final thr = updated.getInt('irrigation.moisture_threshold_raw', 2000);
      AppConfig.autoOffSeconds.value = autoOff;
      AppConfig.moistureThresholdRaw.value = thr;
      _autoOffSecondsController.text = autoOff.toString();
      _moistureThresholdRawController.text = thr.toString();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = _settings;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refreshAll,
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: AppConfig.backendBaseUrl,
        builder: (context, baseUrl, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StatusBanner(
                loading: _loading,
                error: _error,
                mqttConnected: _mqttConnected,
                deviceStale: _stale,
                lastStateAgeLabel: _ageLabel(),
                baseUrl: baseUrl,
                onRetry: _loading ? null : _refreshAll,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: l10n.backendBaseUrlLabel,
                  hintText: l10n.backendBaseUrlHint,
                  border: const OutlineInputBorder(),
                  suffixIcon: AnimatedBuilder(
                    animation: _baseUrlController,
                    builder: (context, _) {
                      if (_baseUrlController.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _baseUrlController.clear();
                        },
                      );
                    },
                  ),
                ),
                controller: _baseUrlController,
                onSubmitted: _applyBaseUrl,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        _publicIpLabel(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh public IP',
                    onPressed: _publicIpLoading ? null : _refreshPublicIp,
                    icon: const Icon(Icons.sync),
                  ),
                  IconButton(
                    tooltip: 'Apply to textbox',
                    onPressed: (_suggestedBaseUrl() == null)
                        ? null
                        : () {
                            final v = _suggestedBaseUrl();
                            if (v == null) return;
                            setState(() => _baseUrlController.text = v);
                          },
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
              if (_publicIpError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _publicIpError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Irrigation settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (settings != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Keys: irrigation.*',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Auto-off seconds',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        controller: _autoOffSecondsController,
                        enabled: !_loading,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Moisture threshold (raw)',
                          border: OutlineInputBorder(),
                          helperText:
                              'If the “dry” highlight seems inverted, adjust this threshold.',
                        ),
                        keyboardType: TextInputType.number,
                        controller: _moistureThresholdRawController,
                        enabled: !_loading,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _saveSettings,
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.technicalInfoTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.deviceLabel(AppConfig.deviceId)),
                      Text(
                        l10n.backendToMqttLabel(
                          _mqttConnected == null
                              ? l10n.unknownLabel
                              : (_mqttConnected!
                                    ? l10n.connectedLabel
                                    : l10n.disconnectedLabel),
                        ),
                      ),
                      Text(l10n.stateAgeLabel(_ageLabel())),
                      Text(l10n.staleLabel(_stale ? l10n.yesLabel : l10n.noLabel)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.expandTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.automationSoon),
                      Text(l10n.notificationsSoon),
                    ],
                  ),
                ),
              ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          );
        },
      ),
    );
  }
}

