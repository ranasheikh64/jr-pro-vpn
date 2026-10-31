import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Modern compact desktop VPN window size
    let defaultSize = NSSize(width: 420, height: 750)
    let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let originX = screenRect.origin.x + (screenRect.width - defaultSize.width) / 2
    let originY = screenRect.origin.y + (screenRect.height - defaultSize.height) / 2
    let initialFrame = NSRect(x: originX, y: originY, width: defaultSize.width, height: defaultSize.height)

    self.setFrame(initialFrame, display: true)
    self.minSize = NSSize(width: 380, height: 680)
    self.title = "JRonix VPN"

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
