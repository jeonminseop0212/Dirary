//
//  CommunityViewController.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase

enum PushNotificationKind: String {
  case noti;
  case message;
}

class ANINotiViewController: UIViewController {
  
  private weak var menuBar: ANiNotiMenuBar?
  private weak var containerCollectionView: UICollectionView?
  
  private weak var needLoginView: ANINeedLoginView?
  
  var pushNotificationKind: PushNotificationKind? {
    didSet {
      guard let pushNotificationKind = self.pushNotificationKind else { return }
      
      if pushNotificationKind == .noti {
        self.tapNotiNotification()
      } else if pushNotificationKind == .message {
        self.tapMessageNotification()
      }
    }
  }
  
  var sendPushNotificationUserId: String? {
    didSet {
      guard let sendPushNotificationUserId = self.sendPushNotificationUserId else { return }
      
      pushChatTapPushNotification(sendUserId: sendPushNotificationUserId)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup() {
      guard let pushNotificationKind = self.pushNotificationKind else { return }
      
      if pushNotificationKind == .noti {
        self.tapNotiNotification()
      } else if pushNotificationKind == .message {
        self.tapMessageNotification()
      }
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
    
    showNeedLoginView()
    setupNotifications()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
    
    ANINotiView.endRefresh()
  }
  
  private func setup(completion:(()->())? = nil) {
    //basic
    ANIOrientation.lockOrientation(.portrait)
    navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    
    //container
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumLineSpacing = 0
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    let containerCollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: flowLayout)
    containerCollectionView.contentInsetAdjustmentBehavior = .never
    containerCollectionView.dataSource = self
    containerCollectionView.delegate = self
    containerCollectionView.showsHorizontalScrollIndicator = false
    containerCollectionView.backgroundColor = ANIColor.bg
    containerCollectionView.isPagingEnabled = true
    let notiId = NSStringFromClass(ANINotiNotiCell.self)
    containerCollectionView.register(ANINotiNotiCell.self, forCellWithReuseIdentifier: notiId)
    let messageId = NSStringFromClass(ANINotiMessageCell.self)
    containerCollectionView.register(ANINotiMessageCell.self, forCellWithReuseIdentifier: messageId)
    
    self.view.addSubview(containerCollectionView)
    containerCollectionView.edgesToSuperview()
    self.containerCollectionView = containerCollectionView
    
    //menuBar
    let menuBar = ANiNotiMenuBar()
    menuBar.notiViewController = self
    self.view.addSubview(menuBar)
    let menuBarHeight = UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT
    menuBar.topToSuperview()
    menuBar.leftToSuperview()
    menuBar.rightToSuperview()
    menuBar.height(menuBarHeight)
    self.menuBar = menuBar
    
    //needLoginView
    let needLoginView = ANINeedLoginView()
    needLoginView.isHidden = true
    needLoginView.setupMessage(text: "通知とメッセージを利用するには\nログインが必要です")
    needLoginView.delegate = self
    self.view.addSubview(needLoginView)
    needLoginView.edgesToSuperview()
    self.needLoginView = needLoginView
    
    completion?()
  }
  
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(messageCellTapped: self, selector: #selector(pushChat))
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(login: self, selector: #selector(showNeedLoginView))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  func scrollToMenuIndex(menuIndex: Int) {
    guard let containerCollectionView = self.containerCollectionView else { return }
    let indexPath = IndexPath(item: menuIndex, section: 0)
    containerCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
  }
  
  @objc private func showNeedLoginView() {
    guard let needLoginView = self.needLoginView else { return }
    
    if ANISessionManager.shared.isAnonymous == true {
      needLoginView.isHidden = false
    } else {
      needLoginView.isHidden = true
    }
  }
  
  private func tapNotiNotification() {
    guard let menuBar = self.menuBar else { return }
    
    scrollToMenuIndex(menuIndex: 0)
    menuBar.menuCollectionView?.selectItem(at: IndexPath(item: 0, section: 0), animated: true, scrollPosition: .left)
    
    ANINotificationManager.postTapNotiNotification()
  }
  
  private func tapMessageNotification() {
    guard let menuBar = self.menuBar else { return }
    
    scrollToMenuIndex(menuIndex: 1)
    menuBar.menuCollectionView?.selectItem(at: IndexPath(item: 1, section: 0), animated: true, scrollPosition: .left)
  }
  
  private func pushChatTapPushNotification(sendUserId: String) {
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(sendUserId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          return
        }

        guard let snapshot = snapshot,
              let data = snapshot.data() else { return }
        
        do {
          let sendUser = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
          
          let chatViewController = ANIChatViewController()
          chatViewController.user = sendUser
          chatViewController.isPush = true
          chatViewController.hidesBottomBarWhenPushed = true
          self.navigationController?.pushViewController(chatViewController, animated: true)
        } catch let error {
          DLog(error)
        }
      })
    }
  }
  
  @objc func pushChat(_ notification: NSNotification) {
    guard let user = notification.object as? FirebaseUser else { return }
    
    let chatViewController = ANIChatViewController()
    chatViewController.user = user
    chatViewController.isPush = true
    chatViewController.hidesBottomBarWhenPushed = true
    self.navigationController?.pushViewController(chatViewController, animated: true)
  }
  
  @objc private func pushOtherProfile(_ notification: NSNotification) {
    guard let userId = notification.object as? String else { return }
    
    if let currentUserUid = ANISessionManager.shared.currentUserUid, currentUserUid == userId {
      let profileViewController = ANIProfileViewController()
      profileViewController.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(profileViewController, animated: true)
      profileViewController.isBackButtonHide = false
    } else {
      let otherProfileViewController = ANIOtherProfileViewController()
      otherProfileViewController.hidesBottomBarWhenPushed = true
      otherProfileViewController.userId = userId
      self.navigationController?.pushViewController(otherProfileViewController, animated: true)
    }
  }
}

