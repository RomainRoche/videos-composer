//
//  ViewController.swift
//  videos-composer
//
//  Created by Romain ROCHE on 01/09/2017.
//  Copyright © 2017 Romain ROCHE. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import AVKit
import PhotosUI

extension AVPlayer {
    
    func currentTrackWithType(_ type: String) -> AVAssetTrack? {
        guard let tracks = self.currentItem?.asset.tracks(withMediaType: type)
            , tracks.count > 0 else {
                return nil
        }
        return tracks[0]
    }
    
    func currentAudioTrack() -> AVAssetTrack? {
        return self.currentTrackWithType(AVMediaTypeAudio)
    }
    
    func currentVideoTrack() -> AVAssetTrack? {
        return self.currentTrackWithType(AVMediaTypeVideo)
    }
    
    func currentVideoTrackResolution() -> CGSize {
        guard let track: AVAssetTrack = self.currentVideoTrack() else {
                return CGSize.zero
        }
        let transform = track.preferredTransform
        var size = __CGSizeApplyAffineTransform(track.naturalSize, transform)
        size.width = fabs(size.width)
        size.height = fabs(size.height)
        return size
    }
    
}

class VCCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet private var firstButton: UIButton?
    @IBOutlet private var secondButtin: UIButton?
    @IBOutlet private var capturedVideoView: UIView?
    @IBOutlet private var savedVideoView: UIView?
    
    // MARK: properties
    
    private var capturedPlayer: AVPlayer?
    private var capturedPlayerLayer: AVPlayerLayer?
    
    private var savedPlayer: AVPlayer?
    private var savedPlayerLayer: AVPlayerLayer?
    
    // MARK: properties override
    
    override public var shouldAutorotate: Bool {
        get {
            return false;
        }
    }
    
    // MARK: methods override
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        // super
        super.viewWillAppear(animated)
        
        // notifications
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playbackDidEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.capturedPlayer?.currentItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playbackDidEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.savedPlayer?.currentItem)
        
        // start players if needed
        if (self.capturedPlayer?.currentItem != nil) {
            self.capturedPlayer?.play()
        }
        if (self.savedPlayer?.currentItem != nil) {
            self.savedPlayer?.play()
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let moviePath = info[UIImagePickerControllerMediaURL] as! URL!
        self.dismiss(animated: true) {
            if (picker.sourceType == .camera) {
                self.installVideo(moviePath, view: self.capturedVideoView, player: &self.capturedPlayer, playerLayer: &self.capturedPlayerLayer)
            } else if (picker.sourceType == .photoLibrary) {
                self.installVideo(moviePath, view: self.savedVideoView, player: &self.savedPlayer, playerLayer: &self.savedPlayerLayer)
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }
    
    // MARK: @IBAction

    @IBAction private func captureFirstVideo() {
        if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            print("no camera available")
            return
        }
        self.getVideo(.camera)
    }
    
    @IBAction private func getSecondVideo() {
        if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)) {
            print("no photo library")
            return
        }
        self.getVideo(.photoLibrary)
    }
    
    @IBAction private func validate() {
        
        guard let capturedVideoTrack: AVAssetTrack = self.capturedPlayer?.currentVideoTrack()
            , let savedVideoTrack: AVAssetTrack = self.savedPlayer?.currentVideoTrack() else {
                return
        }
        
        let composition: AVMutableComposition = AVMutableComposition()
        composition.naturalSize = capturedVideoTrack.naturalSize
        
        let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio, preferredTrackID: kCMPersistentTrackID_Invalid)
        
        
        let capturedDuration: CMTime = self.capturedPlayer!.currentItem!.asset.duration
        let savedDuration: CMTime = self.savedPlayer!.currentItem!.asset.duration
        
        let firstRange: CMTimeRange = CMTimeRange(start: kCMTimeZero, duration: capturedDuration)
        let secondRange: CMTimeRange = CMTimeRange(start: kCMTimeZero, duration: savedDuration)
        
        do {
            
            // add video tracks to the video mutable composition tracks
            try videoTrack.insertTimeRange(firstRange, of: capturedVideoTrack, at: kCMTimeZero)
            try videoTrack.insertTimeRange(secondRange, of: savedVideoTrack, at: capturedDuration)
            
            // add audio tracks (if exists) to the audio mutable composition tracks
            if let capturedAutioTrack: AVAssetTrack = self.capturedPlayer?.currentAudioTrack() {
                try audioTrack.insertTimeRange(firstRange, of: capturedAutioTrack, at: kCMTimeZero)
            }
            if let savedAudioTrack: AVAssetTrack = self.savedPlayer?.currentAudioTrack() {
                try audioTrack.insertTimeRange(secondRange, of: savedAudioTrack, at: capturedDuration)
            }
            
            let player: AVPlayer = AVPlayer(playerItem: AVPlayerItem(asset: composition))
            let controller: AVPlayerViewController = AVPlayerViewController()
            controller.player = player
            self.present(controller, animated: true, completion: { 
                player.play()
            })
            
            // self.saveAsset(composition)
            
        } catch {
            print("error generating video")
        }

        print("go")
    }
    
    // MARK: methods
    
    private func getVideo(_ type: UIImagePickerControllerSourceType) {
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.videoQuality = .typeHigh
        picker.allowsEditing = true
        picker.sourceType = type
        picker.mediaTypes = [kUTTypeMovie as String]
        self.present(picker, animated: true)
    }
    
    @objc private func playbackDidEnd(_ notification: Notification) {
        if let item: AVPlayerItem = notification.object as? AVPlayerItem {
            item.seek(to: kCMTimeZero, completionHandler: { (ok) in
                if (item == self.capturedPlayer?.currentItem) {
                    self.capturedPlayer?.play()
                } else if (item == self.savedPlayer?.currentItem) {
                    self.savedPlayer?.play()
                }
            })
        }
    }
    
    private func installVideo(_ videoURL: URL!, view: UIView?, player: inout AVPlayer?, playerLayer: inout AVPlayerLayer?) {
        player?.pause()
        playerLayer?.removeFromSuperlayer()
        player = AVPlayer(url: videoURL)
        print("player video size: \(String(describing: player?.currentVideoTrackResolution().width)) x \(String(describing: player?.currentVideoTrackResolution().height))")
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = (view?.bounds)!
        view?.layer.addSublayer(playerLayer!)
        player?.isMuted = true
        player?.play()
    }
    
    private func saveAsset(_ asset: AVAsset) {
        let exportPath: String = NSTemporaryDirectory().appending("/tmp.mov")
        if (FileManager.default.fileExists(atPath: exportPath)) {
            do {
                try FileManager.default.removeItem(atPath: exportPath)
            } catch {
                print("error deleting tmp file")
            }
        }
        let exportURL: URL = URL(fileURLWithPath: exportPath)
        let exporter: AVAssetExportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        exporter.outputURL = exportURL
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.exportAsynchronously {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: exportURL)
            }, completionHandler: { (ok, error) in
                print("export ok? \(ok)")
            })
        }
    }

}

