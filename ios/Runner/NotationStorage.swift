import Flutter
import UIKit
import UniformTypeIdentifiers

/// Native counterpart of Android's sornaz/notation_storage channel.
final class NotationStorage: NSObject, UIDocumentPickerDelegate {
  private let channel: FlutterMethodChannel
  private let assetKey: (String) -> String
  private var pending: FlutterResult?
  private var temporaryFile: URL?
  private var choosingFolder = false

  private func selectedFolder() -> URL? {
    guard let data = UserDefaults.standard.data(forKey: "sornaz.notation.folder") else { return nil }
    var stale = false
    return try? URL(resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
  }

  init(messenger: FlutterBinaryMessenger, assetKey: @escaping (String) -> String) {
    self.assetKey = assetKey
    channel = FlutterMethodChannel(name: "sornaz/notation_storage", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func presenter() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController { controller = presented }
    return controller
  }

  private func fail(_ result: FlutterResult, _ message: String) {
    result(FlutterError(code: "NOTATION_STORAGE", message: message, details: nil))
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "sdk" { result(29); return }
    if call.method == "location" { result(selectedFolder()?.lastPathComponent ?? "Documents"); return }
    if call.method == "choose" {
      guard pending == nil, let controller = presenter() else { fail(result, "Document picker is busy."); return }
      choosingFolder = true
      pending = result
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
      picker.delegate = self
      controller.present(picker, animated: true)
      return
    }
    guard ["save", "share", "sibelius", "musicxml", "pdf"].contains(call.method) else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let arguments = call.arguments as? [String: Any],
          let content = arguments[call.method == "pdf" ? "html" : "content"] as? String,
          let controller = presenter() else {
      fail(result, "Invalid music sheet or unavailable document picker.")
      return
    }
    let limit = call.method == "pdf" ? 8_000_000 : 1_000_000
    guard content.utf8.count <= limit else { fail(result, "File is too large."); return }
    if call.method == "pdf" {
      guard UIPrintInteractionController.isPrintingAvailable else {
        fail(result, "PDF printing is unavailable.")
        return
      }
      let printController = UIPrintInteractionController.shared
      let info = UIPrintInfo(dictionary: nil)
      info.outputType = .general
      info.jobName = arguments["name"] as? String ?? "Sornaz notation"
      printController.printInfo = info
      // A standalone print formatter has no Flutter asset base URL. Embed the
      // same bundled font referenced by the score's print stylesheet.
      var printable = content
      let key = assetKey("assets/fonts/iran_sansx_fa/regular.ttf")
      if let path = Bundle.main.path(forResource: key, ofType: nil),
         let font = try? Data(contentsOf: URL(fileURLWithPath: path)) {
        printable = content.replacingOccurrences(of: "../fonts/iran_sansx_fa/regular.ttf", with: "data:font/ttf;base64," + font.base64EncodedString())
      }
      printController.printFormatter = UIMarkupTextPrintFormatter(markupText: printable)
      let shown: Bool
      if UIDevice.current.userInterfaceIdiom == .pad {
        shown = printController.present(from: CGRect(x: controller.view.bounds.midX,
                                                     y: controller.view.bounds.midY,
                                                     width: 1, height: 1),
                                        in: controller.view, animated: true, completionHandler: nil)
      } else {
        shown = printController.present(animated: true, completionHandler: nil)
      }
      if shown { result("print-dialog") }
      else { fail(result, "Could not open PDF export.") }
      return
    }
    guard pending == nil else { fail(result, "Another file export is in progress."); return }
    if call.method == "save" || call.method == "share" {
      guard let data = content.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            json["format"] as? String == "sornaz-notation" else {
        fail(result, "Invalid music sheet.")
        return
      }
    }
    let ext = ["sibelius", "musicxml"].contains(call.method) ? "musicxml" : "json"
    let proposed = (arguments["name"] as? String ?? "score") as NSString
    let stem = proposed.deletingPathExtension
      .replacingOccurrences(of: "[^\\p{L}\\p{N} _-]", with: "", options: .regularExpression)
      .prefix(80)
    let filename = (stem.isEmpty ? "score" : String(stem)) + "." + ext
    if call.method != "share", let destination = selectedFolder() {
      guard destination.startAccessingSecurityScopedResource() else { fail(result, "Selected folder access expired; select it again."); return }
      defer { destination.stopAccessingSecurityScopedResource() }
      let file = destination.appendingPathComponent(UUID().uuidString + "-" + filename)
      var coordinationError: NSError?
      var writeError: Error?
      NSFileCoordinator().coordinate(writingItemAt: file, options: [], error: &coordinationError) { url in
        do { try Data(content.utf8).write(to: url, options: .atomic) }
        catch { writeError = error }
      }
      if let error = writeError ?? coordinationError { fail(result, error.localizedDescription) }
      else { result(file.absoluteString) }
      return
    }
    let folder = FileManager.default.temporaryDirectory
      .appendingPathComponent("notation-exports", isDirectory: true)
    do {
      try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
      let file = folder.appendingPathComponent(UUID().uuidString + "-" + filename)
      try Data(content.utf8).write(to: file, options: .atomic)
      temporaryFile = file
      pending = result
      if call.method == "share" {
        let sheet = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = controller.view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: controller.view.bounds.midX,
                                                                y: controller.view.bounds.midY,
                                                                width: 1, height: 1)
        sheet.completionWithItemsHandler = { [weak self] _, completed, _, error in
          if let error = error { self?.complete(error: error.localizedDescription) }
          else if completed { self?.complete(value: "shared") }
          else { self?.complete(error: "Sharing was cancelled.") }
        }
        controller.present(sheet, animated: true)
      } else {
        let picker = UIDocumentPickerViewController(forExporting: [file], asCopy: true)
        picker.delegate = self
        controller.present(picker, animated: true)
      }
    } catch {
      temporaryFile = nil
      pending = nil
      fail(result, "Could not save the music sheet.")
    }
  }

  private func complete(value: String? = nil, error: String? = nil) {
    let callback = pending
    pending = nil
    choosingFolder = false
    if let error = error {
      callback?(FlutterError(code: "NOTATION_STORAGE", message: error, details: nil))
    } else {
      callback?(value)
    }
    if let file = temporaryFile { try? FileManager.default.removeItem(at: file) }
    temporaryFile = nil
  }

  func documentPicker(_ controller: UIDocumentPickerViewController,
                      didPickDocumentsAt urls: [URL]) {
    if choosingFolder, let destination = urls.first {
      guard destination.startAccessingSecurityScopedResource() else { complete(error: "Folder access was not granted."); return }
      defer { destination.stopAccessingSecurityScopedResource() }
      do {
        let bookmark = try destination.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
        UserDefaults.standard.set(bookmark, forKey: "sornaz.notation.folder")
        complete(value: destination.lastPathComponent)
      } catch { complete(error: error.localizedDescription) }
      return
    }
    if let destination = urls.first { complete(value: destination.absoluteString) }
    else { complete(error: "No destination was selected.") }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    complete(error: "File export was cancelled.")
  }
}
