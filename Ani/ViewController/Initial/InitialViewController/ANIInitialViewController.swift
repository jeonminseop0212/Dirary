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
import GoogleSignIn
import Firebase

class ANIInitialViewController: UIViewController {
  
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
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    UIApplication.shared.statusBar?.alpha = 1.0
  }
  
  private func setup() {
    //basic
    ANIOrientation.lockOrientation(.portrait)
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    
    //google login
    GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().uiDelegate = self
    
    //initialView
    let initialView = ANIInitialView()
    initialView.myTabBarController = myTabBarController
    initialView.delegate = self
    self.view.addSubview(initialView)
    initialView.edgesToSuperview()
    self.initialView = initialView
    
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
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = true
    self.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
}

//MARK: ANIInitialViewDelegate
extension ANIInitialViewController: ANIInitialViewDelegate {
  func loginButtonTapped() {
    let loginViewController = ANILoginViewController()
    loginViewController.myTabBarController = myTabBarController
    self.navigationController?.pushViewController(loginViewController, animated: true)
  }
  
  func signUpButtonTapped() {
    let signUpViewController = ANISignUpViewController()
    self.navigationController?.pushViewController(signUpViewController, animated: true)
  }
  
  func startAnonymous() {
    ANISessionManager.shared.isHiddenInitial = true
    self.dismiss(animated: true, completion: nil)
  }
  
  func showTerms() {
    let urlString = "https://myau5.webnode.jp/%E5%88%A9%E7%94%A8%E8%A6%8F%E7%B4%84/"
    guard let url = URL(string: urlString) else { return }
    
    let safariVC = SFSafariViewController(url: url)
    present(safariVC, animated: true, completion: nil)
  }
  
