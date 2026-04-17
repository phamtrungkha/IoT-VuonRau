import 'package:flutter/material.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

import '../api/backend_api.dart';
import '../api/dtos.dart';
import '../app/app_config.dart';

class DeviceDetailsPage extends StatefulWidget {
  const DeviceDetailsPage({super.key});

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  static const _api = BackendApi();

  bool _loading = false;
  String? _error;
  DeviceCapabilitiesDto? _cap;
  DeviceStateDto? _state;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cap = await _api.getCapabilities(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
      );
      final st = await _api.getDeviceState(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
      );
      setState(() {
        _cap = cap;
        _state = st;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cap = _cap;
    final st = _state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device details'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.deviceLabel(AppConfig.deviceId),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text('Base URL: ${AppConfig.backendBaseUrl.value}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Capabilities', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Actuators: ${cap?.actuators.join(", ") ?? "-"}'),
                  Text('Sensors: ${cap?.sensors.join(", ") ?? "-"}'),
                  Text('Settings: ${cap?.settingsPrefixes.join(", ") ?? "-"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Readings', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (st == null) const Text('-'),
                  if (st != null)
                    ...st.readings.entries.map((e) {
                      final ts = st.readingsUpdatedAt[e.key];
                      final tsLabel = ts == null || ts <= 0
                          ? '-'
                          : DateTime.fromMillisecondsSinceEpoch((ts * 1000).round())
                              .toLocal()
                              .toString();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('${e.key}: ${e.value} (updated: $tsLabel)'),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Outputs', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (st == null) const Text('-'),
                  if (st != null && st.outputs.isEmpty) const Text('(none)'),
                  if (st != null)
                    ...st.outputs.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${e.key}: ${e.value}'),
                        )),
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
      ),
    );
  }
}

