//
//  ANIAutoLoginViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/10/30.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseAuth
import FirebaseFirestore
import CodableFirebase

class ANIAutoLoginViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBarBase: UIView?
  private weak var backButton: UIButton?
  
  private weak var autoLoginView: ANIAutoLoginView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: UIView?
  private weak var rejectBaseView: UIView?
  private weak var rejectLabel: UILabel?
  private var isRejectAnimating: Bool = false
  
  var adress: String?
  var password: String?
  var userId: String?
  
  override func viewDidLoad() {
    setup()
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
    
    //autoLoginView
    let autoLoginView = ANIAutoLoginView()
    autoLoginView.delegate = self
    self.view.addSubview(autoLoginView)
    autoLoginView.topToBottom(of: myNavigationBar)
    autoLoginView.edgesToSuperview(excluding: .top)
    self.autoLoginView = autoLoginView
    
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
    rejectLabel.textAlignment = .center
    rejectBaseView.addSubview(rejectLabel)
    rejectLabel.edgesToSuperview()
    self.rejectLabel = rejectLabel
  }
  
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
  
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
}

//MARK: ANIAutoLoginViewDelegate
extension ANIAutoLoginViewController: ANIAutoLoginViewDelegate {
  func tappeLoginButton() {
    guard let adress = self.adress,
          let password = self.password,
          let userId = self.userId else { return }
    
    Auth.auth().signIn(withEmail: adress, password: password) { (successUser, error) in
      if let errorUnrap = error {
        DLog("loginError \(errorUnrap.localizedDescription)")
      } else {
        if let currentUser = Auth.auth().currentUser {
          if currentUser.isEmailVerified {
            let database = Firestore.firestore()
            
            DispatchQueue.global().async {
              database.collection(KEY_USERS).document(userId).addSnapshotListener({ (snapshot, error) in
                if let error = error {
                  DLog("Error adding document: \(error)")
                  
                  return
                }
                
                guard let snapshot = snapshot, let value = snapshot.data() else { return }
                
                do {
                  let user = try FirestoreDecoder().decode(FirebaseUser.self, from: value)
                  
                  DispatchQueue.main.async {
                    ANISessionManager.shared.isHiddenInitial = true

                    self.navigationController?.dismiss(animated: true, completion: {
                      ANISessionManager.shared.currentUser = user
                      ANISessionManager.shared.currentUserUid = currentUser.uid
                      ANISessionManager.shared.isAnonymous = false
                      
                      ANINotificationManager.postLogin()
                    })
                  }
                } catch let error {
                  DLog(error)
                }
              })
            }
          } else {
            self.reject(notiText: "アドレスの認証メールを確認してください！")
          }
        }
      }
    }
  }
}
