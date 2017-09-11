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

extension AVPlayer {
    
    func currentItemResolution() -> CGSize? {
        guard let tracks = self.currentItem?.asset.tracks(withMediaType: AVMediaTypeVideo)
            , tracks.count > 0 else {
                return nil
        }
        let track = tracks[0]
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playbackDidEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.capturedPlayer?.currentItem)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playbackDidEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: self.savedPlayer?.currentItem)
        if (self.capturedPlayer?.currentItem != nil) {
            self.capturedPlayer?.play()
        }
        if (self.savedPlayer?.currentItem != nil) {
            self.savedPlayer?.play()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
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

    @IBAction
    private func captureFirstVideo() {
        if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            print("no camera available")
            return
        }
        self.getVideo(.camera)
    }
    
    @IBAction
    private func getSecondVideo() {
        if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)) {
            print("no photo library")
            return
        }
        self.getVideo(.photoLibrary)
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
        print("player video size: \(player?.currentItemResolution()?.width ?? 0)x\(player?.currentItemResolution()?.height ?? 0)")
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = (view?.bounds)!
        view?.layer.addSublayer(playerLayer!)
        player?.isMuted = true
        player?.play()
    }

}

