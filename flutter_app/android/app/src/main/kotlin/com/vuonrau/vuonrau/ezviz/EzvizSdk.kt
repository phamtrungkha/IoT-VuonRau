package com.vuonrau.vuonrau.ezviz

import android.app.Application
import com.videogo.openapi.EZOpenSDK
import java.net.URI

object EzvizSdk {
  @Volatile private var initialized = false
  private val lock = Any()

  private fun normalizeBaseUrl(raw: String?): String? {
    if (raw.isNullOrBlank()) return null
    return try {
      val uri = URI(raw)
      val scheme = uri.scheme ?: return raw
      val host = uri.host ?: return raw
      "$scheme://$host"
    } catch (_: Throwable) {
      raw
    }
  }

  fun initIfNeeded(
    application: Application,
    appKey: String,
    accessToken: String?,
    apiUrl: String?,
    authUrl: String?,
  ) {
    if (!initialized) {
      synchronized(lock) {
        if (!initialized) {
          // Must be before initLib.
          EZOpenSDK.showSDKLog(false)
          EZOpenSDK.enableP2P(true)
          EZOpenSDK.initLib(application, appKey)
          initialized = true
        }
      }
    }

    if (!accessToken.isNullOrBlank()) {
      EZOpenSDK.getInstance().setAccessToken(accessToken)
    }

    val normApiUrl = normalizeBaseUrl(apiUrl)
    val normAuthUrl = normalizeBaseUrl(authUrl)
    if (!normApiUrl.isNullOrBlank() && !normAuthUrl.isNullOrBlank()) {
      EZOpenSDK.getInstance().setServerUrl(normApiUrl, normAuthUrl)
    }
  }
}

