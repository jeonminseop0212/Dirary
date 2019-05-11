//
//  ANIAreaButtonView.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/28.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIAreaButtonView: ANIButtonView {
  weak var base:UIView?
  
  var baseBackgroundColor: UIColor?{
    get { return self.base?.backgroundColor }
    set(v) { self.base?.backgroundColor = v }
  }
  
  var baseCornerRadius: CGFloat{
    get { return self.base?.layer.cornerRadius ?? 0 }
    set(v) { self.base?.layer.cornerRadius = v }
  }
  
  override var frame: CGRect {didSet{reloadLayout()}}
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.backgroundColor = .clear
    let base = UIView(frame:self.bounds)
    base.backgroundColor = .white
    addSubview(base)
    self.base = base
    base.edgesToSuperview()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func addContent(_ view:UIView) {
    self.base?.addSubview(view)
  }
  
  private func reloadLayout() {
    guard let base = self.base else { return }
    base.frame = self.bounds
  }
  
  override func touchDown(_ contain: Bool) {
    super.touchDown(contain)
    if self.isAnimation {
      UIView.animate(withDuration: 0.2) {
        self.base?.transform = CGAffineTransform(scaleX:self.e, y:self.e)
      }
    }
  }
  
  override func touchUp(_ contain: Bool) {
    super.touchUp(contain)
    if isAnimation {
      UIView.animate(withDuration: 0.2, delay: 0.2, options: UIView.AnimationOptions.curveEaseInOut, animations: {
        self.base?.transform = CGAffineTransform.identity
      }, completion: nil)
    }
  }
}
