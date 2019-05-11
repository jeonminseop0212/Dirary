//
//  ANIDraggableView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/18.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIDraggableViewDelegate:class {
  func panGestureDidChange(_ panGesture:UIPanGestureRecognizer,originalCenter:CGPoint, translation:CGPoint)
  func panGestureDidEnd(_ panGesture:UIPanGestureRecognizer, originalCenter:CGPoint, translation:CGPoint)
}

class ANIDraggableView: UIView {
  
  weak var imageView: UIImageView?
  
  var scollViewZoomScale: CGFloat = 1.0
  
  private var originalPosition: CGPoint = CGPoint(x: 0.0, y: 0.0)
  var delegate: ANIDraggableViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setUp()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setUp(){
    isUserInteractionEnabled = true
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction))
    panGestureRecognizer.delegate = self
    self.addGestureRecognizer(panGestureRecognizer)
    
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .clear
    imageView.isUserInteractionEnabled = true
    addSubview(imageView)
    imageView.edgesToSuperview()
    self.imageView = imageView
  }
  
  @objc func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
    let translation = panGesture.translation(in: superview)
    
    switch panGesture.state {
    case .began:
      originalPosition = self.center
    case .changed:
      self.delegate?.panGestureDidChange(panGesture, originalCenter: originalPosition, translation: translation)
    case .ended:
      self.delegate?.panGestureDidEnd(panGesture, originalCenter: originalPosition, translation: translation)
    default:
      break
    }
  }
}

extension ANIDraggableView:UIGestureRecognizerDelegate {
  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let panGesture = gestureRecognizer as? UIPanGestureRecognizer, scollViewZoomScale == 1.0 {
      let position = panGesture.translation(in: self)
      if position.y != 0.0 {
        return true
      } else {
        return false
      }
    }
    
    return false
  }
}
