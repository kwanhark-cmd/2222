import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  // 앱 안 표시 이름 → 창 제목("aico/window" setTitle)
  private var windowChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(name: "aico/window", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "setTitle", let title = call.arguments as? String {
        self?.title = title
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    windowChannel = channel

    super.awakeFromNib()
  }
}
