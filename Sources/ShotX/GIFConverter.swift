import Foundation
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

enum GIFConverterError: LocalizedError {
    case emptyVideo
    case destinationFailed
    case finalizeFailed

    var errorDescription: String? {
        switch self {
        case .emptyVideo: return "Recorded video is empty."
        case .destinationFailed: return "Couldn't create GIF file."
        case .finalizeFailed: return "Couldn't finalize GIF."
        }
    }
}

enum GIFConverter {
    static func convert(
        videoURL: URL,
        outputURL: URL,
        fps: Int = 12,
        maxDimension: CGFloat = 720
    ) async throws {
        let asset = AVURLAsset(url: videoURL)

        let duration = try await asset.load(.duration).seconds
        guard duration > 0 else { throw GIFConverterError.emptyVideo }

        let totalFrames = max(1, Int(duration * Double(fps)))
        let frameDelay = 1.0 / Double(fps)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        if let track = try await asset.loadTracks(withMediaType: .video).first {
            let natural = try await track.load(.naturalSize)
            let largest = max(natural.width, natural.height)
            let scale = largest > maxDimension ? maxDimension / largest : 1.0
            generator.maximumSize = CGSize(width: natural.width * scale, height: natural.height * scale)
        }

        try? FileManager.default.removeItem(at: outputURL)

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.gif.identifier as CFString,
            totalFrames,
            nil
        ) else {
            throw GIFConverterError.destinationFailed
        }

        let fileProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ]
        CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)

        let frameProperties: [CFString: Any] = [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFDelayTime: frameDelay,
                kCGImagePropertyGIFUnclampedDelayTime: frameDelay
            ]
        ]

        for index in 0..<totalFrames {
            let time = CMTime(seconds: Double(index) * frameDelay, preferredTimescale: 600)
            do {
                let result = try await generator.image(at: time)
                CGImageDestinationAddImage(destination, result.image, frameProperties as CFDictionary)
            } catch {
                continue
            }
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GIFConverterError.finalizeFailed
        }
    }
}
