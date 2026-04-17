export 'ezviz_ptz_pad.dart';

import 'package:flutter/services.dart';

import 'ezviz_camera_view.dart';

enum EzvizPtzCommand { up, down, left, right }

class EzvizPtzController {
  static const _channel = MethodChannel('ezviz_player');

  Future<void> ptzStart({
    required String ezopenUrl,
    required EzvizPtzCommand command,
    int speed = 2,
  }) async {
    final parsed = parseEzopenUrl(ezopenUrl);
    await _channel.invokeMethod<void>('ptzStart', {
      'deviceSerial': parsed.deviceSerial,
      'channelNo': parsed.channelNo,
      'command': command.name,
      'speed': speed,
    });
  }

  Future<void> ptzStop({
    required String ezopenUrl,
    required EzvizPtzCommand command,
  }) async {
    final parsed = parseEzopenUrl(ezopenUrl);
    await _channel.invokeMethod<void>('ptzStop', {
      'deviceSerial': parsed.deviceSerial,
      'channelNo': parsed.channelNo,
      'command': command.name,
    });
  }
}

