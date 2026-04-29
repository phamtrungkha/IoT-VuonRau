import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

import '../api/backend_api.dart';
import '../app/app_config.dart';
import '../ezviz/ezviz_camera_screen.dart';
import '../ezviz/ezviz_camera_view.dart';
import '../ezviz/ezviz_config.dart';
import '../ezviz/ezviz_ptz.dart';
import 'settings_page.dart';
import 'device_details_page.dart';
import 'device_history_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const _api = BackendApi();

  final _ptz = EzvizPtzController();
  final _zoomController = TransformationController();
  EzvizPtzCommand? _activeCommand;
  bool _ptzExpanded = false;
  bool _cameraPaused = false;

  bool _loading = false;
  bool? _waterValve;
  int? _humidityRaw;
  DateTime? _lastHumidityUpdatedAt;
  String? _error;
  Timer? _autoOffTimer;
  int? _remainingSeconds;

  @override
  void initState() {
    super.initState();
    AppConfig.backendBaseUrl.addListener(_onBackendBaseUrlChanged);
    _refreshSettings();
    _refreshState();
  }

  @override
  void dispose() {
    AppConfig.backendBaseUrl.removeListener(_onBackendBaseUrlChanged);
    _autoOffTimer?.cancel();
    _zoomController.dispose();
    super.dispose();
  }

  void _onBackendBaseUrlChanged() {
    if (!mounted) return;
    _refreshSettings();
    _refreshState();
  }

  Future<void> _refreshSettings() async {
    try {
      final settings = await _api.getDeviceSettings(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
      );
      AppConfig.autoOffSeconds.value =
          settings.getInt('irrigation.auto_off_seconds', 30);
      AppConfig.moistureThresholdRaw.value =
          settings.getInt('irrigation.moisture_threshold_raw', 2000);
      if (mounted) setState(() {});
    } catch (_) {
      // Ignore settings failures here; Settings page has explicit UX for errors.
    }
  }

  void _stopCountdown() {
    _autoOffTimer?.cancel();
    _autoOffTimer = null;
    _remainingSeconds = null;
  }

  void _startCountdown(int seconds) {
    if (seconds <= 0) {
      _stopCountdown();
      return;
    }
    _stopCountdown();
    _remainingSeconds = seconds;
    _autoOffTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      if (_waterValve != true) {
        _stopCountdown();
        if (mounted) setState(() {});
        return;
      }

      final next = (_remainingSeconds ?? 0) - 1;
      _remainingSeconds = next;
      setState(() {});
      if (next <= 0) {
        _stopCountdown();
        setState(() {});
        await _setWaterValve(false);
      }
    });
    setState(() {});
  }

  Future<void> _refreshState() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dto = await _api.getDeviceState(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
      );
      setState(() {
        _waterValve = dto.waterValve;
        _humidityRaw = dto.humidityRaw;
        _lastHumidityUpdatedAt = dto.humidityUpdatedAtEpochS <= 0
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (dto.humidityUpdatedAtEpochS * 1000).round(),
              );
      });
      if (dto.waterValve == true) {
        _startCountdown(AppConfig.autoOffSeconds.value);
      } else {
        _stopCountdown();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _setWaterValve(bool value) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.setWaterValve(
        baseUrl: AppConfig.backendBaseUrl.value,
        deviceId: AppConfig.deviceId,
        value: value,
      );
      await _refreshState();
      if (value) {
        _startCountdown(AppConfig.autoOffSeconds.value);
      } else {
        _stopCountdown();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _ptzStart({required EzvizPtzCommand command, int speed = 2}) async {
    try {
      _activeCommand = command;
      await _ptz.ptzStart(
        ezopenUrl: EzvizConfig.ezopenUrl,
        command: command,
        speed: speed,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _formatPtzErrorMessage(e);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ptzError(msg))),
      );
      rethrow;
    }
  }

  String _formatPtzErrorMessage(Object e) {
    if (e is PlatformException) {
      // iOS Ezviz OpenSDK: when PTZ hits the hardware limit, it can throw:
      // - code: "ptz_error"
      // - details: 16000x
      // - message: "error.opensdk.ys7.com 160003: https error code = 60003"
      final details = e.details;
      final isLimit = details == 160002 ||
          details == 160003 ||
          details == 160004 ||
          details == 160005;
      if (e.code == 'ptz_error' && isLimit) {
        return 'Camera đã tới giới hạn quay/tilt, không thể quay thêm theo hướng này.';
      }
      // Fallback: keep original for debugging.
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  Future<void> _ptzStop({EzvizPtzCommand? command}) async {
    final cmd = command ?? _activeCommand;
    if (cmd == null) return;
    try {
      await _ptz.ptzStop(ezopenUrl: EzvizConfig.ezopenUrl, command: cmd);
    } catch (_) {
      // Ignore stop failures.
    } finally {
      if (_activeCommand == cmd) _activeCommand = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final humidityLabel = _humidityRaw == null ? '-' : _humidityRaw.toString();
    final updatedAtLabel = _lastHumidityUpdatedAt == null
        ? '-'
        : _lastHumidityUpdatedAt!.toLocal().toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [
          IconButton(
            tooltip: l10n.deviceInfoTooltip,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DeviceDetailsPage()),
              );
              if (!mounted) return;
              await _refreshState();
            },
            icon: const Icon(Icons.info_outline),
          ),
          IconButton(
            tooltip: l10n.settingsTooltip,
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
              );
              if (!mounted) return;
              await _refreshSettings();
              await _refreshState();
            },
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            tooltip: l10n.fullscreenCameraTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EzvizCameraScreen(),
                ),
              );
            },
            icon: const Icon(Icons.fullscreen),
          ),
          IconButton(
            onPressed: _loading ? null : _refreshState,
            tooltip: l10n.refreshTooltip,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: InteractiveViewer(
                        transformationController: _zoomController,
                        minScale: 1,
                        maxScale: 4,
                        panEnabled: true,
                        scaleEnabled: true,
                        child: ValueListenableBuilder<String>(
                          valueListenable: AppConfig.ezvizAccessTokenOverride,
                          builder: (context, _, __) {
                            return EzvizCameraView(
                              appKey: EzvizConfig.appKey,
                              accessToken: AppConfig.ezvizAccessTokenEffective,
                              ezopenUrl: EzvizConfig.ezopenUrl,
                              apiUrl: EzvizConfig.apiUrl,
                              authUrl: EzvizConfig.authUrl,
                              paused: _cameraPaused,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 160),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _ptzExpanded
                                ? Transform.scale(
                                    key: const ValueKey('ptzPad'),
                                    alignment: Alignment.bottomRight,
                                    scale: 0.78,
                                    child: EzvizPtzPad(
                                      onUpStart: () =>
                                          _ptzStart(command: EzvizPtzCommand.up),
                                      onUpStop: () =>
                                          _ptzStop(command: EzvizPtzCommand.up),
                                      onDownStart: () => _ptzStart(
                                        command: EzvizPtzCommand.down,
                                      ),
                                      onDownStop: () =>
                                          _ptzStop(command: EzvizPtzCommand.down),
                                      onLeftStart: () =>
                                          _ptzStart(command: EzvizPtzCommand.left),
                                      onLeftStop: () =>
                                          _ptzStop(command: EzvizPtzCommand.left),
                                      onRightStart: () => _ptzStart(
                                        command: EzvizPtzCommand.right,
                                      ),
                                      onRightStop: () =>
                                          _ptzStop(command: EzvizPtzCommand.right),
                                      onStop: _ptzStop,
                                    ),
                                  )
                                : const SizedBox(key: ValueKey('ptzPadEmpty')),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'cameraPauseDashboard',
                                backgroundColor: Colors.black.withAlpha(160),
                                foregroundColor: Colors.white,
                                onPressed: () async {
                                  final nextPaused = !_cameraPaused;
                                  setState(() {
                                    _cameraPaused = nextPaused;
                                    if (nextPaused) _ptzExpanded = false;
                                  });
                                  if (nextPaused) await _ptzStop();
                                },
                                child: Icon(
                                  _cameraPaused ? Icons.play_arrow : Icons.pause,
                                ),
                              ),
                              const SizedBox(width: 8),
                              FloatingActionButton.small(
                                heroTag: 'ptzToggleDashboard',
                                backgroundColor: Colors.black.withAlpha(160),
                                foregroundColor: Colors.white,
                                onPressed: () => setState(() {
                                  _ptzExpanded = !_ptzExpanded;
                                }),
                                child: Icon(
                                  _ptzExpanded ? Icons.close : Icons.control_camera,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    l10n.waterValveSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ValueListenableBuilder(
                    valueListenable: AppConfig.moistureThresholdRaw,
                    builder: (context, threshold, _) {
                      final h = _humidityRaw;
                      final isDry = h != null && h > threshold;
                      final style = isDry
                          ? TextStyle(color: Theme.of(context).colorScheme.error)
                          : null;
                      return Text(
                        l10n.humidityRawLabel(humidityLabel),
                        style: style,
                      );
                    },
                  ),
                  Text(l10n.lastUpdatedLabel(updatedAtLabel)),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.waterValveSwitchLabel),
                    value: _waterValve ?? false,
                    onChanged:
                        (_waterValve == null || _loading) ? null : _setWaterValve,
                  ),
                  if (_waterValve == true && _remainingSeconds != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Auto-off in ${_remainingSeconds}s',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (_waterValve == null)
                    Text(l10n.pressRefreshHint),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DeviceHistoryPage(),
                          ),
                        );
                      },
                      child: Text(l10n.historyDetailButton),
                    ),
                  ),
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

