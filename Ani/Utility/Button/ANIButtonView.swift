//
//  ANIButtonView.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/24.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIButtonViewDelegate: NSObjectProtocol {
  func buttonViewTapped(view: ANIButtonView)
}

class ANIButtonView: UIView {
  weak var delegate: ANIButtonViewDelegate?
  var e: CGFloat = 0.9
  private var isDown: Bool = false
  var isAnimation: Bool = true
  
  convenience init() { self.init(frame: CGRect.zero) }
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    let gesture = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
    addGestureRecognizer(gesture)
  }
  required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
  
  //MARK: - Touches
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let p = touches.first?.location(in: self) else { return }
    let contain = self.bounds.contains(p)
    touchDown(contain)
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {}
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let p = touches.first?.location(in: self) else { return }
    let contain = self.bounds.contains(p)
    touchUp(contain)
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    touchUp(false)
  }
  
  //MARK: - Menu
  func touchDown(_ contain:Bool) {
    self.isDown = true
  }
  
  func touchUp(_ contain:Bool) {
    self.isDown = false
    if (contain) {
      self.delegate?.buttonViewTapped(view: self)
    }
  }
  
  //MARK: - Action
  @objc private func tapped(sender:UITapGestureRecognizer) {
    let p = sender.location(in: self)
    let contain = self.bounds.contains(p)
    if (!self.isDown) {
      touchDown(contain)
    }
    touchUp(contain)
  }
}
