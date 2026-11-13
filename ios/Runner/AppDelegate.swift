import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var notationStorage: NotationStorage?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let infoChannel = FlutterMethodChannel(name: "sornaz/app_info", binaryMessenger: registrar(forPlugin: "AppInfo")!.messenger())
    infoChannel.setMethodCallHandler { call, result in
      if call.method == "version" {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        result("\(version) (\(build))")
      } else { result(FlutterMethodNotImplemented) }
    }
    let notationRegistrar = registrar(forPlugin: "NotationStorage")!
    notationStorage = NotationStorage(messenger: notationRegistrar.messenger(), assetKey: { notationRegistrar.lookupKey(forAsset: $0) })
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
