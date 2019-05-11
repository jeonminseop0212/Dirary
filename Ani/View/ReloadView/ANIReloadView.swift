//
//  ANIReloadView.swift
//  Ani
//
//  Created by jeonminseop on 2018/09/07.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIReloadViewDelegate {
  func reloadButtonTapped()
}

class ANIReloadView: UIView {
  
  private let BASE_VIEW_HEIGHT: CGFloat = 200.0
  private weak var baseView: UIView?
  
  private weak var messegeLabel: UILabel?
  
  private var RELOAD_BUTTON_HEIGHT: CGFloat = 60.0
  private weak var reloadButton: ANIImageButtonView?
  
  var messege = "" {
    didSet {
      guard let messegeLabel = self.messegeLabel else { return }
      
      messegeLabel.text = messege
    }
  }
  
  var delegate: ANIReloadViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    set()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func set() {
    //baseView
    let baseView = UIView()
    baseView.backgroundColor = .white
    baseView.layer.cornerRadius = 10.0
    baseView.layer.masksToBounds = true
    addSubview(baseView)
    baseView.height(BASE_VIEW_HEIGHT)
    baseView.edgesToSuperview()
    self.baseView = baseView
    
    //reloadButton
    let reloadButton = ANIImageButtonView()
    reloadButton.image = UIImage(named: "reloadButton")
    reloadButton.delegate = self
    baseView.addSubview(reloadButton)
    reloadButton.centerXToSuperview()
    reloadButton.centerYToSuperview(offset: 20.0)
    reloadButton.width(RELOAD_BUTTON_HEIGHT)
    reloadButton.height(RELOAD_BUTTON_HEIGHT)
    self.reloadButton = reloadButton
    
    //messegeLabel
    let messegeLabel = UILabel()
    messegeLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    messegeLabel.textColor = ANIColor.dark
    messegeLabel.text = "まだないです"
    messegeLabel.textAlignment = .center
    baseView.addSubview(messegeLabel)
    messegeLabel.leftToSuperview()
    messegeLabel.rightToSuperview()
    messegeLabel.bottomToTop(of: reloadButton, offset: -20)
    self.messegeLabel = messegeLabel
  }
}

//MARK: ANIButtonViewDelegate
extension ANIReloadView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === reloadButton {
      self.delegate?.reloadButtonTapped()
    }
  }
}
