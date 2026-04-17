import Foundation

final class EzvizSdk {
  static let shared = EzvizSdk()
  private init() {}

  private var initialized = false
  private var initializedWithCustomServer = false
  private var lastApiUrl: String?
  private var lastAuthUrl: String?

  private func normalizeBaseUrl(_ raw: String) -> String {
    guard let u = URL(string: raw), let scheme = u.scheme, let host = u.host else {
      return raw
    }
    // EZOpenSDK expects base host, it will append API paths internally.
    return "\(scheme)://\(host)"
  }

  func initIfNeeded(appKey: String, accessToken: String?, apiUrl: String?, authUrl: String?) {
    guard !appKey.isEmpty else { return }
    let wantCustom = (apiUrl?.isEmpty == false) && (authUrl?.isEmpty == false)
    let normApiUrl = apiUrl.map(normalizeBaseUrl)
    let normAuthUrl = authUrl.map(normalizeBaseUrl)

    // If we already initialized with default server but later user provides custom server,
    // we must re-init, otherwise the SDK keeps using the default CN endpoints.
    if initialized && wantCustom && !initializedWithCustomServer {
      _ = EZOpenSDK.destoryLib()
      initialized = false
    }

    if !initialized {
      // Must be called before init.
      EZOpenSDK.setDebugLogEnable(false)
      if wantCustom, let apiUrl = normApiUrl, let authUrl = normAuthUrl {
        lastApiUrl = apiUrl
        lastAuthUrl = authUrl
        initialized = EZOpenSDK.initLib(withAppKey: appKey, url: apiUrl, authUrl: authUrl)
        initializedWithCustomServer = initialized
      } else {
        lastApiUrl = nil
        lastAuthUrl = nil
        initialized = EZOpenSDK.initLib(withAppKey: appKey)
        initializedWithCustomServer = false
      }
    } else if wantCustom {
      // Keep for debugging.
      lastApiUrl = normApiUrl
      lastAuthUrl = normAuthUrl
    }
    if let token = accessToken, !token.isEmpty {
      EZOpenSDK.setAccessToken(token)
    }
  }
}

