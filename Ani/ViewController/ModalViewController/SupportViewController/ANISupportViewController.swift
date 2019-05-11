//
//  SuportViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/19.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

class ANISupportViewController: UIViewController {
  
  private let SUPPORT_VIEW_HEIGHT: CGFloat = 220.0
  private var supportViewCenterYConstraint: Constraint?
  private weak var supportView: ANISupportView?
  
  var recruit: FirebaseRecruit?
  
  var user: FirebaseUser?
  
  private var isKeyboardShow: Bool = false
  
  override func viewDidLoad() {
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    setupNotifications()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    supprotViewPop()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
  }
  
  private func setup() {
    //basic
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(supportViewDismiss))
    self.view.addGestureRecognizer(tapGestureRecognizer)
    
    //supportView
    let supportView = ANISupportView()
    supportView.alpha = 0.0
    supportView.delegate = self
    if let recruit = self.recruit {
      supportView.recruit = recruit
    }
    if let user = self.user {
      supportView.user = user
    }
    self.view.addSubview(supportView)
    supportViewCenterYConstraint = supportView.centerYToSuperview()
    supportView.leftToSuperview(offset: 10.0)
    supportView.rightToSuperview(offset: -10.0)
    supportView.height(SUPPORT_VIEW_HEIGHT)
    self.supportView = supportView
  }
  
  private func supprotViewPop() {
    guard let supportView = self.supportView else { return }
    
    UIView.animate(withDuration: 0.2) {
      self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
      supportView.alpha = 1.0
    }
  }
  
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(keyboardWillShow: self, selector: #selector(keyboardWillShow))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func supportViewDismiss() {
    guard let supportView = self.supportView else { return }
    
    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
      self.view.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
      supportView.alpha = 0.0
    }, completion: { (complete) in
      self.dismiss(animated: false, completion: nil)
    })
  }
  
  @objc private func keyboardWillShow(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let supportView = self.supportView,
          let supportViewCenterYConstraint = self.supportViewCenterYConstraint else { return }

    if supportView.frame.maxY > (keyboardFrame.origin.y - 50) && isKeyboardShow == false {
      supportViewCenterYConstraint.constant = -(supportView.frame.maxY - (keyboardFrame.origin.y - 50))
      
      UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
        self.view.layoutIfNeeded()
      })
    }
    
    isKeyboardShow = true
  }
}

//MARK: ANISupportViewDelegate
extension ANISupportViewController: ANISupportViewDelegate {
  func supportButtonTapped() {    
    supportViewDismiss()
  }
}
