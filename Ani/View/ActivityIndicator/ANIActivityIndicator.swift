//
//  ANIActivityIndicator.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/11.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIActivityIndicator: UIView {
  
  private weak var backgrounView: UIView?
  
  private let imageNames: [String] = ["splashFoot1", "splashFoot2", "splashFoot3", "splashFoot4", "splashFoot5"]
  private var imageViews: [UIImageView]?
  
  var isAnimatedOneCycle: Bool = false {
    didSet {
      ANINotificationManager.postDismissSplash()
    }
  }
  var isSplash: Bool = false
  
  var isFull: Bool = false {
    didSet {
      if isFull {
        setupFullSize()
      } else {
        setup()
      }
    }
  }
  
  private var isAnimating: Bool = true
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    self.isHidden = true
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    for (index, imageName) in imageNames.enumerated() {
      let imageView = UIImageView()
      imageView.contentMode = .scaleAspectFit
      if index == 0 {
        imageView.alpha = 1.0
      } else {
        imageView.alpha = 0.0
      }
      imageView.image = UIImage(named: imageName)
      if self.imageViews != nil {
        self.imageViews?.append(imageView)
      } else {
        self.imageViews = [imageView]
      }
      self.addSubview(imageView)
      imageView.centerInSuperview()
      imageView.width(43.0)
      imageView.height(35.0)
    }
  }
  
  private func setupFullSize() {
    let backgrounView = UIView()
    backgrounView.alpha = 0.0
    backgrounView.backgroundColor = .black
    self.addSubview(backgrounView)
    backgrounView.edgesToSuperview()
    self.backgrounView = backgrounView
    
    setup()
  }
  
  func startAnimating() {
    stopAnimating()
    
    if let backgrounView = self.backgrounView {
      backgrounView.alpha = 0.5
    }
    
    isAnimating = true

    self.loopAnimation()
    
    self.isHidden = false
  }
  
  func stopAnimating() {
    DispatchQueue.main.async {
      if let backgrounView = self.backgrounView {
        backgrounView.alpha = 0.0
      }
      
      self.isAnimating = false
      
      self.isHidden = true
    }
  }
  
  private func animation(index: Int, completion:(()->())?) {
    guard let imageViews = self.imageViews else { return }

    UIView.animate(withDuration: 0.3, animations: {
      if imageViews.count > index {
        imageViews[index].alpha = 1.0
      }
    }) { (complete) in
      completion?()
    }
  }

  private func loopAnimation(isFirst: Bool = true) {
    guard let imageViews = self.imageViews,
          isAnimating else { return }
    
    let duration = isFirst ? 0.0 : 0.3
    UIView.animate(withDuration: duration, animations: {
      for (index, imageView) in imageViews.enumerated() {
        if index != 0 {
          imageView.alpha = 0.0
        }
      }
    }) { (complete) in
      self.animation(index: 1, completion: {
        self.animation(index: 2, completion: {
          self.animation(index: 3, completion: {
            self.animation(index: 4, completion: {
              if self.isSplash {
                self.isAnimatedOneCycle = true
              }
              self.loopAnimation(isFirst: false)
            })
          })
        })
      })
    }
  }
}
