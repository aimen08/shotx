import Cocoa
import ScreenCaptureKit
import AVFoundation

enum ScreenRecorderError: LocalizedError {
    case displayNotFound
    case writerFailed(String)
    case micPermissionDenied
    case noMicAvailable

    var errorDescription: String? {
        switch self {
        case .displayNotFound: return "Couldn't find the display to record."
        case .writerFailed(let msg): return "Recording failed: \(msg)"
        case .micPermissionDenied: return "Microphone access denied. Enable it in System Settings → Privacy & Security → Microphone."
        case .noMicAvailable: return "No microphone available on this Mac."
        }
    }
}

struct CaptureDisplay: Sendable {
    let id: CGDirectDisplayID
    let frame: CGRect
    let backingScaleFactor: CGFloat

    init(_ screen: NSScreen) {
        let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        self.id = screenNumber?.uint32Value ?? CGMainDisplayID()
        self.frame = screen.frame
        self.backingScaleFactor = screen.backingScaleFactor
    }
}

@available(macOS 13.0, *)
final class ScreenRecorder: NSObject, @unchecked Sendable {
    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var systemAudioInput: AVAssetWriterInput?
    private var micAudioInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private var micSession: AVCaptureSession?

    private let sampleQueue = DispatchQueue(label: "com.shotx.recorder.samples", qos: .userInitiated)
    private let audioQueue = DispatchQueue(label: "com.shotx.recorder.audio", qos: .userInitiated)
    private let stateQueue = DispatchQueue(label: "com.shotx.recorder.state")
    private var _sessionStarted = false
    private var sessionStarted: Bool {
        get { stateQueue.sync { _sessionStarted } }
        set { stateQueue.sync { _sessionStarted = newValue } }
    }

    private let outputURL: URL
    var onError: ((Error) -> Void)?

    init(outputURL: URL) {
        self.outputURL = outputURL
        super.init()
    }

    func start(
        rect: CGRect,
        display: CaptureDisplay,
        showsCursor: Bool,
        captureSystemAudio: Bool = false,
        captureMicrophone: Bool = false,
        exceptingWindowID: CGWindowID? = nil
    ) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        guard let scDisplay = content.displays.first(where: { $0.displayID == display.id })
            ?? content.displays.first else {
            throw ScreenRecorderError.displayNotFound
        }

        // AppKit global → display-local CG coords (top-left origin).
        let displayFrame = display.frame
        let localX = rect.origin.x - displayFrame.origin.x
        let localYFromBottom = rect.origin.y - displayFrame.origin.y
        let localYFromTop = displayFrame.height - localYFromBottom - rect.height
        let sourceRect = CGRect(x: localX, y: localYFromTop, width: rect.width, height: rect.height)

        let scale = display.backingScaleFactor
        let pixelWidth = Int(rect.width * scale)
        let pixelHeight = Int(rect.height * scale)

        let selfPID = NSRunningApplication.current.processIdentifier
        let excludeApps = content.applications.filter { $0.processID == selfPID }

        // If the caller wants a specific window of ours included in the capture
        // (e.g. the click-highlight overlay), look it up and pass it as an
        // exception to the app exclusion.
        var exceptingWindows: [SCWindow] = []
        if let wid = exceptingWindowID,
           let win = content.windows.first(where: { $0.windowID == wid }) {
            exceptingWindows.append(win)
        }

        let filter = SCContentFilter(
            display: scDisplay,
            excludingApplications: excludeApps,
            exceptingWindows: exceptingWindows
        )

        let config = SCStreamConfiguration()
        config.width = pixelWidth
        config.height = pixelHeight
        config.sourceRect = sourceRect
        config.showsCursor = showsCursor
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.queueDepth = 6
        config.capturesAudio = captureSystemAudio
        if captureSystemAudio {
            config.sampleRate = 48000
            config.channelCount = 2
        }

