import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "EzvizPlayerView") {
      registrar.register(EzvizPlayerViewFactory(), withId: "ezviz_player_view")
    }
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "ezviz_player",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "bad_args", message: "Expected map args", details: nil))
          return
        }
        let deviceSerial = args["deviceSerial"] as? String ?? ""
        let channelNo = args["channelNo"] as? Int ?? 1
        let commandStr = args["command"] as? String ?? ""
        let speed = args["speed"] as? Int ?? 2

        func mapCommand(_ s: String) -> EZPTZCommand? {
          switch s {
          case "up": return .up
          case "down": return .down
          case "left": return .left
          case "right": return .right
          default: return nil
          }
        }

        guard let cmd = mapCommand(commandStr) else {
          result(FlutterError(code: "bad_command", message: "Unknown command: \(commandStr)", details: nil))
          return
        }

        let action: EZPTZAction
        switch call.method {
        case "ptzStart": action = .start
        case "ptzStop": action = .stop
        default:
          result(FlutterMethodNotImplemented)
          return
        }

        _ = EZOpenSDK.controlPTZ(
          deviceSerial,
          cameraNo: channelNo,
          command: cmd,
          action: action,
          speed: speed
        ) { error in
          if let error {
            let nsErr = error as NSError
            result(
              FlutterError(
                code: "ptz_error",
                message: "\(nsErr.domain) \(nsErr.code): \(nsErr.localizedDescription)",
                details: nsErr.code
              )
            )
          } else {
            result(nil)
          }
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
