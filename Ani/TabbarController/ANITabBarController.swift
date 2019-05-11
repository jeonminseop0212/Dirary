//
//  TabBarController.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/02.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import CodableFirebase

class ANITabBarController: UITabBarController {
  
  private weak var splashView: ANISplashView?
  
  private let BADGE_WIDHT: CGFloat = 5.0
  private weak var badge: UIView?
  
  private let NUMBER_OF_NOTI_TAB: Int = 2

  private var showingTabTag: Int = 0
  
  var isLoadedUser: Bool = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setup()
    setupTabBar()
    setupNotifications()
  }
  
  private func setup() {
    //basic
    ANIOrientation.lockOrientation(.portrait)
    
    //splashView
    let splashView = ANISplashView()
    self.view.addSubview(splashView)
    splashView.edgesToSuperview()
    self.splashView = splashView
    
    //tabBar上の線を消す
    let tabBarAppearane = UITabBar.appearance()
    tabBarAppearane.backgroundImage = UIImage()
    tabBarAppearane.shadowImage = UIImage()
    tabBarAppearane.backgroundColor = UIColor(red: 255, green: 255, blue: 255, a: 0.95)
    tabBar.layer.borderWidth = 0.0
    tabBar.clipsToBounds = true
    
    //update first launch
    let userDefaults = UserDefaults.standard
    if userDefaults.object(forKey: KEY_FIRST_LAUNCH) == nil {
      userDefaults.set(true, forKey: KEY_FIRST_LAUNCH)
    }
  }
  
  private func setupTabBar() {
    let diaryVC = ANIDiaryViewController()
    diaryVC.tabBarItem.image = UIImage(named: "diaryTap")?.withRenderingMode(.alwaysOriginal)
    diaryVC.tabBarItem.selectedImage = UIImage(named: "diaryTap")?.withRenderingMode(.alwaysOriginal)
    diaryVC.tabBarItem.tag = 0
    let diaryNV = UINavigationController(rootViewController: diaryVC)
    
    setViewControllers([diaryNV], animated: false)
    
    if let items = tabBar.items {
      for item in items {
        item.imageInsets = UIEdgeInsets.init(top: 4.0, left: 0.0, bottom: -4.0, right: 0.0)
      }
    }
  }
  
  override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    switch item.tag {
    case 0:
      if showingTabTag == 0 {
        ANINotificationManager.postCommunityTabTapped()
      }
      showingTabTag = 0
    default:
      DLog("default tab")
    }
  }
  
  private func ifNeedsShowInitialView() {    
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self
    let initialNV = UINavigationController(rootViewController: initialViewController)
    self.present(initialNV, animated: true, completion: nil)
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(dismissSplash: self, selector: #selector(dismissSplash))
    ANINotificationManager.receive(failLoadVersion: self, selector: #selector(showFailMessage))
    ANINotificationManager.receive(didSetupViewNotifications: self, selector: #selector(loadFirstData))
  }
  
  @objc private func dismissSplash() {
    guard let splashView = splashView,
          let activityIndicatorView = splashView.activityIndicatorView else { return }
    
    DispatchQueue.main.async {
      if ANISessionManager.shared.isLoadedFirstData && splashView.alpha != 0.0 && activityIndicatorView.isAnimatedOneCycle {
        UIView.animate(withDuration: 0.2, delay: 0.2, animations: {
          splashView.alpha = 0.0
        }, completion: { (complete) in
          activityIndicatorView.stopAnimating()

          ANIFunction.shared.showReviewAlertOpenApp()
          
          ANISessionManager.shared.isHiddenSplash = true
          self.showEventIfNeeded()
        })
      }
    }
  }
  
  
  @objc private func showFailMessage() {
    let alertController = UIAlertController(title: "データのローディングに失敗しました", message: "アプリを再起動してください。", preferredStyle: .alert)
    self.present(alertController, animated: true, completion: nil)
  }
  
  @objc private func loadFirstData() {
    loadUser()
  }
  
  private func showEventIfNeeded() {
    let database = Firestore.firestore()
    
    let userDefaults = UserDefaults.standard
    
    if ANISessionManager.shared.isHiddenInitial && ANISessionManager.shared.isHiddenSplash && ANISessionManager.shared.isCheckedVersion {
      DispatchQueue.global().async {
        database.collection(KEY_EVENTS).getDocuments(completion: { (snapshot, error) in
          if let error = error {
            DLog("get event document error \(error)")
            return
          }
          
          guard let snapshot = snapshot else { return }
          
          for document in snapshot.documents {
            do {
              let event = try FirestoreDecoder().decode(FirebaseEvent.self, from: document.data())
              
              if userDefaults.object(forKey: KEY_SHOW_EVENT) == nil {
                let showEvents = [Int]()
                userDefaults.set(showEvents, forKey: KEY_SHOW_EVENT)
              }
              
              if let eventId = Int(event.id),
                let showEvents = userDefaults.object(forKey: KEY_SHOW_EVENT) as? [Int],
                !showEvents.contains(eventId) {
                let eventPopupViewController = ANIEventPopupViewController()
                eventPopupViewController.event = event
                eventPopupViewController.modalPresentationStyle = .overCurrentContext
                self.present(eventPopupViewController, animated: false, completion: nil)
                
                userDefaults.set([eventId], forKey: KEY_SHOW_EVENT)
                
                ANISessionManager.shared.isShowEvent = true
              }
            } catch let error {
              DLog(error)
            }
          }
        })
      }
    }
  }
}

//MARK: data
extension ANITabBarController {
  func loadUser(completion:(()->())? = nil) {
    
    if Auth.auth().currentUser == nil {
      ifNeedsShowInitialView()
    }

    if let currentUser = Auth.auth().currentUser {
      ANISessionManager.shared.currentUserUid = currentUser.uid
      guard let currentUserUid = ANISessionManager.shared.currentUserUid else { return }
      
      let database = Firestore.firestore()

      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(currentUserUid).getDocument(completion: { (snapshot, error) in
          guard let snapshot = snapshot, let data = snapshot.data() else {
            self.signOut()
            return
          }
          
          do {
            let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
            
            DispatchQueue.main.async {
              ANISessionManager.shared.currentUser = user
              ANISessionManager.shared.currentUserUid = user.uid
              
              if !self.isLoadedUser {
                DispatchQueue.main.async {
                  ANINotificationManager.postLoadedCurrentUser()
                  
                  completion?()
                }
              }
            }
          } catch let error {
            DLog(error)
          }
        })
      }
    } else {
      signOut()
    }
  }
  
  private func signOut() {
    do {
      try Auth.auth().signOut()
      
      let userDefaults = UserDefaults.standard
      userDefaults.set(false, forKey: KEY_IS_TWITTER_SHARE)
      
      ANISessionManager.shared.currentUser = nil
      ANISessionManager.shared.currentUserUid = nil
      
      ANINotificationManager.postLogout()
    } catch let signOutError as NSError {
      DLog("signOutError \(signOutError)")
    }
  }
}
