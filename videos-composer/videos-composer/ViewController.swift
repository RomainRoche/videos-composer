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
import TwitterKit

extension AVPlayer {
    
    func currentTrackWithType(_ type: AVMediaType) -> AVAssetTrack? {
        guard let tracks = self.currentItem?.asset.tracks(withMediaType: type)
            , tracks.count > 0 else {
                return nil
        }
        return tracks[0]
    }
    
    var currentAudioTrack: AVAssetTrack? {
        get {
            return self.currentTrackWithType(AVMediaType.audio)
        }
    }
    
    var currentVideoTrack: AVAssetTrack? {
        get {
            return self.currentTrackWithType(AVMediaType.video)
        }
    }
    
    func currentVideoTrackResolution() -> CGSize {
        guard let track: AVAssetTrack = self.currentVideoTrack else {
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
    
    private var composedVideoAsset: AVAsset? {
        get {
            guard let capturedItem: AVPlayerItem = self.capturedPlayer?.currentItem
                , let savedItem: AVPlayerItem = self.savedPlayer?.currentItem else {
                    return nil
            }
            return VideosComposer.AppendVideos([capturedItem, savedItem])
        }
    }
    
    private var twitterSession: TWTRSession?
    
    // MARK: properties override
    
    override public var shouldAutorotate: Bool {
        get {
            return false
        }
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get {
            return .portrait
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
    
    @IBAction private func viewResult() {
        guard let asset: AVAsset = self.composedVideoAsset else {
            return
        }
        let player: AVPlayer = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        let controller: AVPlayerViewController = AVPlayerViewController()
        controller.player = player
        self.present(controller, animated: true, completion: {
            player.play()
        })
    }
    
    @IBAction private func saveResult() {
        guard let asset: AVAsset = self.composedVideoAsset else {
            return
        }
        self.saveAssetToLibrary(asset)
    }
    
    @IBAction private func instagramResult() {
        guard let asset: AVAsset = self.composedVideoAsset else {
            return
        }
        self.saveAssetToLibrary(asset) { (ok: Bool) in
            DispatchQueue.main.async {
                if ok, let insta: URL = URL(string: "instagram://camera"), UIApplication.shared.canOpenURL(insta) {
                    UIApplication.shared.open(insta)
                }
            }
        }
    }
    
    @IBAction private func facebookResult() {
        // need to add a SDK
        guard let asset: AVAsset = self.composedVideoAsset else {
            return
        }
        self.exportAsset(asset) { (url, ok) -> Void in
            if ok {
                let sharer: UIActivityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self.present(sharer, animated: true)
            }
        }
    }
    
    @IBAction private func twitterResult() {
        // login
        self.loginToTwitterIfNeeded { (ok: Bool) -> Void in
            guard let asset: AVAsset = self.composedVideoAsset else {
                return
            }
            // export asset
            self.exportAsset(asset, completion: { (url, ok) in
                guard ok else {return}
                do {
                    // present twitter composer with preview and video data
                    let previewGenerator: AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
                    let img = try previewGenerator.copyCGImage(at: CMTimeMake(1, 1), actualTime: nil)
                    let data: Data = try Data(contentsOf: url)
                    DispatchQueue.main.async {
                        let tw: TWTRComposerViewController = TWTRComposerViewController(initialText: "", image: UIImage(cgImage: img), videoData: data)
                        self.present(tw, animated: true)
                    }
                }
                catch let error as NSError {
                    print("error: \(error.localizedDescription)")
                }
            })
        }
    }
    
    // MARK: methods
    
    private func loginToTwitterIfNeeded(_ completion: ((Bool) -> Void)? = nil) {
        var valid = false
        if let session = self.twitterSession {
            valid = !Twitter.sharedInstance().sessionStore.isExpiredSession(session, error: NSError())
        }
        if !valid {
            Twitter.sharedInstance().logIn { (session: TWTRSession?, error: Error?) in
                self.twitterSession = session
                completion?(session != nil && error == nil)
            }
        } else {
            completion?(true)
        }
    }
    
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
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = (view?.bounds)!
        view?.layer.addSublayer(playerLayer!)
        player?.isMuted = true
        player?.play()
    }
    
    private func exportAsset(_ asset: AVAsset, completion: ((URL, Bool) -> Void)? = nil) {
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
        exporter.outputFileType = AVFileType.mov
        exporter.exportAsynchronously {
            completion?(exportURL, exporter.status == .completed)
        }
    }
    
    private func saveAssetToLibrary(_ asset: AVAsset, completion: ((Bool) -> Void)? = nil) {
        self.exportAsset(asset) { (url, ok) in
            if ok {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }, completionHandler: { (ok, error) in
                    print("export ok? \(ok)")
                    completion?(ok)
                })
            }
        }
    }

}

