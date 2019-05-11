//
//  ANIInitialViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/23.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseAuth
import SafariServices
import TinyConstraints
import FirebaseFirestore
import CodableFirebase
import Firebase

class ANIInitialViewController: UIViewController {
  
  private var initialViewBottomConstraint: Constraint?
  private weak var initialView: ANIInitialView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: UIView?
  private weak var rejectBaseView: UIView?
  private weak var rejectLabel: UILabel?
  private var isRejectAnimating: Bool = false

  private weak var activityIndicatorView: ANIActivityIndicator?
  
  var myTabBarController: ANITabBarController?
  
  override func viewDidLoad() {
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    UIApplication.shared.statusBar?.alpha = 0.0
    setupNotifications()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    UIApplication.shared.statusBar?.alpha = 1.0
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
  }
  
  private func setup() {
    //basic
    ANIOrientation.lockOrientation(.portrait)
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    
    //initialView
    let initialView = ANIInitialView()
    initialView.myTabBarController = myTabBarController
    initialView.delegate = self
    self.view.addSubview(initialView)
    initialView.edgesToSuperview(excluding: .bottom)
    initialViewBottomConstraint = initialView.bottomToSuperview()
    self.initialView = initialView
    
    //rejectView
    let rejectView = UIView()
    rejectView.backgroundColor = ANIColor.darkGray
    self.view.addSubview(rejectView)
    rejectViewBottomConstraint = rejectView.bottomToTop(of: self.view)
    rejectViewBottomConstraintOriginalConstant = rejectViewBottomConstraint?.constant
    rejectView.leftToSuperview()
    rejectView.rightToSuperview()
    rejectView.height(UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT)
    self.rejectView = rejectView
    
    //rejectBaseView
    let rejectBaseView = UIView()
    rejectBaseView.backgroundColor = ANIColor.darkGray
    rejectView.addSubview(rejectBaseView)
    rejectBaseView.edgesToSuperview(excluding: .top)
    rejectBaseView.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.rejectBaseView = rejectBaseView
    
    //rejectLabel
    let rejectLabel = UILabel()
    rejectLabel.textAlignment = .center
    rejectLabel.textColor = .white
    rejectLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
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
          let initialViewBottomConstraint = self.initialViewBottomConstraint else { return }
    
    let h = keyboardFrame.height
    
    initialViewBottomConstraint.constant = -h
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let initialViewBottomConstraint = self.initialViewBottomConstraint else { return }
    
    initialViewBottomConstraint.constant = 0.0
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
}

//MARK: ANIInitialViewDelegate
extension ANIInitialViewController: ANIInitialViewDelegate {
  func loginSuccess() {
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
  
  func signUpButtonTapped() {
    let signUpViewController = ANISignUpViewController()
    self.navigationController?.pushViewController(signUpViewController, animated: true)
  }
  
//  func showTerms() {
//    let urlString = "https://myau5.webnode.jp/%E5%88%A9%E7%94%A8%E8%A6%8F%E7%B4%84/"
//    guard let url = URL(string: urlString) else { return }
//    
//    let safariVC = SFSafariViewController(url: url)
//    present(safariVC, animated: true, completion: nil)
//  }
//  
//  func showPrivacyPolicy() {
//    let urlString = "https://myau5.webnode.jp/プライバシーポリシー/"
//    guard let privacyPolicyUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
//          let url = URL(string: privacyPolicyUrl) else { return }
//    
//    let safariVC = SFSafariViewController(url: url)
//    present(safariVC, animated: true, completion: nil)
//  }
  
  func reject(notiText: String) {
    guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
          let rejectLabel = self.rejectLabel,
          !isRejectAnimating else { return }
    
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

//MARK: UIGestureRecognizerDelegate
extension ANIInitialViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