  func showPrivacyPolicy() {
    let urlString = "https://myau5.webnode.jp/プライバシーポリシー/"
    guard let privacyPolicyUrl = urlString.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
          let url = URL(string: privacyPolicyUrl) else { return }
    
    let safariVC = SFSafariViewController(url: url)
    present(safariVC, animated: true, completion: nil)
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
  
  func startAnimaing() {
    self.activityIndicatorView?.startAnimating()
  }
  
  func stopAnimating() {
    self.activityIndicatorView?.stopAnimating()
  }
  
  func successTwitterLogin() {
    ANINotificationManager.postLogin()
    ANISessionManager.shared.isHiddenInitial = true
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
  
  func googleLoginButtonTapped() {
    self.activityIndicatorView?.startAnimating()
    GIDSignIn.sharedInstance().signIn()
  }
}

//MARK: UIGestureRecognizerDelegate
extension ANIInitialViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

//MARK: GIDSignInDelegate
extension ANIInitialViewController: GIDSignInDelegate, GIDSignInUIDelegate {
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    if let error = error {
      DLog("google sign in error \(error.localizedDescription)")
      self.activityIndicatorView?.stopAnimating()
      signOut()
      self.reject(notiText: "Googleログインに失敗しました。")
      return
    }
    
    guard let authentication = user.authentication else { return }
    
    let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                   accessToken: authentication.accessToken)
    
    Auth.auth().signInAndRetrieveData(with: credential) { (authResult, error) in
      if let error = error {
        DLog("auth sign in error \(error.localizedDescription)")
        self.activityIndicatorView?.stopAnimating()
        self.signOut()
        self.reject(notiText: "Googleログインに失敗しました。")
        return
      }
      
      let database = Firestore.firestore()
      if let crrentUserId = Auth.auth().currentUser?.uid {
        //再ログインかアカウント作成か判断
        database.collection(KEY_USERS).document(crrentUserId).getDocument(completion: { (snapshot, error) in
          if let error = error {
            DLog("get document error \(error.localizedDescription)")
            self.signOut()
            self.activityIndicatorView?.stopAnimating()
            self.reject(notiText: "データ取得に失敗しました。")
            return
          }
          
          if let snapshot = snapshot, snapshot.data() != nil {
            self.myTabBarController?.isLoadedUser = false
            self.myTabBarController?.isLoadedFirstData = false
            self.myTabBarController?.loadUser() {
              ANINotificationManager.postLogin()
              self.activityIndicatorView?.stopAnimating()
              ANISessionManager.shared.isHiddenInitial = true
              self.navigationController?.dismiss(animated: true, completion: nil)
              self.myTabBarController?.observeChatGroup()
            }
          } else {
            self.getUniqueUserName(userName: user.profile.name, count: 0, completion: { (uniqueUserName) in
              if uniqueUserName == "" {
                self.signOut()
                self.activityIndicatorView?.stopAnimating()
                self.reject(notiText: "MYAUアカウント登録に失敗しました。")

                return
              }

              if let url = user.profile.imageURL(withDimension: 200) {
                DispatchQueue.global().async {
                  if let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data)?.resize(size: CGSize(width: 500.0, height: 500.0)) {
                    self.uploadUserData(userName: uniqueUserName, profileImage: image)
                  }
                }
              } else {
                if let image = UIImage(named: "profileDefaultImage") {
                  self.uploadUserData(userName: uniqueUserName, profileImage: image)
                }
              }
            })
          }
        })
      }
    }
  }
  
  func uploadUserData(userName: String, profileImage: UIImage) {
    guard let currentUser = Auth.auth().currentUser,
      let profileImageData = profileImage.jpegData(compressionQuality: 0.5) else { return }
    
    let storageRef = Storage.storage().reference()
    storageRef.child(KEY_PROFILE_IMAGES).child("\(currentUser.uid).jpeg").putData(profileImageData, metadata: nil) { (metaData, error) in
      if error != nil {
        DLog("storageError")
        self.signOut()
        self.activityIndicatorView?.stopAnimating()
        self.reject(notiText: "データの書き込みに失敗しました。")
        return
      }
      
      storageRef.child(KEY_PROFILE_IMAGES).child("\(currentUser.uid).jpeg").downloadURL(completion: { (url, error) in
        if error != nil {
          DLog("storage download url error")
          self.signOut()
          self.activityIndicatorView?.stopAnimating()
          self.reject(notiText: "データのロードに失敗しました。")
          return
        }
        
        if let profileImageUrl = url {
          let fcmToken = UserDefaults.standard.string(forKey: KEY_FCM_TOKEN)
          let user = FirebaseUser(uid: currentUser.uid, userName: userName, kind: "個人", introduce: "", profileImageUrl: profileImageUrl.absoluteString, familyImageUrls: nil, checkNotiDate: nil, isHaveUnreadNoti: false, unreadNotiCount: 0, unreadMessageCount: 0, fcmToken: fcmToken, twitterAccount: nil, instagramAccount: nil, isTwitterLink: false)
          
          self.uploadUserIntoDatabase(uid: currentUser.uid, user: user)
        }
      })
    }
  }
  
  func uploadUserIntoDatabase(uid: String, user: FirebaseUser) {
    let database = Firestore.firestore()
    
    do {
      let userData = try FirestoreEncoder().encode(user)
      
      database.collection(KEY_USERS).document(uid).setData(userData) { error in
        if let error = error {
          DLog("Error set document: \(error)")
          self.signOut()
          self.activityIndicatorView?.stopAnimating()
          self.reject(notiText: "アカウント登録に失敗しました。")
          return
        }
        
        self.pushDataAlgolia(data: userData as [String: AnyObject])
        
        self.myTabBarController?.isLoadedUser = false
        self.myTabBarController?.isLoadedFirstData = false
        self.myTabBarController?.loadUser() {
          ANINotificationManager.postLogin()
          self.activityIndicatorView?.stopAnimating()
          ANISessionManager.shared.isHiddenInitial = true
          self.navigationController?.dismiss(animated: true, completion: nil)
          self.myTabBarController?.observeChatGroup()
        }
      }
    } catch let error {
      DLog(error)
      self.signOut()
      self.activityIndicatorView?.stopAnimating()
      self.reject(notiText: "アカウント登録に失敗しました。")
    }
  }
  
  func getUniqueUserName(userName: String, count: Int, completion: @escaping ((String)->())) {
    let database = Firestore.firestore()
    if count > 30 {
      DLog("Error get unique user name")
      completion("")
      return
    }
    
    DispatchQueue.global().async {
      database.collection(KEY_USERS).whereField(KEY_USER_NAME, isEqualTo: userName).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          completion("")
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        if snapshot.documents.isEmpty {
          completion(userName)
        } else {
          let randomInt = String(Int.random(in: 1 ... 10))
          let newUserName = userName + randomInt
          self.getUniqueUserName(userName: newUserName, count: count + 1, completion: completion)
        }
      })
    }
  }
  
  func pushDataAlgolia(data: [String: AnyObject]) {
    let index = ANISessionManager.shared.client.index(withName: KEY_USERS_INDEX)
    
    var newData = data
    if let objectId = data[KEY_UID] {
      newData.updateValue(objectId, forKey: KEY_OBJECT_ID)
    }
    
    DispatchQueue.global().async {
      index.addObject(newData, completionHandler: { (content, error) -> Void in
        if let error = error {
          DLog("algolia error \(error)")
        }
        
        guard let content = content else { return }
        DLog("Object IDs: \(content)")
      })
    }
  }
  
  func signOut() {
    if Auth.auth().currentUser != nil {
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
    
    GIDSignIn.sharedInstance().signOut()
  }
}
