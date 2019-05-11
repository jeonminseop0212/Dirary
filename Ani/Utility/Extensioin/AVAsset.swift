//
//  AVAsset.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/18.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import AVFoundation

extension AVAsset {
  func assetByTrimming(startTime: CMTime, endTime: CMTime) throws -> AVAsset {
    let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
    let composition = AVMutableComposition()
    do {
      for track in tracks {
        let compositionTrack = composition.addMutableTrack(withMediaType: track.mediaType,
                                                           preferredTrackID: track.trackID)
        try compositionTrack?.insertTimeRange(timeRange, of: track, at: CMTime.zero)
      }
    } catch let error {
      throw error
    }
    
    if let videoTrack = self.tracks(withMediaType: .video).last,
      let compositionTrack = composition.tracks(withMediaType: .video).last {
      compositionTrack.preferredTransform = videoTrack.preferredTransform
    }
    
    return composition
  }
}
