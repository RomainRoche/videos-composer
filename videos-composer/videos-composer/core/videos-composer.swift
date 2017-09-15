//
//  videos-composer.swift
//  videos-composer
//
//  Created by Romain ROCHE on 15/09/2017.
//  Copyright © 2017 Romain ROCHE. All rights reserved.
//

import Foundation
import AVFoundation

class VideosComposer: NSObject {
    
    class func AppendVideos(_ items: [AVPlayerItem]!) -> AVAsset? {
        
        guard items.count > 0 else { return nil }
        
        let composition: AVMutableComposition = AVMutableComposition()
        let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: kCMPersistentTrackID_Invalid)!
        let audioTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: AVMediaType.audio, preferredTrackID: kCMPersistentTrackID_Invalid)!
        
        do {
            var setSize: Bool = true
            try items.forEach({ (item: AVPlayerItem) throws in
                
                // add video track (if exists)
                if item.asset.tracks(withMediaType: .video).count > 0 {
                    
                    // range to take for the item asset tracks and current duration of the composition
                    let range: CMTimeRange = CMTimeRange(start: kCMTimeZero, duration: item.asset.duration)
                    let duration: CMTime = composition.duration
                    
                    let video = item.asset.tracks(withMediaType: .video)[0]
                    try videoTrack.insertTimeRange(range, of: video, at: duration)
                    if (setSize) {
                        composition.naturalSize = video.naturalSize
                        setSize = false
                    }
                    
                    // add audio track (if exists)
                    if item.asset.tracks(withMediaType: .audio).count > 0 {
                        let audio = item.asset.tracks(withMediaType: .audio)[0]
                        try audioTrack.insertTimeRange(range, of: audio, at: duration)
                    }
                    
                }
                
            })
            return composition
        } catch {
            print("error generating video")
        }
        
        return nil
    }
    
}
