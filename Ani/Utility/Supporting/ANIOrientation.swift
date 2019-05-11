//
//  Orientation.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

struct ANIOrientation {
  
  static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
    
    if let delegate = UIApplication.shared.delegate as? AppDelegate {
      delegate.orientationLock = orientation
    }
  }
  
  static func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation:UIInterfaceOrientation) {
    
    self.lockOrientation(orientation)
    
    UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
  }
  
}