        // Try to remove any stale output file.
        try? FileManager.default.removeItem(at: outputURL)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)

        let avgBitRate = max(1_500_000, pixelWidth * pixelHeight * 6)
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: pixelWidth,
            AVVideoHeightKey: pixelHeight,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: avgBitRate,
                AVVideoExpectedSourceFrameRateKey: 30
            ]
        ]
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        input.expectsMediaDataInRealTime = true

        let sourceAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: pixelWidth,
            kCVPixelBufferHeightKey as String: pixelHeight
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: sourceAttrs
        )

        writer.add(input)

        // System audio input (fed from SCStream .audio samples)
        if captureSystemAudio {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 48000,
                AVEncoderBitRateKey: 128000
            ]
            let sysInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            sysInput.expectsMediaDataInRealTime = true
            writer.add(sysInput)
            self.systemAudioInput = sysInput
        }

        // Mic audio input (fed from AVCaptureSession)
        if captureMicrophone {
            let micSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000
            ]
            let micInput = AVAssetWriterInput(mediaType: .audio, outputSettings: micSettings)
            micInput.expectsMediaDataInRealTime = true
            writer.add(micInput)
            self.micAudioInput = micInput
        }

        guard writer.startWriting() else {
            throw ScreenRecorderError.writerFailed(writer.error?.localizedDescription ?? "unknown")
        }

        self.assetWriter = writer
        self.videoInput = input
        self.pixelBufferAdaptor = adaptor

        let stream = SCStream(filter: filter, configuration: config, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
        if captureSystemAudio {
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)
        }
        self.stream = stream
        try await stream.startCapture()

        if captureMicrophone {
            try await startMicCapture()
        }
    }

    private func startMicCapture() async throws {
        // Request mic permission
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .notDetermined {
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            if !granted { throw ScreenRecorderError.micPermissionDenied }
        } else if status != .authorized {
            throw ScreenRecorderError.micPermissionDenied
        }

        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw ScreenRecorderError.noMicAvailable
        }

        let session = AVCaptureSession()
        let input = try AVCaptureDeviceInput(device: device)
        if session.canAddInput(input) { session.addInput(input) }

        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: audioQueue)
        if session.canAddOutput(output) { session.addOutput(output) }

        session.startRunning()
        micSession = session
    }

    func stop() async -> URL? {
        do { try await stream?.stopCapture() } catch { /* finalize anyway */ }
        micSession?.stopRunning()
        micSession = nil
        videoInput?.markAsFinished()
        systemAudioInput?.markAsFinished()
        micAudioInput?.markAsFinished()
        if let writer = assetWriter {
            await writer.finishWriting()
            if writer.status == .completed { return outputURL }
        }
        return nil
    }
}

@available(macOS 13.0, *)
extension ScreenRecorder: SCStreamOutput, SCStreamDelegate {
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        switch outputType {
        case .screen:
            handleVideo(sampleBuffer)
        case .audio:
            handleSystemAudio(sampleBuffer)
        @unknown default:
            break
        }
    }

    private func handleVideo(_ sampleBuffer: CMSampleBuffer) {
        guard let attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
                as? [[SCStreamFrameInfo: Any]],
              let attachments = attachmentsArray.first,
              let statusRaw = attachments[SCStreamFrameInfo.status] as? Int,
              let status = SCFrameStatus(rawValue: statusRaw),
              status == .complete,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        guard let writer = assetWriter,
              let input = videoInput,
              let adaptor = pixelBufferAdaptor
        else { return }

        if !sessionStarted {
            if writer.status == .writing {
                writer.startSession(atSourceTime: pts)
                sessionStarted = true
            } else {
                return
            }
        }

        if input.isReadyForMoreMediaData {
            adaptor.append(imageBuffer, withPresentationTime: pts)
        }
    }

    private func handleSystemAudio(_ sampleBuffer: CMSampleBuffer) {
        guard sessionStarted,
              let input = systemAudioInput,
              input.isReadyForMoreMediaData,
              assetWriter?.status == .writing
        else { return }
        input.append(sampleBuffer)
    }

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onError?(error)
    }
}

@available(macOS 13.0, *)
extension ScreenRecorder: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard sessionStarted,
              let input = micAudioInput,
              input.isReadyForMoreMediaData,
              assetWriter?.status == .writing
        else { return }
        input.append(sampleBuffer)
    }
}
