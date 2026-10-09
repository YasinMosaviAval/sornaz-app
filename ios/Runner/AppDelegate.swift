import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var analysisAudio: AnalysisAudio?
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
    analysisAudio = AnalysisAudio(messenger: registrar(forPlugin: "AnalysisAudio")!.messenger())
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
