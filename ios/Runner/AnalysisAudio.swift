import AVFoundation
import AudioToolbox
import Flutter

/// Temporary, bounded-buffer AAC-to-s16le decoder for offline analysis.
final class AnalysisAudio: NSObject {
  private let channel: FlutterMethodChannel
  private let worker = DispatchQueue(label: "sornaz.analysis.audio", qos: .utility)
  private let lock = NSLock()
  private var cancelled = false
  private var busy = false

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "sornaz/analysis_audio", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "cancel" {
      lock.lock(); cancelled = true; lock.unlock()
      result(nil)
      return
    }
    guard call.method == "decode" else { result(FlutterMethodNotImplemented); return }
    guard let args = call.arguments as? [String: Any],
          let source = args["source"] as? String,
          args["contentUri"] as? Bool == false else {
      result(FlutterError(code: "UNSUPPORTED_FORMAT", message: "Expected local file", details: nil))
      return
    }
    lock.lock()
    if busy {
      lock.unlock()
      result(FlutterError(code: "DECODE_FAILED", message: "Decoder is busy", details: nil))
      return
    }
    busy = true
    cancelled = false
    lock.unlock()
    worker.async { [weak self] in
      guard let self = self else { return }
      let response: Any
      do { response = try self.decode(source) }
      catch let error as AnalysisDecodeError {
        response = FlutterError(code: error.code, message: error.message, details: nil)
      }
      catch {
        response = FlutterError(code: "DECODE_FAILED", message: error.localizedDescription, details: nil)
      }
      self.lock.lock(); self.busy = false; self.lock.unlock()
      DispatchQueue.main.async { result(response) }
    }
  }

  private var isCancelled: Bool {
    lock.lock(); defer { lock.unlock() }
    return cancelled
  }

  private func decode(_ source: String) throws -> [String: Any] {
    let url = URL(fileURLWithPath: source)
    guard FileManager.default.fileExists(atPath: url.path) else {
      throw AnalysisDecodeError("MISSING_FILE", "Audio file does not exist")
    }
    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first,
          let description = track.formatDescriptions.first as? CMAudioFormatDescription,
          let sourceFormat = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee,
          sourceFormat.mFormatID == kAudioFormatMPEG4AAC else {
      throw AnalysisDecodeError("UNSUPPORTED_FORMAT", "Only AAC-LC recordings are supported")
    }
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ]
    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
    guard reader.canAdd(output) else {
      throw AnalysisDecodeError("UNSUPPORTED_FORMAT", "Audio output settings unsupported")
    }
    reader.add(output)
    guard reader.startReading() else {
      throw AnalysisDecodeError("DECODE_FAILED", reader.error?.localizedDescription ?? "Cannot start decoder")
    }
    let target = FileManager.default.temporaryDirectory
      .appendingPathComponent("analysis-decoded-\(UUID().uuidString).s16le")
    FileManager.default.createFile(atPath: target.path, contents: nil)
    do {
      let file = try FileHandle(forWritingTo: target)
      defer { file.closeFile() }
      while let sample = output.copyNextSampleBuffer() {
        if isCancelled {
          reader.cancelReading()
          throw AnalysisDecodeError("CANCELLED", "Audio preparation was cancelled")
        }
        guard let block = CMSampleBufferGetDataBuffer(sample) else {
          throw AnalysisDecodeError("DECODE_FAILED", "Missing PCM data buffer")
        }
        let length = CMBlockBufferGetDataLength(block)
        var offset = 0
        var bytes = [UInt8](repeating: 0, count: 65536)
        while offset < length {
          let count = min(bytes.count, length - offset)
          let status = CMBlockBufferCopyDataBytes(block, atOffset: offset,
                                                   dataLength: count, destination: &bytes)
          guard status == noErr else {
            throw AnalysisDecodeError("DECODE_FAILED", "Cannot copy PCM block")
          }
          file.write(Data(bytes.prefix(count)))
          offset += count
        }
      }
      if isCancelled {
        throw AnalysisDecodeError("CANCELLED", "Audio preparation was cancelled")
      }
      guard reader.status == .completed else {
        throw AnalysisDecodeError("DECODE_FAILED", reader.error?.localizedDescription ?? "Decoder stopped")
      }
      let duration = CMTimeGetSeconds(asset.duration)
      return [
        "path": target.path,
        "sampleRate": Int(sourceFormat.mSampleRate),
        "channels": Int(sourceFormat.mChannelsPerFrame),
        "durationUs": duration.isFinite ? Int64(duration * 1_000_000) : 0,
        "mime": "audio/mp4a-latm",
      ]
    } catch {
      try? FileManager.default.removeItem(at: target)
      throw error
    }
  }
}

private struct AnalysisDecodeError: Error {
  let code: String
  let message: String
  init(_ code: String, _ message: String) { self.code = code; self.message = message }
}
