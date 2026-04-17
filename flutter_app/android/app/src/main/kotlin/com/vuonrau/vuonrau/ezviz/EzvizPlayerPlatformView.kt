package com.vuonrau.vuonrau.ezviz

import android.app.Application
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.SurfaceHolder
import android.view.SurfaceView
import android.view.View
import android.widget.FrameLayout
import com.videogo.openapi.EZConstants
import com.videogo.openapi.EZOpenSDK
import com.videogo.openapi.EZPlayer
import io.flutter.plugin.platform.PlatformView

class EzvizPlayerPlatformView(
  private val context: Context,
  private val params: Map<String, Any?>,
) : PlatformView, SurfaceHolder.Callback {

  private val tag = "EzvizPlayerPlatformView"
  private val container: FrameLayout = FrameLayout(context)
  private val surfaceView: SurfaceView = SurfaceView(context)
  private var player: EZPlayer? = null
  private var holder: SurfaceHolder? = null

  private val appKey: String = (params["appKey"] as? String) ?: ""
  private val accessToken: String? = params["accessToken"] as? String
  private val deviceSerial: String = (params["deviceSerial"] as? String) ?: ""
  private val channelNo: Int = (params["channelNo"] as? Int) ?: 1
  private val isHd: Boolean = (params["isHd"] as? Boolean) ?: false
  private val apiUrl: String? = params["apiUrl"] as? String
  private val authUrl: String? = params["authUrl"] as? String

  init {
    container.addView(
      surfaceView,
      FrameLayout.LayoutParams(
        FrameLayout.LayoutParams.MATCH_PARENT,
        FrameLayout.LayoutParams.MATCH_PARENT,
      ),
    )
    surfaceView.holder.addCallback(this)
  }

  override fun getView(): View = container

  override fun dispose() {
    surfaceView.holder.removeCallback(this)
    stopAndRelease()
  }

  override fun surfaceCreated(holder: SurfaceHolder) {
    this.holder = holder
    ensurePlayerAndStart()
  }

  override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
    this.holder = holder
    player?.setSurfaceHold(holder)
  }

  override fun surfaceDestroyed(holder: SurfaceHolder) {
    player?.setSurfaceHold(null)
    this.holder = null
    stopAndRelease()
  }

  private fun ensurePlayerAndStart() {
    val h = holder ?: return
    val application = context.applicationContext as? Application ?: return

    if (appKey.isBlank() || deviceSerial.isBlank()) {
      Log.w(tag, "Missing appKey/deviceSerial. appKeyBlank=${appKey.isBlank()} deviceSerialBlank=${deviceSerial.isBlank()}")
      return
    }

    EzvizSdk.initIfNeeded(application, appKey, accessToken, apiUrl, authUrl)

    if (player == null) {
      player = EZOpenSDK.getInstance().createPlayer(deviceSerial, channelNo)
      // Surface/player callbacks (errors/messages) go through this handler.
      player?.setHandler(Handler(Looper.getMainLooper()) { msg ->
        Log.d(tag, "EZPlayer msg what=${msg.what} obj=${msg.obj}")
        false
      })
    }
    player?.setSurfaceHold(h)

    // Set video level preference before starting.
    try {
      val level =
        if (isHd) EZConstants.EZVideoLevel.VIDEO_LEVEL_HD else EZConstants.EZVideoLevel.VIDEO_LEVEL_BALANCED
      EZOpenSDK.getInstance().setVideoLevel(deviceSerial, channelNo, level.videoLevel)
    } catch (_: Throwable) {
      // Ignore if device doesn't support or SDK throws.
    }

    try {
      Log.d(tag, "startRealPlay serial=$deviceSerial ch=$channelNo hd=$isHd")
      player?.startRealPlay()
    } catch (_: Throwable) {
      // Start failure will be observable via SDK logcat; keep view alive.
    }
  }

  private fun stopAndRelease() {
    try {
      player?.stopRealPlay()
    } catch (_: Throwable) {}
    try {
      player?.release()
    } catch (_: Throwable) {}
    player = null
  }
}

