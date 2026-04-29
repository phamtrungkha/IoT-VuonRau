import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

import '../app/app_config.dart';
import 'ezviz_config.dart';
import 'ezviz_camera_view.dart';
import 'ezviz_ptz.dart';

class EzvizCameraScreen extends StatefulWidget {
  const EzvizCameraScreen({super.key});

  @override
  State<EzvizCameraScreen> createState() => _EzvizCameraScreenState();
}

class _EzvizCameraScreenState extends State<EzvizCameraScreen> {
  final _appKey = EzvizConfig.appKey;
  final _ezopenUrl = EzvizConfig.ezopenUrl;
  final _apiUrl = EzvizConfig.apiUrl;
  final _authUrl = EzvizConfig.authUrl;

  final _ptz = EzvizPtzController();
  final _zoomController = TransformationController();
  EzvizPtzCommand? _activeCommand;
  bool _ptzExpanded = false;

  List<DeviceOrientation>? _previousOrientations;

  @override
  void initState() {
    super.initState();
    _lockLandscape();
  }

  @override
  void dispose() {
    _restoreOrientation();
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _lockLandscape() async {
    // Snapshot current preference (best-effort) and force landscape for fullscreen.
    // Note: Flutter doesn't expose a getter; we keep our own previous value.
    _previousOrientations ??= const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ];
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreOrientation() async {
    final prev = _previousOrientations;
    if (prev == null) return;
    await SystemChrome.setPreferredOrientations(prev);
  }

  Future<void> _ptzStart({
    required EzvizPtzCommand command,
    int speed = 2,
  }) async {
    try {
      _activeCommand = command;
      await _ptz.ptzStart(
        ezopenUrl: _ezopenUrl,
        command: command,
        speed: speed,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _formatPtzErrorMessage(e);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.ptzStartFailed(msg))),
      );
      rethrow;
    }
  }

  String _formatPtzErrorMessage(Object e) {
    if (e is PlatformException) {
      final details = e.details;
      final isLimit = details == 160002 ||
          details == 160003 ||
          details == 160004 ||
          details == 160005;
      if (e.code == 'ptz_error' && isLimit) {
        return 'Camera đã tới giới hạn quay/tilt, không thể quay thêm theo hướng này.';
      }
      return e.message ?? e.toString();
    }
    return e.toString();
  }

  Future<void> _ptzStop({EzvizPtzCommand? command}) async {
    final cmd = command ?? _activeCommand;
    if (cmd == null) return;
    try {
      await _ptz.ptzStop(ezopenUrl: _ezopenUrl, command: cmd);
    } catch (_) {
      // Ignore stop failures.
    } finally {
      if (_activeCommand == cmd) _activeCommand = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<String>(
      valueListenable: AppConfig.ezvizAccessTokenOverride,
      builder: (context, _, __) {
        final token = AppConfig.ezvizAccessTokenEffective;
        final tokenMissing = token.trim().isEmpty;
        return _buildScaffold(context, l10n, tokenMissing, token);
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    AppLocalizations l10n,
    bool tokenMissing,
    String accessToken,
  ) {
    return Scaffold(
      body: ColoredBox(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  if (tokenMissing)
                    MaterialBanner(
                      content: Text(l10n.missingAccessTokenBanner),
                      actions: const [],
                    ),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: InteractiveViewer(
                                transformationController: _zoomController,
                                minScale: 1,
                                maxScale: 4,
                                panEnabled: true,
                                scaleEnabled: true,
                                child: EzvizCameraView(
                                  appKey: _appKey,
                                  accessToken: accessToken,
                                  ezopenUrl: _ezopenUrl,
                                  apiUrl: _apiUrl,
                                  authUrl: _authUrl,
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
                                        ? EzvizPtzPad(
                                            key: const ValueKey('ptzPad'),
                                            onUpStart: () => _ptzStart(
                                              command: EzvizPtzCommand.up,
                                            ),
                                            onUpStop: () => _ptzStop(
                                              command: EzvizPtzCommand.up,
                                            ),
                                            onDownStart: () => _ptzStart(
                                              command: EzvizPtzCommand.down,
                                            ),
                                            onDownStop: () => _ptzStop(
                                              command: EzvizPtzCommand.down,
                                            ),
                                            onLeftStart: () => _ptzStart(
                                              command: EzvizPtzCommand.left,
                                            ),
                                            onLeftStop: () => _ptzStop(
                                              command: EzvizPtzCommand.left,
                                            ),
                                            onRightStart: () => _ptzStart(
                                              command: EzvizPtzCommand.right,
                                            ),
                                            onRightStop: () => _ptzStop(
                                              command: EzvizPtzCommand.right,
                                            ),
                                            onStop: _ptzStop,
                                          )
                                        : const SizedBox(
                                            key: ValueKey('ptzPadEmpty'),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  FloatingActionButton.small(
                                    heroTag: 'ptzToggleFullscreen',
                                    backgroundColor: Colors.black.withAlpha(160),
                                    foregroundColor: Colors.white,
                                    onPressed: () => setState(() {
                                      _ptzExpanded = !_ptzExpanded;
                                    }),
                                    child: Icon(
                                      _ptzExpanded
                                          ? Icons.close
                                          : Icons.control_camera,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  color: Colors.white,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withAlpha(140),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

