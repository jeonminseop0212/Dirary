//
//  ANILoginViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/23.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

class ANILoginViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBarBase: UIView?
  private weak var backButton: UIButton?
  
  private var loginViewOriginalBottomConstraintConstant: CGFloat?
  private var loginViewBottomConstraint: Constraint?
  private weak var loginView: ANILoginView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: UIView?
  private weak var rejectBaseView: UIView?
  private weak var rejectLabel: UILabel?
  private var isRejectAnimating: Bool = false
  
  var myTabBarController: ANITabBarController?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  override func viewDidLoad() {
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    setupNotifications()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
  }
  
  private func setup() {
    //basic
    self.view.backgroundColor = .white
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = .white
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview()
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //myNavigationBarBase
    let myNavigationBarBase = UIView()
    myNavigationBar.addSubview(myNavigationBarBase)
    myNavigationBarBase.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    myNavigationBarBase.bottomToSuperview()
    myNavigationBarBase.leftToSuperview()
    myNavigationBarBase.rightToSuperview()
    self.myNavigationBarBase = myNavigationBarBase
    
    //backButton
    let backButton = UIButton()
    let dismissButtonImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate)
    backButton.setImage(dismissButtonImage, for: .normal)
    backButton.tintColor = ANIColor.dark
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBarBase.addSubview(backButton)
    backButton.width(UIViewController.NAVIGATION_BAR_HEIGHT)
    backButton.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    backButton.leftToSuperview()
    backButton.centerYToSuperview()
    self.backButton = backButton
    
    //loginView
    let loginView = ANILoginView()
    loginView.myTabBarController = myTabBarController
    loginView.delegate = self
    self.view.addSubview(loginView)
    loginView.topToBottom(of: myNavigationBar)
    loginView.leftToSuperview()
    loginView.rightToSuperview()
    loginViewBottomConstraint = loginView.bottomToSuperview()
    rejectViewBottomConstraintOriginalConstant = loginViewBottomConstraint?.constant
    self.loginView = loginView
    
    //rejectView
    let rejectView = UIView()
    rejectView.backgroundColor = ANIColor.emerald
    self.view.addSubview(rejectView)
    rejectViewBottomConstraint = rejectView.bottomToTop(of: self.view)
    rejectViewBottomConstraintOriginalConstant = rejectViewBottomConstraint?.constant
    rejectView.leftToSuperview()
    rejectView.rightToSuperview()
    rejectView.height(UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT)
    self.rejectView = rejectView
    
    //rejectBaseView
    let rejectBaseView = UIView()
    rejectBaseView.backgroundColor = ANIColor.emerald
    rejectView.addSubview(rejectBaseView)
    rejectBaseView.edgesToSuperview(excluding: .top)
    rejectBaseView.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.rejectBaseView = rejectBaseView
    
    //rejectLabel
    let rejectLabel = UILabel()
    rejectLabel.textAlignment = .center
    rejectLabel.textColor = .white
    rejectLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
    rejectLabel.text = "ユーザーが見つかりません！"
    rejectLabel.textAlignment = .center
    rejectBaseView.addSubview(rejectLabel)
    rejectLabel.edgesToSuperview()
    self.rejectLabel = rejectLabel
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = true
    self.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
    ANINotificationManager.receive(keyboardWillHide: self, selector: #selector(keyboardWillHide))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let loginViewBottomConstraint = self.loginViewBottomConstraint else { return }
    
    let h = keyboardFrame.height
    
    loginViewBottomConstraint.constant = -h
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let loginViewOriginalBottomConstraintConstant = self.loginViewOriginalBottomConstraintConstant,
          let loginViewBottomConstraint = self.loginViewBottomConstraint else { return }
    
    loginViewBottomConstraint.constant = loginViewOriginalBottomConstraintConstant
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  //MARK: action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
}

//MARK: ANILoginViewDelegate
extension ANILoginViewController: ANILoginViewDelegate {
  func loginSuccess() {
    ANINotificationManager.postLogin()

    ANISessionManager.shared.isHiddenInitial = true
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
  
  func reject(notiText: String) {
    guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
          !isRejectAnimating,
          let rejectLabel = self.rejectLabel else { return }
    
    rejectLabel.text = notiText
    
    rejectViewBottomConstraint.constant = UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
      self.isRejectAnimating = true
      self.view.layoutIfNeeded()
    }) { (complete) in
      guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
            let rejectViewBottomConstraintOriginalConstant = self.rejectViewBottomConstraintOriginalConstant else { return }
      
      rejectViewBottomConstraint.constant = rejectViewBottomConstraintOriginalConstant
      UIView.animate(withDuration: 0.3, delay: 1.0, options: .curveEaseInOut, animations: {
        self.view.layoutIfNeeded()
      }, completion: { (complete) in
        self.isRejectAnimating = false
      })
    }
  }
  
  func startAnimaing() {
    self.activityIndicatorView?.startAnimating()
  }
  
  func stopAnimating() {
    self.activityIndicatorView?.stopAnimating()
  }
}
