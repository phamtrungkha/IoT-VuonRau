package com.vuonrau.vuonrau.ezviz

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class EzvizPtzMethodChannel(private val context: Context) : MethodChannel.MethodCallHandler {
  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "ptzStart" -> {
        handlePtz(call, action = "start", result = result)
      }
      "ptzStop" -> {
        handlePtz(call, action = "stop", result = result)
      }
      else -> result.notImplemented()
    }
  }

  private fun handlePtz(call: MethodCall, action: String, result: MethodChannel.Result) {
    val args = call.arguments as? Map<*, *> ?: run {
      result.error("bad_args", "Expected map args", null)
      return
    }
    val deviceSerial = args["deviceSerial"] as? String ?: ""
    val channelNo = (args["channelNo"] as? Number)?.toInt() ?: 1
    val commandStr = args["command"] as? String ?: ""
    val speed = (args["speed"] as? Number)?.toInt() ?: 2

    val cmd = when (commandStr) {
      "up" -> com.videogo.openapi.EZConstants.EZPTZCommand.EZPTZCommandUp
      "down" -> com.videogo.openapi.EZConstants.EZPTZCommand.EZPTZCommandDown
      "left" -> com.videogo.openapi.EZConstants.EZPTZCommand.EZPTZCommandLeft
      "right" -> com.videogo.openapi.EZConstants.EZPTZCommand.EZPTZCommandRight
      else -> null
    } ?: run {
      result.error("bad_command", "Unknown command: $commandStr", null)
      return
    }

    val act =
      if (action == "start") com.videogo.openapi.EZConstants.EZPTZAction.EZPTZActionSTART
      else com.videogo.openapi.EZConstants.EZPTZAction.EZPTZActionSTOP

    try {
      val ok =
        com.videogo.openapi.EZOpenSDK.getInstance().controlPTZ(deviceSerial, channelNo, cmd, act, speed)
      if (ok) result.success(null) else result.error("ptz_failed", "controlPTZ returned false", null)
    } catch (t: Throwable) {
      result.error("ptz_exception", t.message ?: "PTZ exception", null)
    }
  }
}

