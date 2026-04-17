import Flutter
import UIKit

final class EzvizPlayerPlatformView: NSObject, FlutterPlatformView, EZPlayerDelegate {
  private let containerView: UIView
  private var player: EZPlayer?
  private let statusLabel: UILabel

  init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) {
    self.containerView = UIView(frame: frame)
    self.containerView.backgroundColor = .black
    self.statusLabel = UILabel(frame: .zero)
    super.init()

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    statusLabel.numberOfLines = 0
    statusLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    statusLabel.textColor = UIColor.white.withAlphaComponent(0.9)
    statusLabel.backgroundColor = UIColor.black.withAlphaComponent(0.55)
    statusLabel.layer.cornerRadius = 6
    statusLabel.layer.masksToBounds = true
    statusLabel.textAlignment = .left
    statusLabel.text = "EZVIZ: initializing…"
    containerView.addSubview(statusLabel)
    NSLayoutConstraint.activate([
      statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
      statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -8),
      statusLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
    ])

    guard let dict = args as? [String: Any] else {
      statusLabel.text = "EZVIZ: missing creationParams"
      return
    }
    let appKey = dict["appKey"] as? String ?? ""
    let accessToken = dict["accessToken"] as? String
    let deviceSerial = dict["deviceSerial"] as? String ?? ""
    let channelNo = dict["channelNo"] as? Int ?? 1
    let isHd = dict["isHd"] as? Bool ?? false
    let apiUrl = dict["apiUrl"] as? String
    let authUrl = dict["authUrl"] as? String

    if deviceSerial.isEmpty {
      statusLabel.text = "EZVIZ: missing deviceSerial"
      return
    }

    statusLabel.text = "EZVIZ: init…"

    // Some SDK calls can block; keep the UI thread responsive.
    DispatchQueue.global(qos: .userInitiated).async {
      EzvizSdk.shared.initIfNeeded(
        appKey: appKey,
        accessToken: accessToken,
        apiUrl: apiUrl,
        authUrl: authUrl
      )
      let p = EZPlayer.createPlayer(withDeviceSerial: deviceSerial, cameraNo: channelNo)
      DispatchQueue.main.async {
        guard let p else {
          self.statusLabel.text = "EZVIZ: createPlayer failed"
          return
        }
        self.player = p
        p.delegate = self
        p.setHDPriority(true)
        p.setPlayerView(self.containerView)

        let level: EZVideoLevelType = isHd ? .high : .middle
        EZOpenSDK.setVideoLevel(
          deviceSerial,
          cameraNo: channelNo,
          videoLevel: level
        ) { _ in }

        let ok = p.startRealPlay()
        self.statusLabel.text = ok ? "EZVIZ: playing…" : "EZVIZ: startRealPlay=false"
      }
    }
  }

  func view() -> UIView {
    containerView
  }

  deinit {
    stopAndDestroy()
  }

  private func stopAndDestroy() {
    if let p = player {
      _ = p.stopRealPlay()
      _ = p.destoryPlayer()
    }
    player = nil
  }

  // MARK: - EZPlayerDelegate
  func player(_ player: EZPlayer!, didPlayFailed error: Error!) {
    let nsErr = error as NSError?
    let code = nsErr?.code ?? -1
    let domain = nsErr?.domain ?? "unknown"
    let msg = nsErr?.localizedDescription ?? "unknown error"
    let line = "EZVIZ: playFailed (\(domain) \(code))\n\(msg)"
    NSLog("%@", line)
    DispatchQueue.main.async {
      self.statusLabel.text = line
    }
  }
}

