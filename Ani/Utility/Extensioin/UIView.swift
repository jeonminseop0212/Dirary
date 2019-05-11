//
//  UIView.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/24.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

extension UIView {
  func dropShadow(
    color:UIColor = UIColor(red:0, green:0, blue:0, alpha:1),
    opacity:Float = 0.05,
    offset:CGSize = CGSize(width:0, height:5),
    radius:CGFloat = 5.0) {
    self.layer.shadowColor = color.cgColor
    self.layer.shadowOpacity = opacity
    self.layer.shadowOffset = offset
    self.layer.shadowRadius = radius
    self.layer.shouldRasterize = true
    self.layer.rasterizationScale = UIScreen.main.scale
  }
  
  var x:CGFloat {
    get { return self.frame.origin.x }
    set(v) { self.frame.origin.x = v }
  }
  var y:CGFloat {
    get { return self.frame.origin.y }
    set(v) { self.frame.origin.y = v }
  }
  var width:CGFloat {
    get { return self.frame.size.width }
    set(v) { self.frame.size.width = v }
  }
  var height:CGFloat {
    get { return self.frame.size.height }
    set(v) { self.frame.size.height = v }
  }
  var right:CGFloat {
    get { return self.x + self.width }
    set(v) { self.x = v - self.width }
  }
  var bottom:CGFloat {
    get { return self.y + self.height }
    set(v) { self.y = v - self.height }
  }
}
