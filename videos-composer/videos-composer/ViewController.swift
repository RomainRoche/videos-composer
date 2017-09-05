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

class VCCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: IBoutlets
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        if (picker.sourceType == .camera) {
            self.installCapturedVideo(moviePath)
        } else if (picker.sourceType == .photoLibrary) {
            self.installSavedVideo(moviePath)
        }
        self.dismiss(animated: true)
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
    
    private func installCapturedVideo(_ imageURL: URL!) {
        // Dispatched on main because for some reason adding the layer could
        // not work... TODO: fix that
        DispatchQueue.main.async {
            self.capturedPlayer?.pause()
            self.capturedPlayerLayer?.removeFromSuperlayer()
            self.capturedPlayer = AVPlayer(url: imageURL)
            self.capturedPlayerLayer = AVPlayerLayer(player: self.capturedPlayer)
            self.capturedPlayerLayer!.frame = (self.capturedVideoView?.bounds)!
            self.capturedVideoView?.layer.addSublayer(self.capturedPlayerLayer!)
            self.capturedPlayer?.isMuted = true // no sound
            self.capturedPlayer?.play()
        }
    }
    
    private func installSavedVideo(_ imageURL: URL! ) {
        DispatchQueue.main.async {
            self.savedPlayer?.pause()
            self.savedPlayerLayer?.removeFromSuperlayer()
            self.savedPlayer = AVPlayer(url: imageURL)
            self.savedPlayerLayer = AVPlayerLayer(player: self.savedPlayer)
            self.savedPlayerLayer!.frame = (self.savedVideoView?.bounds)!
            self.savedVideoView?.layer.addSublayer(self.savedPlayerLayer!)
            self.savedPlayer?.isMuted = true // no sound
            self.savedPlayer?.play()
        }
    }

}

