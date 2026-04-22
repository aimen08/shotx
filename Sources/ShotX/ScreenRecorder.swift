import Cocoa
import ScreenCaptureKit
import AVFoundation

enum ScreenRecorderError: LocalizedError {
    case displayNotFound
    case writerFailed(String)

    var errorDescription: String? {
        switch self {
        case .displayNotFound: return "Couldn't find the display to record."
        case .writerFailed(let msg): return "Recording failed: \(msg)"
        }
    }
}

@available(macOS 13.0, *)
final class ScreenRecorder: NSObject, @unchecked Sendable {
    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private let sampleQueue = DispatchQueue(label: "com.shotx.recorder.samples", qos: .userInitiated)
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

    func start(rect: CGRect, screen: NSScreen, showsCursor: Bool) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        let targetDisplayID = screenNumber?.uint32Value ?? CGMainDisplayID()
        guard let display = content.displays.first(where: { $0.displayID == targetDisplayID })
            ?? content.displays.first else {
            throw ScreenRecorderError.displayNotFound
        }

        // AppKit global → display-local CG coords (top-left origin).
        let displayFrame = screen.frame
        let localX = rect.origin.x - displayFrame.origin.x
        let localYFromBottom = rect.origin.y - displayFrame.origin.y
        let localYFromTop = displayFrame.height - localYFromBottom - rect.height
        let sourceRect = CGRect(x: localX, y: localYFromTop, width: rect.width, height: rect.height)

        let scale = screen.backingScaleFactor
        let pixelWidth = Int(rect.width * scale)
        let pixelHeight = Int(rect.height * scale)

        let selfPID = NSRunningApplication.current.processIdentifier
        let excludeApps = content.applications.filter { $0.processID == selfPID }
        let filter = SCContentFilter(display: display, excludingApplications: excludeApps, exceptingWindows: [])

        let config = SCStreamConfiguration()
        config.width = pixelWidth
        config.height = pixelHeight
        config.sourceRect = sourceRect
        config.showsCursor = showsCursor
        config.minimumFrameInterval = CMTime(value: 1, timescale: 30)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.queueDepth = 6

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
        guard writer.startWriting() else {
            throw ScreenRecorderError.writerFailed(writer.error?.localizedDescription ?? "unknown")
        }

        self.assetWriter = writer
        self.videoInput = input
        self.pixelBufferAdaptor = adaptor

        let stream = SCStream(filter: filter, configuration: config, delegate: self)
        try stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
        self.stream = stream
        try await stream.startCapture()
    }

    func stop() async -> URL? {
        do { try await stream?.stopCapture() } catch { /* finalize anyway */ }
        videoInput?.markAsFinished()
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
        guard outputType == .screen, CMSampleBufferDataIsReady(sampleBuffer) else { return }

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

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        onError?(error)
    }
}
