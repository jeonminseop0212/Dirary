//
//  AVFileType.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/18.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVKit

extension AVFileType {
  /// Fetch and extension for a file from UTI string
  var fileExtension: String {
    if let ext = UTTypeCopyPreferredTagWithClass(self as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() {
      return ext as String
    }
    return "None"
  }
}
