package com.vuonrau.vuonrau

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import com.vuonrau.vuonrau.ezviz.EzvizPlayerViewFactory
import com.vuonrau.vuonrau.ezviz.EzvizPtzMethodChannel

class MainActivity : FlutterActivity() {
  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    flutterEngine
      .platformViewsController
      .registry
      .registerViewFactory("ezviz_player_view", EzvizPlayerViewFactory())

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ezviz_player").setMethodCallHandler(
      EzvizPtzMethodChannel(context = this)
    )
  }
}
