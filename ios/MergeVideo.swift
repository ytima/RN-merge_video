//
//  MergeVideo.swift
//  MergeVideo
//
//  Created by Eugene Shapovalov on 09.08.2022.
//

import Foundation
import AVKit
import AVFoundation
import MobileCoreServices

@available(iOS 11.0, *)
@objc (MergeVideo)
public class MergeVideo: NSObject {
    private var isSecondVideoNeeded = true
    private var assetWriter: AVAssetWriter?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private var assetReader: AVAssetReader?
    private let bitrate: NSNumber = NSNumber(value: 1250000)

    private var secondVideoURL: URL? {
        let url = createLocalUrl(for: "Untitled", ofType: "mp4")
        return url
    }

    public override init() {
    }

    @objc
    static func requiresMainQueueSetup() -> Bool {
        return true
    }

    private func createLocalUrl(for filename: String, ofType: String) -> URL? {
        let fileManager = FileManager.default
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cacheDirectory.appendingPathComponent("\(filename).\(ofType)")

        guard fileManager.fileExists(atPath: url.path) else {
            guard let video = NSDataAsset(name: filename)  else { return nil }
            fileManager.createFile(atPath: url.path, contents: video.data, attributes: nil)
            return url
        }

        return url
    }

    @objc func mergeVideo(_ firstVideoURL: String?, audioURL: String?, successCallback: @escaping RCTResponseSenderBlock, errorCallback: @escaping RCTResponseSenderBlock) {
        print("START: ", Date())
        guard let secondVideoUrl = secondVideoURL, let audioURL = NSURL(string: audioURL ?? "")?.absoluteURL else {
            errorCallback(["Error in URLs"])
            return
        }
        var firstAsset: AVAsset?
        let secondAsset = AVAsset(url: secondVideoUrl)
        let audioAsset = AVAsset(url: audioURL)
        let finalDuration = audioAsset.duration
        if firstVideoURL != nil, let firstVideoURL = NSURL(string: firstVideoURL ?? "")?.absoluteURL {
            firstAsset = AVAsset(url: firstVideoURL)
            guard let firstAsset = firstAsset else { return }
            isSecondVideoNeeded = firstAsset.duration < finalDuration
        } else {
            isSecondVideoNeeded = true
        }

        let mixComposition = AVMutableComposition()

        var instructions: [AVVideoCompositionLayerInstruction] = []
        let firstTrack = mixComposition.addMutableTrack(withMediaType: .video,
                                                        preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
        let secondTrack = !isSecondVideoNeeded ? nil : mixComposition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: Int32(kCMPersistentTrackID_Invalid))

        guard let firstTrack = firstTrack else {
            errorCallback(["FirstTrack is nil"])
            return }

        do {
            if let firstAsset = firstAsset {
                let duration = isSecondVideoNeeded ? firstAsset.duration : finalDuration
                try firstTrack.insertTimeRange(
                    CMTimeRangeMake(start: .zero, duration: duration),
                    of: firstAsset.tracks(withMediaType: .video)[0],
                    at: .zero)
                let firstInstruction = VideoHelper.videoCompositionInstruction(firstTrack, asset: firstAsset)
                firstInstruction.setOpacity(0.0, at: duration)
                instructions.append(firstInstruction)
            }

            if isSecondVideoNeeded, let secondTrack = secondTrack {
                try secondTrack.insertTimeRange(
                    CMTimeRangeMake(start: .zero, duration: finalDuration - (firstAsset?.duration ?? .zero)),
                    of: secondAsset.tracks(withMediaType: .video)[0],
                    at: firstAsset?.duration ?? .zero)
                let secondInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: secondTrack)
                let scaleToFitRatio = UIScreen.main.bounds.width / secondTrack.naturalSize.width
                let scaleFactor = CGAffineTransform(
                    scaleX: scaleToFitRatio,
                    y: scaleToFitRatio)
                secondInstruction.setTransform(
                    secondTrack.preferredTransform.concatenating(scaleFactor),
                    at: .zero)
                instructions.append(secondInstruction)
            }
        } catch {
            print("Failed to load tracks")
            errorCallback(["Failed to load tracks"])
            return
        }

        let mainInstruction = AVMutableVideoCompositionInstruction()
        mainInstruction.timeRange = CMTimeRangeMake(
            start: .zero,
            duration: finalDuration)

