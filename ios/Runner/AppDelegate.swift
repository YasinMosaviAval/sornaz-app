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
    analysisAudio = AnalysisAudio(messenger: registrar(forPlugin: "AnalysisAudio")!.messenger())
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
