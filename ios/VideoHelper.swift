//
//  VideoHelper.swift
//  MergeVideo
//
//  Created by Eugene Shapovalov on 15.08.2022.
//

import AVFoundation
import MobileCoreServices
import UIKit

enum VideoHelper {
    static func orientationFromTransform(
        _ transform: CGAffineTransform,
        isPortrait: Bool
    ) -> (orientation: UIImage.Orientation, isPortrait: Bool) {
        var assetOrientation = UIImage.Orientation.up
        var isPortrait = isPortrait
        let tfA = transform.a
        let tfB = transform.b
        let tfC = transform.c
        let tfD = transform.d

        if tfA == 0 && tfB == 1.0 && tfC == -1.0 && tfD == 0 {
            assetOrientation = .right
            isPortrait = true
        } else if tfA == 0 && tfB == -1.0 && tfC == 1.0 && tfD == 0 {
            assetOrientation = .left
            isPortrait = true
        } else if tfA == 1.0 && tfB == 0 && tfC == 0 && tfD == 1.0 {
            assetOrientation = .up
        } else if tfA == -1.0 && tfB == 0 && tfC == 0 && tfD == -1.0 {
            assetOrientation = .down
        }
        return (assetOrientation, isPortrait)
    }

    static func startMediaBrowser(
        delegate: UIViewController & UINavigationControllerDelegate & UIImagePickerControllerDelegate,
        sourceType: UIImagePickerController.SourceType
    ) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType)
        else { return }

        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = sourceType
        mediaUI.mediaTypes = [kUTTypeMovie as String]
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate
        delegate.present(mediaUI, animated: true, completion: nil)
    }

    static func videoCompositionInstruction(
        _ track: AVCompositionTrack,
        asset: AVAsset
    ) -> AVMutableVideoCompositionLayerInstruction {
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracks(withMediaType: AVMediaType.video)[0]

        let transform = assetTrack.preferredTransform
        let isPortrait = assetTrack.naturalSize.width < assetTrack.naturalSize.height
        let assetInfo = orientationFromTransform(transform, isPortrait: isPortrait)

        var scaleToFitRatio = videoSize.width / assetTrack.naturalSize.width
        if assetInfo.isPortrait {
            scaleToFitRatio = videoSize.width / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(
                scaleX: scaleToFitRatio,
                y: scaleToFitRatio)
            instruction.setTransform(
                assetTrack.preferredTransform.concatenating(scaleFactor),
                at: .zero)
        } else {
          scaleToFitRatio = videoSize.height / assetTrack.naturalSize.height
            let scaleFactor = CGAffineTransform(
                scaleX: scaleToFitRatio,
                y: scaleToFitRatio)
            var concat = assetTrack.preferredTransform.concatenating(scaleFactor)
                .concatenating(CGAffineTransform(
                  translationX: -((assetTrack.naturalSize.width * scaleToFitRatio / 2) - (UIScreen.main.bounds.width / 2)),
                    y: 0))
            if assetInfo.orientation == .down {
                let fixUpsideDown = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                let windowBounds = videoSize
                let yFix = assetTrack.naturalSize.height + windowBounds.height
                let centerFix = CGAffineTransform(
                    translationX: assetTrack.naturalSize.width,
                    y: yFix)
                concat = fixUpsideDown.concatenating(centerFix).concatenating(scaleFactor)
            }
            instruction.setTransform(concat, at: .zero)
        }

        return instruction
    }
}

