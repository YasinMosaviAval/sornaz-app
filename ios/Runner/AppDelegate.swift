import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var analysisAudio: AnalysisAudio?
  private var notationStorage: NotationStorage?
  private var mediaServices: MediaServices?
  private var iosMetronome: IOSMetronome?
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
    notationStorage = NotationStorage(messenger: registrar(forPlugin: "NotationStorage")!.messenger())
    mediaServices = MediaServices(messenger: registrar(forPlugin: "MediaServices")!.messenger())
    let metronomeRegistrar = registrar(forPlugin: "IOSMetronome")!
    iosMetronome = IOSMetronome(messenger: metronomeRegistrar.messenger(), assetKey: { metronomeRegistrar.lookupKey(forAsset: $0) })
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
