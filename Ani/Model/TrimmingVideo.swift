//
//  TrimmingVideo.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/19.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import Gallery
import AVKit

struct TrimmingVideo {
  let video: Video
  let avAsset: AVAsset
  let coverImage: UIImage
  let timeRange: CMTimeRange
}