//MARK: UICollectionViewDataSource
extension ANINotiViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 2
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.item == 0 {
      let notiId = NSStringFromClass(ANINotiNotiCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: notiId, for: indexPath) as! ANINotiNotiCell
      
      cell.frame.origin.y = collectionView.frame.origin.y
      cell.delegate = self
      
      return cell
    } else {
      let messageId = NSStringFromClass(ANINotiMessageCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: messageId, for: indexPath) as! ANINotiMessageCell
      
      cell.frame.origin.y = collectionView.frame.origin.y
      
      return cell
    }
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANINotiViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: self.view.frame.width, height: self.view.frame.height)
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANINotiViewController: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let menuBar = self.menuBar, let horizontalBarleftConstraint = menuBar.horizontalBarleftConstraint else { return }
    horizontalBarleftConstraint.constant = scrollView.contentOffset.x / 2
  }
  
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let menuBar = self.menuBar else { return }
    let indexPath = IndexPath(item: Int(targetContentOffset.pointee.x / view.frame.width), section: 0)
    menuBar.menuCollectionView?.selectItem(at: indexPath, animated: true, scrollPosition: .left)
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if let cell = cell as? ANINotiNotiCell {
      cell.isCellSelected = true
    } else if let cell = cell as? ANINotiMessageCell {
      cell.isCellSelected = true
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if let cell = cell as? ANINotiNotiCell {
      cell.isCellSelected = false
    } else if let cell = cell as? ANINotiMessageCell {
      cell.isCellSelected = false
    }
  }
}

//MARK: ANINeedLoginViewDelegate
extension ANINotiViewController: ANINeedLoginViewDelegate {
  func loginButtonTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
  }
}

//MARK: ANINotiNotiCellDelegate
extension ANINotiViewController: ANINotiNotiCellDelegate {
  func cellTapped(noti: FirebaseNotification) {
    let notiDetailViewController = ANINotiDetailViewController()
    notiDetailViewController.noti = noti
    notiDetailViewController.hidesBottomBarWhenPushed = true
    
    if noti.notiKind == KEY_NOTI_KIND_FOLLOW {
      notiDetailViewController.notiKind = .follow
    } else if noti.notiKind == KEY_NOTI_KIND_LOVE {
      notiDetailViewController.notiKind = .love
    } else if noti.notiKind == KEY_NOTI_KIND_COMMENT {
      notiDetailViewController.notiKind = .comment
    } else if noti.notiKind == KEY_NOTI_KIND_SUPPORT {
      notiDetailViewController.notiKind = .support
    }

    if noti.contributionKind == KEY_CONTRIBUTION_KIND_RECRUIT {
      notiDetailViewController.navigationTitle = "募集"
      notiDetailViewController.contributionKind = .recruit
    } else if noti.contributionKind == KEY_CONTRIBUTION_KIND_STROY {
      notiDetailViewController.navigationTitle = "ストーリー"
      notiDetailViewController.contributionKind = .story
    } else if noti.contributionKind == KEY_CONTRIBUTION_KIND_QNA {
      notiDetailViewController.navigationTitle = "Q&A"
      notiDetailViewController.contributionKind = .qna
    } else if noti.contributionKind == KEY_CONTRIBUTION_KIND_STORY_COMMENT {
      notiDetailViewController.navigationTitle = "ストーリー"
      notiDetailViewController.contributionKind = .storyComment
    } else if noti.contributionKind == KEY_CONTRIBUTION_KIND_QNA_COMMENT {
      notiDetailViewController.navigationTitle = "Q&A"
      notiDetailViewController.contributionKind = .qnaComment
    }
    
    self.navigationController?.pushViewController(notiDetailViewController, animated: true)
  }
}

//MARK: UIGestureRecognizerDelegate
extension ANINotiViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
