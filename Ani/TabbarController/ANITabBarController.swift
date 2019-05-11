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
import GoogleSignIn

class ANITabBarController: UITabBarController {
  
  private weak var splashView: ANISplashView?
  
  private let BADGE_WIDHT: CGFloat = 5.0
  private weak var badge: UIView?
  
  private let NUMBER_OF_NOTI_TAB: Int = 2

  private var showingTabTag: Int = 0
  
  private var oldIsHaveUnreadNoti: Bool = false
  private var oldIsHaveUnreadMessage: Bool = false
  
  private var userListener: ListenerRegistration?
  private var blockUserListener: ListenerRegistration?
  private var blockingUserListener: ListenerRegistration?
  private var chatGroupListener: ListenerRegistration?
  
  var isLoadedFirstData: Bool = false
  var isLoadedUser: Bool = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setup()
    setupTabBar()
    setupBadge()
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
    let communityVC = ANICommunityViewController()
    communityVC.tabBarItem.image = UIImage(named: "community")?.withRenderingMode(.alwaysOriginal)
    communityVC.tabBarItem.selectedImage = UIImage(named: "communitySelected")?.withRenderingMode(.alwaysOriginal)
    communityVC.tabBarItem.tag = 0
    let communityNV = UINavigationController(rootViewController: communityVC)
    
    let recruitVC = ANIRecruitViewController()
    recruitVC.tabBarItem.image = UIImage(named: "recruit")?.withRenderingMode(.alwaysOriginal)
    recruitVC.tabBarItem.selectedImage = UIImage(named: "recruitSelected")?.withRenderingMode(.alwaysOriginal)
    recruitVC.tabBarItem.tag = 1
    let recruitNV = UINavigationController(rootViewController: recruitVC)
    
    let notiVC = ANINotiViewController()
    notiVC.tabBarItem.image = UIImage(named: "noti")?.withRenderingMode(.alwaysOriginal)
    notiVC.tabBarItem.selectedImage = UIImage(named: "notiSelected")?.withRenderingMode(.alwaysOriginal)
    notiVC.tabBarItem.tag = 2
    let notiNV = UINavigationController(rootViewController: notiVC)
    
    let searchVC = ANISearchViewController()
    searchVC.tabBarItem.image = UIImage(named: "search")?.withRenderingMode(.alwaysOriginal)
    searchVC.tabBarItem.selectedImage = UIImage(named: "searchSelected")?.withRenderingMode(.alwaysOriginal)
    searchVC.tabBarItem.tag = 3
    let searchNV = UINavigationController(rootViewController: searchVC)
    
    let profileVC = ANIProfileViewController()
    profileVC.tabBarItem.image = UIImage(named: "profile")?.withRenderingMode(.alwaysOriginal)
    profileVC.tabBarItem.selectedImage = UIImage(named: "profileSelected")?.withRenderingMode(.alwaysOriginal)
    profileVC.tabBarItem.tag = 4
    let profileNV = UINavigationController(rootViewController: profileVC)
    
    setViewControllers([communityNV, recruitNV, notiNV, searchNV, profileNV], animated: false)
    
