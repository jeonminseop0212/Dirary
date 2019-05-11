//
//  ANIImageButtonView.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/24.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

class ANIImageButtonView: ANIButtonView {
  
  var imageView: UIImageView?
  private var imageWidthConst: Constraint?
  private var imageHeightConst: Constraint?
  
  var imageSize:CGSize = .zero{
    didSet {
      if self.imageWidthConst == nil {
        if imageSize == .zero, let size = self.imageView?.image?.size {
          self.imageWidthConst = self.imageView?.width(size.width, priority: LayoutPriority.defaultHigh)
        } else {
          self.imageWidthConst = self.imageView?.width(imageSize.width, priority: LayoutPriority.defaultHigh)
        }
      } else {
        if imageSize == .zero, let size = self.imageView?.image?.size {
          self.imageWidthConst?.constant = size.width
        } else {
          self.imageWidthConst?.constant = imageSize.width
        }
      }
      
      if self.imageHeightConst == nil {
        if imageSize == .zero, let size = self.imageView?.image?.size {
          self.imageHeightConst = self.imageView?.height(size.height, priority: LayoutPriority.defaultHigh)
        } else {
          self.imageHeightConst = self.imageView?.height(imageSize.height, priority: LayoutPriority.defaultHigh)
        }
      } else {
        if imageSize == .zero, let size = self.imageView?.image?.size {
          self.imageHeightConst?.constant = size.height
        } else {
          self.imageHeightConst?.constant = imageSize.height
        }
      }
      self.layoutIfNeeded()
    }
  }
  
  var image:UIImage?{
    get {
      return self.imageView?.image
    }
    set(v) {
      self.imageView?.image = v
      if imageSize == .zero, let size = v?.size{
        self.imageSize = size
      }
    }
  }
  
  override var tintColor: UIColor!{
    get {
      return self.imageView?.tintColor
    }
    set(v) {
      self.imageView?.tintColor = v
    }
  }
  
  override init(frame: CGRect = .zero) {
    super.init(frame: frame)
    self.setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup(){
    let iv = UIImageView()
    self.addSubview(iv)
    self.imageView = iv
    iv.contentMode = .scaleAspectFit
    iv.centerInSuperview()
  }
  
  override func touchDown(_ contain: Bool) {
    super.touchDown(contain)
    if isAnimation {
      UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut, animations: {
        self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
      })
    }
  }
  
  override func touchUp(_ contain: Bool) {
    super.touchUp(contain)
    if isAnimation {
      UIView.animate(withDuration: 0.2, delay: 0.2, options: .curveEaseInOut, animations: {
        self.transform = .identity
      })
    }
  }
  
  func superViewCornerRadius(radius: CGFloat) {
    self.layer.cornerRadius = radius
  }
  
  func superViewDropShadow(
    color:UIColor = UIColor(red:0, green:0, blue:0, alpha:1),
    opacity:Float = 0.05,
    offset:CGSize = CGSize(width:0, height:5),
    radius:CGFloat = 5.0) {
    self.dropShadow(color: color, opacity: opacity, offset: offset, radius: radius)
  }
}
