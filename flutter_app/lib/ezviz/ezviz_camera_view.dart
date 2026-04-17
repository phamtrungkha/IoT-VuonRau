import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vuonrau/l10n/app_localizations.dart';

class EzvizParsedEzopenUrl {
  final String deviceSerial;
  final int channelNo;
  final bool isHd;
  const EzvizParsedEzopenUrl({
    required this.deviceSerial,
    required this.channelNo,
    required this.isHd,
  });
}

EzvizParsedEzopenUrl parseEzopenUrl(String ezopenUrl) {
  // Expected:
  // - ezopen://open.ezviz.com/BH1541592/1.hd.live
  // - ezopen://open.ezviz.com/BH1541592/1.live
  final uri = Uri.parse(ezopenUrl);
  if (uri.scheme != 'ezopen') {
    throw FormatException('Unsupported scheme: ${uri.scheme}');
  }
  final segments = uri.pathSegments;
  if (segments.length < 2) {
    throw const FormatException('Invalid ezopen URL path');
  }
  final deviceSerial = segments[0];
  final second = segments[1]; // e.g. "1.hd.live"
  final parts = second.split('.');
  final channelNo = int.tryParse(parts.first);
  if (channelNo == null) {
    throw const FormatException('Invalid channel number in ezopen URL');
  }
  final isHd = parts.contains('hd');
  return EzvizParsedEzopenUrl(
    deviceSerial: deviceSerial,
    channelNo: channelNo,
    isHd: isHd,
  );
}

class EzvizCameraView extends StatefulWidget {
  final String appKey;
  final String accessToken;
  final String ezopenUrl;
  final String apiUrl;
  final String authUrl;
  final bool paused;

  const EzvizCameraView({
    super.key,
    required this.appKey,
    required this.accessToken,
    required this.ezopenUrl,
    required this.apiUrl,
    required this.authUrl,
    this.paused = false,
  });

  @override
  State<EzvizCameraView> createState() => _EzvizCameraViewState();
}

class _EzvizCameraViewState extends State<EzvizCameraView> {
  bool _mountPlatformView = false;

  @override
  void initState() {
    super.initState();
    // Delay platform-view creation until after first frame so route transition
    // and initial UI remain responsive even if native init is heavy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mountPlatformView = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (kIsWeb) {
      return Center(child: Text(l10n.ezvizNotSupportedWeb));
    }

    if (widget.paused) {
      return Center(
        child: Text(
          l10n.cameraPausedLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
        ),
      );
    }

    if (!_mountPlatformView) {
      return Center(
        child: FilledButton(
          onPressed: () => setState(() => _mountPlatformView = true),
          child: Text(l10n.startCamera),
        ),
      );
    }

    final parsed = parseEzopenUrl(widget.ezopenUrl);
    final params = <String, Object?>{
      'appKey': widget.appKey,
      'accessToken': widget.accessToken,
      'deviceSerial': parsed.deviceSerial,
      'channelNo': parsed.channelNo,
      'isHd': parsed.isHd,
      'apiUrl': widget.apiUrl,
      'authUrl': widget.authUrl,
    };

    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'ezviz_player_view',
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    if (Platform.isIOS) {
      return UiKitView(
        viewType: 'ezviz_player_view',
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Center(child: Text(l10n.ezvizOnlyAndroidIos));
  }
}

