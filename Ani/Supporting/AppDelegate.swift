//
//  AppDelegate.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/02.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import Siren
import CodableFirebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?
  var orientationLock = UIInterfaceOrientationMask.all
  private weak var tabBarController: ANITabBarController?
  private let NOTI_VIEW_CONTROLLER_INDEX: Int = 2
  
  enum SirenAlertType: String {
    case force;
    case option;
    case skip;
    case none;
  }
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    
    self.orientationLock = .portrait
    
    ANIFirebaseRemoteConfigManager.shared.fetch()
    
    //notification
    application.registerForRemoteNotifications()
    Messaging.messaging().delegate = self
    UNUserNotificationCenter.current().delegate = self
    
    let tabBarController = ANITabBarController()
    self.tabBarController = tabBarController
    
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = tabBarController
    window?.makeKeyAndVisible()
    
    let siren = Siren.shared
    siren.forceLanguageLocalization = .japanese
    siren.alertMessaging = SirenAlertMessaging(updateTitle: NSAttributedString(string: "アップデートのお知らせ"),
                                               updateMessage: NSAttributedString(string: "MYAUの新規バージョンがご利用になれます。アップデートしてください。"),
                                               updateButtonMessage: NSAttributedString(string: "アップデート"),
                                               nextTimeButtonMessage: NSAttributedString(string: "次回"),
                                               skipVersionButtonMessage: NSAttributedString(string: "このバージョンをスキップ"))
    siren.countryCode = "jp"
    siren.delegate = self
    
    ANIFirebaseRemoteConfigManager.shared.getShowReivewConditions { (conditions, error) in
      if error == nil, let conditions = conditions {
        ANISessionManager.shared.showReviewConditions = conditions
      }
    }

    ANIFirebaseRemoteConfigManager.shared.getSirenAlertType { (type, error) in
      if error == nil, let type = type {
        switch type {
        case SirenAlertType.force.rawValue:
          siren.alertType = .force
        case SirenAlertType.option.rawValue:
          siren.alertType = .option
        case SirenAlertType.skip.rawValue:
          siren.alertType = .skip
        case SirenAlertType.none.rawValue:
          siren.alertType = .none
        default:
          siren.alertType = .skip
        }

        siren.checkVersion(checkType: .immediately)
      } else {
        siren.alertType = .force

        siren.checkVersion(checkType: .immediately)
      }
    }
    
    //navigation bar
    let navigationBarAppearane = UINavigationBar.appearance()
    navigationBarAppearane.barTintColor = .white
    navigationBarAppearane.tintColor = ANIColor.dark
    navigationBarAppearane.setBackgroundImage(UIImage(), for: .default)
    navigationBarAppearane.shadowImage = UIImage()
    
    return true
  }
  
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return self.orientationLock
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    if !ANISessionManager.shared.isCheckedVersion {
      Siren.shared.checkVersion(checkType: .immediately)
    }
    
    playTopViewControllerVideo()
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
  }
  
  private func playTopViewControllerVideo() {
    if let topController = UIApplication.topViewController() {
      if let communityViewController = topController as? ANICommunityViewController {
        communityViewController.playVideo()
      }
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
                self.tabBarController?.present(eventPopupViewController, animated: false, completion: nil)
                
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

//MARK: UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
  }

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
  }
}

// MARK: MessagingDelegate
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
  }
  
  func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
  }
}

//MARK: SirenDelegate
extension AppDelegate: SirenDelegate {
  func sirenLatestVersionInstalled() {
    ANISessionManager.shared.isCheckedVersion = true
    showEventIfNeeded()
  }

  func sirenVersionIsSkip() {
    ANISessionManager.shared.isCheckedVersion = true
    showEventIfNeeded()
  }

  func sirenUserDidCancel() {
    ANISessionManager.shared.isCheckedVersion = true
    showEventIfNeeded()
  }

  func sirenUserDidSkipVersion() {
    ANISessionManager.shared.isCheckedVersion = true
    showEventIfNeeded()
  }

  func sirenDidFailVersionCheck(error: Error) {
    if IS_DEBUG {
      ANISessionManager.shared.isCheckedVersion = true
      showEventIfNeeded()
    } else {
      ANINotificationManager.postFailLoadVersion()
    }
  }
}
