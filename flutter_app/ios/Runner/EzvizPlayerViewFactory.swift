import Flutter
import UIKit

final class EzvizPlayerViewFactory: NSObject, FlutterPlatformViewFactory {
  func createArgsCodec() -> (any FlutterMessageCodec & NSObjectProtocol) {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    EzvizPlayerPlatformView(frame: frame, viewIdentifier: viewId, arguments: args)
  }
}

