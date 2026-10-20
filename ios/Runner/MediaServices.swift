import AVFoundation
import Flutter
import PDFKit
import Photos
import UIKit
import UniformTypeIdentifiers

/// iOS counterparts of the Android photo-library and private-document contracts.
/// Originals stay in Photos; only explicitly selected media is materialized.
final class MediaServices: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate {
  private var channels: [FlutterMethodChannel] = []
  private let worker = DispatchQueue(label: "sornaz.ios.media", qos: .userInitiated)
  private var cameraResult: FlutterResult?
  private var originalBrightness: CGFloat?
  private var workspaceResult: FlutterResult?
  private var recordingFolder: URL?

  init(messenger: FlutterBinaryMessenger) {
    super.init()
    if let bookmark = UserDefaults.standard.data(forKey: "sornaz.recording.folder") {
      var stale = false
      if let url = try? URL(resolvingBookmarkData: bookmark, options: [], relativeTo: nil, bookmarkDataIsStale: &stale),
         url.startAccessingSecurityScopedResource() { recordingFolder = url }
    }
    for name in ["sornaz/ios_media", "sornaz/private_pdf", "sornaz/video_controls", "sornaz/recording_workspace"] {
      let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handle(name, call, result)
      }
      channels.append(channel)
    }
  }

  private func reply(_ result: @escaping FlutterResult, _ value: Any?) {
    DispatchQueue.main.async { result(value) }
  }
  private func failure(_ result: @escaping FlutterResult, _ message: String) {
    reply(result, FlutterError(code: "IOS_MEDIA", message: message, details: nil))
  }
  private func presenter() -> UIViewController? {
    var controller = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }.first { $0.isKeyWindow }?.rootViewController
    while let next = controller?.presentedViewController { controller = next }
    return controller
  }
  private func localURL(_ value: String) -> URL {
    if value.hasPrefix("file:"), let url = URL(string: value) { return url }
    return URL(fileURLWithPath: value)
  }
  private func draft(_ ext: String) throws -> URL {
    let folder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("sornaz-media", isDirectory: true)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
  }
  private func authorized(_ result: @escaping FlutterResult, action: @escaping () -> Void) {
    PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
      if status == .authorized || status == .limited { action() }
      else { self.failure(result, "Photo library permission was not granted.") }
    }
  }
  private func asset(_ uri: String) -> PHAsset? {
    guard uri.hasPrefix("ph://") else { return nil }
    return PHAsset.fetchAssets(withLocalIdentifiers: [String(uri.dropFirst(5))], options: nil).firstObject
  }

  private func handle(_ name: String, _ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    if name == "sornaz/recording_workspace" {
      if call.method == "location" {
        do {
          let folder = recordingFolder ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Recordings", isDirectory: true)
          try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
          result(folder.path)
        } catch { failure(result, error.localizedDescription) }
      } else if call.method == "choose" {
        guard workspaceResult == nil, let controller = presenter() else { failure(result, "Folder picker is busy."); return }
        workspaceResult = result
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder], asCopy: false)
        picker.delegate = self
        controller.present(picker, animated: true)
      } else { result(FlutterMethodNotImplemented) }
      return
    }
    if name == "sornaz/video_controls" {
      switch call.method {
      case "getBrightness": result(Double(UIScreen.main.brightness))
      case "setBrightness":
        if originalBrightness == nil { originalBrightness = UIScreen.main.brightness }
        UIScreen.main.brightness = CGFloat(min(1, max(0.05, (args["value"] as? Double) ?? 0.5)))
        result(nil)
      case "resetBrightness":
        if let value = originalBrightness { UIScreen.main.brightness = value; originalBrightness = nil }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
      return
    }
    if name == "sornaz/private_pdf" {
      guard call.method == "render", let path = args["path"] as? String,
            let index = args["page"] as? Int else { result(FlutterMethodNotImplemented); return }
      worker.async {
        guard let document = PDFDocument(url: self.localURL(path)), index >= 0,
              index < document.pageCount, let page = document.page(at: index) else {
          self.failure(result, "Invalid PDF document or page."); return
        }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.width > 0, bounds.height > 0 else { self.failure(result, "Invalid PDF dimensions."); return }
        let scale = min(2, 2048 / max(bounds.width, bounds.height))
        let image = page.thumbnail(of: CGSize(width: max(1, bounds.width * scale), height: max(1, bounds.height * scale)), for: .mediaBox)
        guard let data = image.pngData(), data.count <= 32 * 1024 * 1024 else {
          self.failure(result, "PDF page is too large."); return
        }
        self.reply(result, ["bytes": FlutterStandardTypedData(bytes: data), "count": document.pageCount])
      }
      return
    }
    switch call.method {
    case "permission":
      PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
        self.reply(result, status == .authorized ? "granted" : status == .limited ? "limited" : "denied")
      }
    case "gallery", "videos":
      authorized(result) { self.worker.async { self.list(args, videosOnly: call.method == "videos", result) } }
    case "materialize":
      guard let uri = args["uri"] as? String else { failure(result, "Missing media URI."); return }
      if uri.hasPrefix("ph://") {
        authorized(result) {
          guard let source = self.asset(uri) else { self.failure(result, "Photo asset is unavailable."); return }
          self.materialize(source, result)
        }
      } else {
        worker.async {
          do {
            let source = self.localURL(uri)
            let target = try self.draft(source.pathExtension.isEmpty ? "bin" : source.pathExtension)
            try FileManager.default.copyItem(at: source, to: target)
            self.reply(result, target.path)
          } catch { self.failure(result, error.localizedDescription) }
        }
      }
    case "thumbnail":
      guard let uri = args["uri"] as? String else { failure(result, "Missing media URI."); return }
      authorized(result) {
        guard let source = self.asset(uri) else { self.failure(result, "Photo asset is unavailable."); return }
        let size = min(2048, max(16, args["size"] as? Int ?? 240))
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .exact
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(for: source, targetSize: CGSize(width: CGFloat(size), height: CGFloat(size)), contentMode: .aspectFit, options: options) { image, info in
          if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
          guard let data = image?.jpegData(compressionQuality: 0.85) else { self.failure(result, "Thumbnail unavailable."); return }
          self.reply(result, FlutterStandardTypedData(bytes: data))
        }
      }
    case "save":
      guard let path = args["path"] as? String else { failure(result, "Missing output file."); return }
      let url = localURL(path)
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        guard status == .authorized || status == .limited else { self.failure(result, "Photo saving permission was not granted."); return }
        PHPhotoLibrary.shared().performChanges({
          if args["video"] as? Bool == true { PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) }
          else { PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url) }
        }) { success, error in
          if success { self.reply(result, path) }
          else { self.failure(result, error?.localizedDescription ?? "Could not save photo asset.") }
        }
      }
    case "delete":
      let uris = args["uris"] as? [String] ?? []
      authorized(result) {
        let ids = uris.filter { $0.hasPrefix("ph://") }.map { String($0.dropFirst(5)) }
        guard ids.count == uris.count else { self.failure(result, "Expected Photo library assets."); return }
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        PHPhotoLibrary.shared().performChanges({ PHAssetChangeRequest.deleteAssets(assets) }) { success, error in
          if success { self.reply(result, nil) }
          else { self.failure(result, error?.localizedDescription ?? "Photo deletion was cancelled.") }
        }
      }
    case "rename":
      guard let uri = (args["uris"] as? [String])?.first,
            let title = args["name"] as? String, !title.isEmpty,
            title == (title as NSString).lastPathComponent else { failure(result, "Invalid asset name."); return }
      // PhotoKit does not expose renaming original resources. Keep a display
      // title for this application without replacing or deleting the asset.
      UserDefaults.standard.set(title, forKey: "sornaz.video.title.\(uri)")
      result(uri)
    case "share":
      let paths = args["paths"] as? [String] ?? []
      guard !paths.isEmpty, let controller = presenter() else { failure(result, "No files to share."); return }
      let sheet = UIActivityViewController(activityItems: paths.map { localURL($0) }, applicationActivities: nil)
      sheet.popoverPresentationController?.sourceView = controller.view
      sheet.popoverPresentationController?.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
      sheet.completionWithItemsHandler = { _, _, _, error in
        if let error = error { self.failure(result, error.localizedDescription) }
        else { self.reply(result, nil) }
      }
      controller.present(sheet, animated: true)
    case "camera":
      guard cameraResult == nil, UIImagePickerController.isSourceTypeAvailable(.camera), let controller = presenter() else {
        failure(result, "Camera unavailable or already in use."); return
      }
      let picker = UIImagePickerController()
      picker.sourceType = .camera
      picker.mediaTypes = ["public.image"]
      picker.delegate = self
      cameraResult = result
      controller.present(picker, animated: true)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func list(_ args: [String: Any], videosOnly: Bool, _ result: @escaping FlutterResult) {
    let options = PHFetchOptions()
    options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    options.predicate = videosOnly ? NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
      : NSPredicate(format: "mediaType == %d OR mediaType == %d", PHAssetMediaType.video.rawValue, PHAssetMediaType.image.rawValue)
    let assets = PHAsset.fetchAssets(with: options)
    let offset = min(assets.count, max(0, args["offset"] as? Int ?? 0))
    let end = videosOnly ? assets.count : min(assets.count, offset + 60)
    var rows: [[String: Any]] = []
    for index in offset..<end {
      let item = assets.object(at: index)
      let uri = "ph://" + item.localIdentifier
      let filename = PHAssetResource.assetResources(for: item).first?.originalFilename ?? "Media"
      rows.append([
        "uri": uri, "path": uri, "name": UserDefaults.standard.string(forKey: "sornaz.video.title.\(uri)") ?? filename,
        "video": item.mediaType == .video, "size": 0,
        "duration": Int((item.duration * 1000).rounded()),
        "addedAt": Int64((item.creationDate?.timeIntervalSince1970 ?? 0) * 1000),
        "folder": "Photos", "folderId": "photos",
      ])
    }
    reply(result, rows)
  }

  private func materialize(_ asset: PHAsset, _ result: @escaping FlutterResult) {
    if asset.mediaType == .video {
      let options = PHVideoRequestOptions()
      options.isNetworkAccessAllowed = true
      PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { source, _, _ in
        guard let source = source, let exporter = AVAssetExportSession(asset: source, presetName: AVAssetExportPresetPassthrough) else {
          self.failure(result, "Video is unavailable or cannot be exported."); return
        }
        do {
          let type: AVFileType = exporter.supportedFileTypes.contains(.mp4) ? .mp4 : .mov
          let output = try self.draft(type == .mp4 ? "mp4" : "mov")
          exporter.outputURL = output
          exporter.outputFileType = type
          exporter.exportAsynchronously {
            if exporter.status == .completed { self.reply(result, output.path) }
            else {
              try? FileManager.default.removeItem(at: output)
              self.failure(result, exporter.error?.localizedDescription ?? "Video export failed.")
            }
          }
        } catch { self.failure(result, error.localizedDescription) }
      }
    } else {
      let options = PHImageRequestOptions()
      options.isNetworkAccessAllowed = true
      options.deliveryMode = .highQualityFormat
      PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
        guard let data = data else { self.failure(result, "Image is unavailable."); return }
        do {
          let output = try self.draft("jpg")
          guard let image = UIImage(data: data) else { self.failure(result, "Invalid image."); return }
          let normalized = UIGraphicsImageRenderer(size: image.size).image { _ in image.draw(at: .zero) }
          guard let encoded = normalized.jpegData(compressionQuality: 0.95) else { self.failure(result, "Image export failed."); return }
          try encoded.write(to: output, options: .atomic)
          self.reply(result, output.path)
        } catch { self.failure(result, error.localizedDescription) }
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    let result = cameraResult; cameraResult = nil
    picker.dismiss(animated: true) { result?(nil) }
  }
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let callback = workspaceResult; workspaceResult = nil
    guard let result = callback else { return }
    guard let folder = urls.first, folder.startAccessingSecurityScopedResource() else { failure(result, "Folder access was not granted."); return }
    do {
      let bookmark = try folder.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
      UserDefaults.standard.set(bookmark, forKey: "sornaz.recording.folder")
      recordingFolder?.stopAccessingSecurityScopedResource()
      recordingFolder = folder
      result(folder.path)
    } catch {
      folder.stopAccessingSecurityScopedResource()
      failure(result, error.localizedDescription)
    }
  }
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let result = workspaceResult; workspaceResult = nil; result?(nil)
  }
  deinit { recordingFolder?.stopAccessingSecurityScopedResource() }
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
    let result = cameraResult; cameraResult = nil
    picker.dismiss(animated: true) {
      guard let result = result else { return }
      guard let image = info[.originalImage] as? UIImage else { self.failure(result, "Camera returned no image."); return }
      do {
        let file = try self.draft("jpg")
        let normalized = UIGraphicsImageRenderer(size: image.size).image { _ in image.draw(at: .zero) }
        guard let data = normalized.jpegData(compressionQuality: 0.95) else { self.failure(result, "Camera image export failed."); return }
        try data.write(to: file, options: .atomic)
        self.reply(result, file.path)
      } catch { self.failure(result, error.localizedDescription) }
    }
  }
}
