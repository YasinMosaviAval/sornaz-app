import AVFoundation
import Flutter

/// A continuously rendered bar keeps timing on the audio clock, including in
/// the background. Dart receives UI updates rather than scheduling the clicks.
final class IOSMetronome: NSObject, FlutterStreamHandler {
  private let engine = AVAudioEngine()
  private let node = AVAudioPlayerNode()
  private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
  private let method: FlutterMethodChannel
  private let events: FlutterEventChannel
  private let assetKey: (String) -> String
  private var sink: FlutterEventSink?
  private var timer: Timer?
  private var samples: [[Float]] = []
  private var beats = 4, subdivisions = 1, framesPerSubdivision = 22050
  private var targetBars = 0, targetSeconds = 0
  private var completedBars = 0, lastTick: Int64 = -1
  private var startedAt: TimeInterval = 0
  private var interruption: NSObjectProtocol?

  init(messenger: FlutterBinaryMessenger, assetKey: @escaping (String) -> String) {
    self.assetKey = assetKey
    method = FlutterMethodChannel(name: "sornaz/metronome", binaryMessenger: messenger)
    events = FlutterEventChannel(name: "sornaz/metronome/events", binaryMessenger: messenger)
    super.init()
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: format)
    events.setStreamHandler(self)
    method.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      do {
        switch call.method {
        case "start":
          self.stop()
          self.startedAt = ProcessInfo.processInfo.systemUptime
          try self.configure(call.arguments as? [String: Any] ?? [:])
        case "configure":
          if self.engine.isRunning { try self.configure(call.arguments as? [String: Any] ?? [:]) }
        case "stop": self.stop()
        default: result(FlutterMethodNotImplemented); return
        }
        result(nil)
      } catch {
        self.stop()
        result(FlutterError(code: "METRONOME", message: error.localizedDescription, details: nil))
      }
    }
    interruption = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
      if (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue {
        self?.stop(finished: true)
      }
    }
  }
  private func readSample(_ name: String) throws -> [Float] {
    let key = assetKey("assets/audio/\(name).wav")
    guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
      throw NSError(domain: "SornazMetronome", code: 1, userInfo: [NSLocalizedDescriptionKey: "Metronome sound asset is missing"])
    }
    let file = try AVAudioFile(forReading: URL(fileURLWithPath: path))
    guard file.length > 0, file.length <= 44100 * 5,
          let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
      throw NSError(domain: "SornazMetronome", code: 2)
    }
    try file.read(into: buffer)
    guard let channel = buffer.floatChannelData?[0] else { throw NSError(domain: "SornazMetronome", code: 3) }
    let ratio = file.processingFormat.sampleRate / 44100
    let count = max(1, Int(Double(buffer.frameLength) / ratio))
    return (0..<count).map { index in
      let position = Double(index) * ratio
      let first = min(Int(buffer.frameLength) - 1, Int(position))
      let second = min(Int(buffer.frameLength) - 1, first + 1)
      let fraction = Float(position - Double(first))
      return channel[first] + (channel[second] - channel[first]) * fraction
    }
  }
  private func framePosition() -> Int64 {
    guard let time = node.lastRenderTime, let player = node.playerTime(forNodeTime: time) else { return 0 }
    return max(0, player.sampleTime)
  }
  private func configure(_ args: [String: Any]) throws {
    if engine.isRunning {
      completedBars += Int(framePosition()) / max(1, framesPerSubdivision * subdivisions * beats)
    }
    node.stop()
    timer?.invalidate()
    if samples.isEmpty { samples = try [readSample("accent"), readSample("tick"), readSample("sub_tick")] }
    let bpm = min(300, max(30, args["bpm"] as? Int ?? 120))
    beats = min(32, max(1, args["beats"] as? Int ?? 4))
    subdivisions = min(4, max(1, args["subdivisions"] as? Int ?? 1))
    framesPerSubdivision = max(1, Int((44100 * 60 / Double(bpm * subdivisions)).rounded()))
    targetBars = max(0, args["bars"] as? Int ?? 0)
    targetSeconds = max(0, args["seconds"] as? Int ?? 0)
    let volumes = ["accent", "tick", "sub"].map { min(1, max(0, args[$0] as? Double ?? 1)) }
    let frames = framesPerSubdivision * beats * subdivisions
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)),
          let output = buffer.floatChannelData?[0] else { throw NSError(domain: "SornazMetronome", code: 4) }
    buffer.frameLength = AVAudioFrameCount(frames)
    output.initialize(repeating: 0, count: frames)
    for tick in 0..<(beats * subdivisions) {
      let kind = tick == 0 ? 0 : tick % subdivisions == 0 ? 1 : 2
      let start = tick * framesPerSubdivision
      for index in 0..<min(samples[kind].count, framesPerSubdivision) {
        output[start + index] = samples[kind][index] * Float(volumes[kind])
      }
    }
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    try session.setActive(true)
    if !engine.isRunning { try engine.start() }
    lastTick = -1
    node.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
    node.play()
    timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in self?.update() }
    update()
  }
  private func update() {
    let frame = framePosition()
    let tick = frame / Int64(framesPerSubdivision)
    let bars = completedBars + Int(tick) / (beats * subdivisions)
    if (targetBars > 0 && bars >= targetBars) ||
       (targetSeconds > 0 && ProcessInfo.processInfo.systemUptime - startedAt >= Double(targetSeconds)) {
      stop(finished: true); return
    }
    if tick == lastTick { return }
    lastTick = tick
    sink?(["beat": (Int(tick) / subdivisions) % beats + 1, "bar": bars + 1,
           "accent": Int(tick) % (beats * subdivisions) == 0, "finished": false])
  }
  private func stop(finished: Bool = false) {
    timer?.invalidate(); timer = nil
    node.stop(); engine.stop()
    completedBars = 0; lastTick = -1
    if finished { sink?(["finished": true]) }
  }
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? { sink = events; return nil }
  func onCancel(withArguments arguments: Any?) -> FlutterError? { sink = nil; return nil }
  deinit {
    timer?.invalidate(); node.stop(); engine.stop()
    if let interruption = interruption { NotificationCenter.default.removeObserver(interruption) }
  }
}