        mainInstruction.layerInstructions = instructions
        let mainComposition = AVMutableVideoComposition()
        mainComposition.instructions = [mainInstruction]
        mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 25)
        mainComposition.renderSize = CGSize(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.height)

        let audioTrack = mixComposition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: 0)
        do {
            try audioTrack?.insertTimeRange(
                CMTimeRangeMake(
                    start: .zero,
                    duration: finalDuration),
                of: audioAsset.tracks(withMediaType: .audio)[0],
                at: .zero)
        } catch {
            print("Failed to load Audio track")
            errorCallback(["Failed to load Audio track"])
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        let date = Date()
        let tempDir = NSTemporaryDirectory()
        let outputPath = "\(tempDir)/\(formatter.string(from: date)).mov"
        let url = URL(fileURLWithPath: outputPath)

        guard let exporter = AVAssetExportSession(
            asset: mixComposition,
            presetName: AVAssetExportPresetHighestQuality)
        else {
            errorCallback(["Error in exporter"])
            return
        }
        exporter.outputURL = url
        exporter.outputFileType = AVFileType.mov
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = mainComposition

        var finalUrl: URL? = nil

        exporter.exportAsynchronously { [weak self] in
            switch exporter.status {
            case .completed:
                guard let exporterOutputURL = exporter.outputURL else { return }
                DispatchQueue.main.async {
                    self?.compressFile(exporterOutputURL) { (compressedURL) in
                        finalUrl = compressedURL
                        guard let finalUrl = finalUrl else {
                            errorCallback(["Error in finalUrl"])
                            return
                        }
                        successCallback([String(describing: finalUrl)])
                        print("FINISH: \(Date())")
                    }
                    self?.removeUrlFromFileManager(exporterOutputURL)
                }
            case .failed:
                print(exporter.error as Any)
            default:
                break
            }
        }
    }

    private func removeUrlFromFileManager(_ outputFileURL: URL?) {
        if let outputFileURL = outputFileURL {

            let path = outputFileURL.path
            if FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.removeItem(atPath: path)
                    print("url SUCCESSFULLY removed: \(outputFileURL)")
                } catch {
                    print("Could not remove file at url: \(outputFileURL)")
                }
            }
        }
    }

    // MARK: - Compression
    private func compressFile(_ urlToCompress: URL, completion:@escaping (URL)->Void) {

        var audioFinished = false
        var videoFinished = false

        let asset = AVAsset(url: urlToCompress)

        do {
            assetReader = try AVAssetReader(asset: asset)
        } catch {
            assetReader = nil
        }

        guard let reader = assetReader else {
            print("Could not iniitalize asset reader probably failed its try catch")
            return
        }

        guard let videoTrack = asset.tracks(withMediaType: AVMediaType.video).first else { return }
        let videoReaderSettings: [String:Any] = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB]

        let assetReaderVideoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)

        var assetReaderAudioOutput: AVAssetReaderTrackOutput?
        if let audioTrack = asset.tracks(withMediaType: AVMediaType.audio).first {

            let audioReaderSettings: [String : Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 32000,
                AVNumberOfChannelsKey: 2
            ]

            assetReaderAudioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)

            if reader.canAdd(assetReaderAudioOutput!) {
                reader.add(assetReaderAudioOutput!)
            } else {
                print("Couldn't add audio output reader")
                return
            }
        }

        if reader.canAdd(assetReaderVideoOutput) {
            reader.add(assetReaderVideoOutput)
        } else {
            print("Couldn't add video output reader")
            return
        }

        let videoSettings:[String:Any] = [
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: self.bitrate],
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoHeightKey: videoTrack.naturalSize.height,
            AVVideoWidthKey: videoTrack.naturalSize.width,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill
        ]

        let audioSettings: [String:Any] = [AVFormatIDKey : kAudioFormatMPEG4AAC,
                                           AVNumberOfChannelsKey : 2,
                                           AVSampleRateKey : 32000.0,
                                           AVEncoderBitRateKey: 128000
        ]

        let audioInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioSettings)
        let videoInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoSettings)
        videoInput.transform = videoTrack.preferredTransform

        let videoInputQueue = DispatchQueue(label: "videoQueue")
        let audioInputQueue = DispatchQueue(label: "audioQueue")

        guard let documentDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask).first
        else { return }

        do {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            dateFormatter.timeStyle = .short
            let date = dateFormatter.string(from: Date())
            let outputURL = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: AVFileType.mov)
        } catch {
            assetWriter = nil
        }
        guard let writer = assetWriter else {
            print("assetWriter was nil")
            return
        }

        writer.shouldOptimizeForNetworkUse = true
        writer.add(videoInput)
        writer.add(audioInput)

        writer.startWriting()
        reader.startReading()
        writer.startSession(atSourceTime: CMTime.zero)

        let closeWriter:()->Void = {
            if (audioFinished && videoFinished) {
                self.assetWriter?.finishWriting(completionHandler: { [weak self] in
                    if let assetWriter = self?.assetWriter {
                        do {
                            let data = try Data(contentsOf: assetWriter.outputURL)
                            print("compressFile -file size after compression: \(Double(data.count / 1048576)) mb")
                        } catch let err as NSError {
                            print("compressFile Error: \(err.localizedDescription)")
                        }
                    }
                    if let safeSelf = self, let assetWriter = safeSelf.assetWriter {
                        completion(assetWriter.outputURL)
                    }
                })
                self.assetReader?.cancelReading()
            }
        }

        audioInput.requestMediaDataWhenReady(on: audioInputQueue) {
            while(audioInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = assetReaderAudioOutput?.copyNextSampleBuffer() {
                    audioInput.append(cmSampleBuffer)
                } else {
                    audioInput.markAsFinished()
                    DispatchQueue.main.async {
                        audioFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }

        videoInput.requestMediaDataWhenReady(on: videoInputQueue) {
            while(videoInput.isReadyForMoreMediaData) {
                if let cmSampleBuffer = assetReaderVideoOutput.copyNextSampleBuffer() {
                    videoInput.append(cmSampleBuffer)
                } else {
                    videoInput.markAsFinished()
                    DispatchQueue.main.async {
                        videoFinished = true
                        closeWriter()
                    }
                    break;
                }
            }
        }
    }
}