    if let items = tabBar.items {
      for item in items {
        item.imageInsets = UIEdgeInsets.init(top: 4.0, left: 0.0, bottom: -4.0, right: 0.0)
      }
    }
  }
  
  private func setupBadge() {
    if self.tabBar.subviews.count > NUMBER_OF_NOTI_TAB {
      let tabBarButton = self.tabBar.subviews[NUMBER_OF_NOTI_TAB]
      for subView in tabBarButton.subviews {
        guard let icon = subView as? UIImageView else { continue }

        let badge = UIView()
        badge.backgroundColor = ANIColor.red
        badge.layer.cornerRadius = BADGE_WIDHT / 2
        badge.layer.masksToBounds = true
        badge.alpha = 0.0
        icon.addSubview(badge)
        badge.centerX(to: icon, icon.rightAnchor)
        badge.centerY(to: icon, icon.topAnchor, offset: 2)
        badge.width(BADGE_WIDHT)
        badge.height(BADGE_WIDHT)
        self.badge = badge
        
        break
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
    case 1:
      if showingTabTag == 1 {
        ANINotificationManager.postRecruitTabTapped()
      }
      showingTabTag = 1
    case 2:
      if showingTabTag == 2 {
        ANINotificationManager.postNotiTabTapped()
      }
      showingTabTag = 2
    case 3:
      if showingTabTag == 3 {
        ANINotificationManager.postSearchTabTapped()
      }
      showingTabTag = 3
    case 4:
      if showingTabTag == 4 {
        ANINotificationManager.postProfileTabTapped()
      }
      showingTabTag = 4
    default:
      DLog("default tab")
    }
  }
  
  private func ifNeedsShowInitialView() {
    let userDefaults = UserDefaults.standard
    
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self
    let initialNV = UINavigationController(rootViewController: initialViewController)
    self.present(initialNV, animated: true, completion: nil)
    
    userDefaults.set(false, forKey: KEY_FIRST_LAUNCH)
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(changeIsHaveUnreadNoti: self, selector: #selector(updateBadge))
    ANINotificationManager.receive(changeIsHaveUnreadMessage: self, selector: #selector(updateBadge))
    ANINotificationManager.receive(logout: self, selector: #selector(logout))
    ANINotificationManager.receive(dismissSplash: self, selector: #selector(dismissSplash))
    ANINotificationManager.receive(failLoadVersion: self, selector: #selector(showFailMessage))
    ANINotificationManager.receive(didSetupViewNotifications: self, selector: #selector(loadFirstData))
  }
  
  @objc private func updateBadge() {
    guard let badge = self.badge else { return }
    
    if ANISessionManager.shared.isHaveUnreadNoti || ANISessionManager.shared.isHaveUnreadMessage {
      badge.alpha = 1.0
    } else {
      badge.alpha = 0.0
    }
  }
  
  @objc private func logout() {
    guard let userListener = self.userListener,
          let blockUserListener = self.blockUserListener,
          let blockingUserListener = self.blockingUserListener,
          let chatGroupListener = self.chatGroupListener else { return }
    
    userListener.remove()
    blockUserListener.remove()
    blockingUserListener.remove()
    chatGroupListener.remove()
    
    ANISessionManager.shared.isHaveUnreadNoti = false
    ANISessionManager.shared.isHaveUnreadMessage = false
    
    oldIsHaveUnreadNoti = false
    oldIsHaveUnreadMessage = false
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
    if !isLoadedFirstData {
      loadUser()
      observeChatGroup()
    }
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
    var isAuthenticated = false
    if let currentUser = Auth.auth().currentUser, currentUser.providerData.count == 1 {
      for userInfo in currentUser.providerData {
        if userInfo.providerID == "password" {
          isAuthenticated = currentUser.isEmailVerified
        } else {
          isAuthenticated = true
        }
      }
    } else {
      isAuthenticated = true
    }
    
    let userDefaults = UserDefaults.standard
    
    if let userListener = self.userListener {
      userListener.remove()
    }
    if let blockUserListener = self.blockUserListener {
      blockUserListener.remove()
    }
    if let blockingUserListener = self.blockingUserListener {
      blockingUserListener.remove()
    }
    if ANISessionManager.shared.blockUserIds != nil {
      ANISessionManager.shared.blockUserIds?.removeAll()
    }
    if ANISessionManager.shared.blockingUserIds != nil {
      ANISessionManager.shared.blockingUserIds?.removeAll()
    }
    
    if Auth.auth().currentUser != nil {
      if !isAuthenticated {
        signOut()
      }
    } else if userDefaults.bool(forKey: KEY_FIRST_LAUNCH) {
      signOut()
      ANISessionManager.shared.isHiddenInitial = false
      ifNeedsShowInitialView()
    }

    if let currentUser = Auth.auth().currentUser, isAuthenticated {
      ANISessionManager.shared.currentUserUid = currentUser.uid
      guard let currentUserUid = ANISessionManager.shared.currentUserUid else { return }
      
      let database = Firestore.firestore()
      let group = DispatchGroup()
      
      if !self.isLoadedFirstData {
        group.enter()
      }
      DispatchQueue(label: "user").async {
        self.userListener = database.collection(KEY_USERS).document(currentUserUid).addSnapshotListener({ (snapshot, error) in
          guard let snapshot = snapshot, let data = snapshot.data() else {
            self.signOut()
            return
          }
          
          do {
            let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
            
            DispatchQueue.main.async {
              ANISessionManager.shared.currentUser = user
              ANISessionManager.shared.isAnonymous = false
              
              if let isHaveUnreadNoti = user.isHaveUnreadNoti {
                if self.oldIsHaveUnreadNoti != isHaveUnreadNoti {
                  ANISessionManager.shared.isHaveUnreadNoti = isHaveUnreadNoti
                }
                
                self.oldIsHaveUnreadNoti = isHaveUnreadNoti
              }
              
              if !self.isLoadedFirstData && !self.isLoadedUser {
                group.leave()
                self.isLoadedUser = true
              }
            }
          } catch let error {
            DLog(error)
          }
        })
      }
      
      if !self.isLoadedFirstData {
        group.enter()
      }
      DispatchQueue(label: "user").async {
        self.blockUserListener =  database.collection(KEY_USERS).document(currentUserUid).collection(KEY_BLOCK_USER_IDS).order(by: KEY_DATE).addSnapshotListener({ (snapshot, error) in
          guard let snapshot = snapshot else { return }
          
          snapshot.documentChanges.forEach({ (diff) in
            if diff.type == .added {
              let data = diff.document.data()
              if let userId = data[KEY_USER_ID] as? String {
                if ANISessionManager.shared.blockUserIds != nil {
                  ANISessionManager.shared.blockUserIds?.insert(userId, at: 0)
                } else {
                  ANISessionManager.shared.blockUserIds = [userId]
                }
              }
              
              if snapshot.documents.count == ANISessionManager.shared.blockUserIds?.count, !self.isLoadedFirstData {
                group.leave()
              }
            } else if diff.type == .removed {
              guard let blockUserIds = ANISessionManager.shared.blockUserIds else { return }
              
              let data = diff.document.data()
              
              for (index, blockUserId) in blockUserIds.enumerated() {
                if let userId = data[KEY_USER_ID] as? String, userId == blockUserId {
                  ANISessionManager.shared.blockUserIds?.remove(at: index)
                }
              }
            }
          })
          
          if snapshot.documents.isEmpty, !self.isLoadedFirstData {
            group.leave()
          }
        })
      }
      
      if !self.isLoadedFirstData {
        group.enter()
      }
      DispatchQueue(label: "user").async {
        self.blockingUserListener = database.collection(KEY_USERS).document(currentUserUid).collection(KEY_BLOCKING_USER_IDS).order(by: KEY_DATE).addSnapshotListener({ (snapshot, error) in
          guard let snapshot = snapshot else { return }
          
          snapshot.documentChanges.forEach({ (diff) in
            if diff.type == .added {
              let data = diff.document.data()
              if let userId = data[KEY_USER_ID] as? String {
                if ANISessionManager.shared.blockingUserIds != nil {
                  ANISessionManager.shared.blockingUserIds?.insert(userId, at: 0)
                } else {
                  ANISessionManager.shared.blockingUserIds = [userId]
                }
                
                if snapshot.documents.count == ANISessionManager.shared.blockingUserIds?.count, !self.isLoadedFirstData {
                  group.leave()
                }
              }
            } else if diff.type == .removed {
              guard let blockingUserIds = ANISessionManager.shared.blockingUserIds else { return }
              
              let data = diff.document.data()
              
              for (index, blockingUserIds) in blockingUserIds.enumerated() {
                if let userId = data[KEY_USER_ID] as? String, userId == blockingUserIds {
                  ANISessionManager.shared.blockingUserIds?.remove(at: index)
                }
              }
            }
          })
          
          if snapshot.documents.isEmpty, !self.isLoadedFirstData {
            group.leave()
          }
        })
      }
      
      group.notify(queue: DispatchQueue(label: "user")) {
        DispatchQueue.main.async {
          ANINotificationManager.postLoadedCurrentUser()
          self.isLoadedFirstData = true
          
          if let fcmToken = UserDefaults.standard.string(forKey: KEY_FCM_TOKEN),
            let currentUser = ANISessionManager.shared.currentUser,
            currentUser.fcmToken != fcmToken {
            database.collection(KEY_USERS).document(currentUserUid).updateData([KEY_FCM_TOKEN: fcmToken])
          }
          
          completion?()
        }
      }
    } else {
      signOut()
      isLoadedFirstData = true
    }
  }
  
  private func signOut() {
    do {
      try Auth.auth().signOut()
      ANITwitter.logOut()
      GIDSignIn.sharedInstance().signOut()
      
      let userDefaults = UserDefaults.standard
      userDefaults.set(false, forKey: KEY_IS_TWITTER_SHARE)
      
      ANISessionManager.shared.currentUser = nil
      ANISessionManager.shared.currentUserUid = nil
      ANISessionManager.shared.isAnonymous = true
      ANISessionManager.shared.blockUserIds = nil
      ANISessionManager.shared.blockingUserIds = nil
      
      ANINotificationManager.postLogout()
    } catch let signOutError as NSError {
      DLog("signOutError \(signOutError)")
    }
  }
  
  func observeChatGroup() {
    guard let crrentUserUid = ANISessionManager.shared.currentUserUid else { return }
    
    let database = Firestore.firestore()
    
    if let chatGroupListener = self.chatGroupListener {
      chatGroupListener.remove()
    }
    
    DispatchQueue.global().async {
      self.chatGroupListener = database.collection(KEY_CHAT_GROUPS).whereField(KEY_CHAT_MEMBER_IDS + "." + crrentUserUid, isEqualTo: true).whereField(KEY_IS_HAVE_UNREAD_MESSAGE + "." + crrentUserUid, isEqualTo: true).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }

        snapshot.documentChanges.forEach({ (diff) in
          if diff.type == .added {
            if self.oldIsHaveUnreadMessage != true {
              ANISessionManager.shared.isHaveUnreadMessage = true
            }
            self.oldIsHaveUnreadMessage = ANISessionManager.shared.isHaveUnreadMessage
          } else if diff.type == .modified {
            if self.oldIsHaveUnreadMessage != true {
              ANISessionManager.shared.isHaveUnreadMessage = true
            }
            self.oldIsHaveUnreadMessage = ANISessionManager.shared.isHaveUnreadMessage
          }
        })
        
        if snapshot.documents.isEmpty {
          if self.oldIsHaveUnreadMessage != false {
            ANISessionManager.shared.isHaveUnreadMessage = false
          }
          self.oldIsHaveUnreadMessage = ANISessionManager.shared.isHaveUnreadMessage
        }
      })
    }
  }
}
