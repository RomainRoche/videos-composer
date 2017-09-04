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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet private var firstButton: UIButton?
    @IBOutlet private var secondButtin: UIButton?
    @IBOutlet private var capturedVideoView: UIView?
    
    private var capturedVideo: NSData?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    
    override public var shouldAutorotate: Bool {
        get {
            return false;
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let moviePath = info[UIImagePickerControllerMediaURL] as! URL!
        self.installCapturedVideo(moviePath)
        self.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true)
    }

    @IBAction
    private func captureFirstVideo() {
        
        if (!UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)) {
            print("no camera available")
            return
        }
        
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = UIImagePickerControllerSourceType.camera
        picker.mediaTypes = [kUTTypeMovie as String]
        self.present(picker, animated: true)
        
    }
    
    @IBAction
    private func getSecondVideo() {
        print("getting second video")
    }
    
    private func installCapturedVideo(_ imageURL: URL!) {
        self.player?.pause()
        self.playerLayer?.removeFromSuperlayer()
        self.player = AVPlayer(url: imageURL)
        self.playerLayer = AVPlayerLayer(player: player)
        self.playerLayer!.frame = (self.capturedVideoView?.bounds)!
        self.capturedVideoView?.layer.addSublayer(self.playerLayer!)
        self.player?.isMuted = true // no sound
        self.player?.play()
    }

}

