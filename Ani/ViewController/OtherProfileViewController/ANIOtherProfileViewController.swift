//
//  ANIOtherProfileViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase
import FirebaseStorage
import SafariServices

class ANIOtherProfileViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var navigationTitleLabel: UILabel?
  private weak var backButton: UIButton?
  private weak var optionButton: UIButton?
  private weak var messageButton: UIButton?
  private let MESSAGE_RIGTHT_GRADATION_VIEW_WIDTH: CGFloat = 35.0
  private weak var messageRightGradationView: UIView?
  
  private weak var profileBasicView: ANIOtherProfileBasicView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  private var rejectTapView: UIView?
  
  private var user: FirebaseUser?
  var userId: String?
  
  private var contentType: ContentType?
  private var contributionId: String?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
    setupNotifications()
    
    playVideo()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    stopVideo()
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
    
    //myNavigationBase
    let myNavigationBase = UIView()
    myNavigationBar.addSubview(myNavigationBase)
    myNavigationBase.edgesToSuperview(excluding: .top)
    myNavigationBase.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBase = myNavigationBase
    
    //backButton
    let backButton = UIButton()
    let backButtonImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate)
    backButton.setImage(backButtonImage, for: .normal)
    backButton.tintColor = ANIColor.dark
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBase.addSubview(backButton)
    backButton.width(44.0)
    backButton.height(44.0)
    backButton.leftToSuperview()
    backButton.centerYToSuperview()
    self.backButton = backButton
    
    //optionButton
    let optionButton = UIButton()
    let optionButtonImage = UIImage(named: "optionButton")?.withRenderingMode(.alwaysTemplate)
    optionButton.setImage(optionButtonImage, for: .normal)
    optionButton.tintColor = ANIColor.dark
    optionButton.addTarget(self, action: #selector(option), for: .touchUpInside)
    myNavigationBase.addSubview(optionButton)
    optionButton.width(40.0)
    optionButton.height(44.0)
    optionButton.rightToSuperview(offset: -5.0)
    optionButton.centerYToSuperview()
    self.optionButton = optionButton
    
    //messageButton
    let messageButton = UIButton()
    let messageButtonImage = UIImage(named: "messageButton")?.withRenderingMode(.alwaysTemplate)
    messageButton.setImage(messageButtonImage, for: .normal)
    messageButton.tintColor = ANIColor.dark
    messageButton.addTarget(self, action: #selector(message), for: .touchUpInside)
    myNavigationBase.addSubview(messageButton)
    messageButton.width(30.0)
    messageButton.height(44.0)
    messageButton.rightToLeft(of: optionButton)
    messageButton.centerYToSuperview()
    self.messageButton = messageButton
    
    //navigationTitleLabel
    let navigationTitleLabel = UILabel()
    navigationTitleLabel.text = "プロフィール"
    navigationTitleLabel.textColor = ANIColor.dark
    navigationTitleLabel.textAlignment = .center
    navigationTitleLabel.lineBreakMode = .byCharWrapping
    navigationTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBase.addSubview(navigationTitleLabel)
    navigationTitleLabel.centerYToSuperview()
    navigationTitleLabel.leftToRight(of: backButton, offset: 35.0)
    navigationTitleLabel.rightToLeft(of: messageButton, offset: -5.0)
    self.navigationTitleLabel = navigationTitleLabel
    
    //messageRightGradationView
    let messageRightGradationView = UIView()
    let gradiationLayer = CAGradientLayer()
    gradiationLayer.startPoint = CGPoint(x: 0.8, y: 0.5)
    gradiationLayer.endPoint = CGPoint(x: 0, y: 0.5)
    gradiationLayer.frame = CGRect(x: 0, y: 0, width: MESSAGE_RIGTHT_GRADATION_VIEW_WIDTH, height: UIViewController.NAVIGATION_BAR_HEIGHT)
    gradiationLayer.colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
    messageRightGradationView.layer.addSublayer(gradiationLayer)
    myNavigationBase.addSubview(messageRightGradationView)
    messageRightGradationView.rightToLeft(of: messageButton, offset: 0.0)
    messageRightGradationView.width(MESSAGE_RIGTHT_GRADATION_VIEW_WIDTH)
    messageRightGradationView.topToSuperview()
    messageRightGradationView.bottomToSuperview()
    self.messageRightGradationView = messageRightGradationView
    
    //profileBasicView
    let profileBasicView = ANIOtherProfileBasicView()
    profileBasicView.userId = userId
    profileBasicView.delegate = self
    self.view.addSubview(profileBasicView)
    profileBasicView.topToBottom(of: myNavigationBar)
    profileBasicView.edgesToSuperview(excluding: .top)
    self.profileBasicView = profileBasicView
    
    //rejectView
    let rejectView = ANIRejectView()
    rejectView.setRejectText("ログインが必要です。")
    self.view.addSubview(rejectView)
    rejectViewBottomConstraint = rejectView.bottomToTop(of: self.view)
    rejectViewBottomConstraintOriginalConstant = rejectViewBottomConstraint?.constant
    rejectView.leftToSuperview()
    rejectView.rightToSuperview()
    self.rejectView = rejectView
    
    //rejectTapView
    let rejectTapView = UIView()
    rejectTapView.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(rejectViewTapped))
    rejectTapView.addGestureRecognizer(tapGesture)
    rejectTapView.isHidden = true
    rejectTapView.backgroundColor = .clear
    self.view.addSubview(rejectTapView)
    rejectTapView.size(to: rejectView)
    rejectTapView.topToSuperview()
    self.rejectTapView = rejectTapView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = true
    self.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  private func unfollow(userId: String, currentUserUid: String) {
    let database = Firestore.firestore()
    
    database.collection(KEY_USERS).document(currentUserUid).collection(KEY_FOLLOWER_IDS).document(userId).delete()
    database.collection(KEY_USERS).document(currentUserUid).collection(KEY_FOLLOWING_USER_IDS).document(userId).delete()
    
    database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWER_IDS).document(currentUserUid).delete()
    database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWING_USER_IDS).document(currentUserUid).delete()
  }
  
  func playVideo() {
    guard let profileBasicView = self.profileBasicView else { return }
    
    profileBasicView.playVideo()
  }
  
  private func stopVideo() {
    guard let profileBasicView = self.profileBasicView else { return }
    
    profileBasicView.stopVideo()
  }
  
  //MARK: notification
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(imageCellTapped: self, selector: #selector(presentImageBrowser(_:)))
    ANINotificationManager.receive(tapHashtag: self, selector: #selector(pushHashtagList))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func presentImageBrowser(_ notification: NSNotification) {
    guard let item = notification.object as? (Int, [String]) else { return }
    
    let selectedIndex = item.0
    let imageUrls = item.1
    let imageBrowserViewController = ANIImageBrowserViewController()
    imageBrowserViewController.selectedIndex = selectedIndex
    imageBrowserViewController.imageUrls = imageUrls
    imageBrowserViewController.modalPresentationStyle = .overCurrentContext
    imageBrowserViewController.delegate = self
    //overCurrentContextだとtabBarが消えないのでtabBarからpresentする
    self.tabBarController?.present(imageBrowserViewController, animated: false, completion: nil)
  }
  
  @objc private func pushHashtagList(_ notification: NSNotification) {
    if let userInfo = notification.userInfo,
      let contributionKind = userInfo[KEY_CONTRIBUTION_KIND] as? String,
      let hashtag = userInfo[KEY_HASHTAG] as? String {
      let hashtagListViewController = ANIHashtagListViewController()
      hashtagListViewController.hashtag = hashtag
      if contributionKind == KEY_CONTRIBUTION_KIND_STROY {
        hashtagListViewController.hashtagList = .story
      } else if contributionKind == KEY_CONTRIBUTION_KIND_QNA {
        hashtagListViewController.hashtagList = .question
      }
      hashtagListViewController.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(hashtagListViewController, animated: true)
    }
  }
  
  private func rejectAnimation() {
    guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
          !isRejectAnimating,
          let rejectTapView = self.rejectTapView else { return }
    
    rejectViewBottomConstraint.constant = UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    rejectTapView.isHidden = false
    
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
        rejectTapView.isHidden = true
      })
    }
  }
  
  //MARK: action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
  
  @objc private func rejectViewTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
  }
  
  @objc private func option() {
    self.contentType = .user
    self.contributionId = userId
    
    let popupOptionViewController = ANIPopupOptionViewController()
    popupOptionViewController.modalPresentationStyle = .overCurrentContext
    popupOptionViewController.isMe = false
    popupOptionViewController.options = ["ブロック"]
    popupOptionViewController.delegate = self
    self.tabBarController?.present(popupOptionViewController, animated: false, completion: nil)
  }
  
  @objc private func message() {
    if !ANISessionManager.shared.isAnonymous {
      let chatViewController = ANIChatViewController()
      let navigationContoller = UINavigationController(rootViewController: chatViewController)
      chatViewController.user = user
      chatViewController.isPush = false
      self.present(navigationContoller, animated: true, completion: nil)
    } else {
      reject()
    }
  }
}

//MARK: ANIProfileBasicViewDelegate
extension ANIOtherProfileViewController: ANIOtherProfileBasicViewDelegate {
  func loadedUser(user: FirebaseUser) {
    guard let navigationTitleLabel = self.navigationTitleLabel,
          let userName = user.userName else { return }
    
    self.user = user
    navigationTitleLabel.text = userName
  }
  
  func followingTapped() {
    guard let userId = self.userId else { return }
    
    let followUserViewController = ANIFollowUserViewContoller()
    followUserViewController.followUserViewMode = .following
    followUserViewController.userId = userId
    followUserViewController.hidesBottomBarWhenPushed = true
    self.navigationController?.pushViewController(followUserViewController, animated: true)
  }
  
  func followerTapped() {
    guard let userId = self.userId else { return }
    
    let followUserViewController = ANIFollowUserViewContoller()
    followUserViewController.followUserViewMode = .follower
    followUserViewController.userId = userId
    followUserViewController.hidesBottomBarWhenPushed = true
    self.navigationController?.pushViewController(followUserViewController, animated: true)
  }
  
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser) {
    let supportViewController = ANISupportViewController()
    supportViewController.modalPresentationStyle = .overCurrentContext
    supportViewController.recruit = supportRecruit
    supportViewController.user = user
    self.tabBarController?.present(supportViewController, animated: false, completion: nil)
  }
  
  func recruitViewCellDidSelect(selectedRecruit: FirebaseRecruit, user: FirebaseUser) {
    let recruitDetailViewController = ANIRecruitDetailViewController()
    recruitDetailViewController.hidesBottomBarWhenPushed = true
    recruitDetailViewController.recruit = selectedRecruit
    recruitDetailViewController.user = user
    self.navigationController?.pushViewController(recruitDetailViewController, animated: true)
  }
  
  func storyViewCellDidSelect(selectedStory: FirebaseStory, user: FirebaseUser) {
    let commentViewController = ANICommentViewController()
    commentViewController.hidesBottomBarWhenPushed = true
    commentViewController.commentMode = CommentMode.story
    commentViewController.story = selectedStory
    commentViewController.user = user
    self.navigationController?.pushViewController(commentViewController, animated: true)
  }
  
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser) {
    let recruitDetailViewController = ANIRecruitDetailViewController()
    recruitDetailViewController.hidesBottomBarWhenPushed = true
    recruitDetailViewController.recruit = recruit
    recruitDetailViewController.user = user
    self.navigationController?.pushViewController(recruitDetailViewController, animated: true)
  }
  
  func qnaViewCellDidSelect(selectedQna: FirebaseQna, user: FirebaseUser) {
    let commentViewController = ANICommentViewController()
    commentViewController.hidesBottomBarWhenPushed = true
    commentViewController.commentMode = CommentMode.qna
    commentViewController.qna = selectedQna
    commentViewController.user = user
    self.navigationController?.pushViewController(commentViewController, animated: true)
  }
  
  func reject() {
    guard let rejectView = self.rejectView,
          let rejectTapView = self.rejectTapView else { return }
    
    rejectTapView.isUserInteractionEnabled = true
    rejectView.setRejectText("ログインが必要です。")
    self.rejectAnimation()
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.contentType = contentType
    self.contributionId = id
    
    let popupOptionViewController = ANIPopupOptionViewController()
    popupOptionViewController.modalPresentationStyle = .overCurrentContext
    popupOptionViewController.isMe = isMe
    if !isMe {
      popupOptionViewController.options = ["非表示"]
    }
    popupOptionViewController.delegate = self
    self.tabBarController?.present(popupOptionViewController, animated: false, completion: nil)
  }
  
  func presentImageBrowser(index: Int, imageUrls: [String]) {
    let imageBrowserViewController = ANIImageBrowserViewController()
    imageBrowserViewController.selectedIndex = index
    imageBrowserViewController.imageUrls = imageUrls
    imageBrowserViewController.modalPresentationStyle = .overCurrentContext
    imageBrowserViewController.delegate = self
    //overCurrentContextだとtabBarが消えないのでtabBarからpresentする
    self.tabBarController?.present(imageBrowserViewController, animated: false, completion: nil)
  }
  
  func twitterOpenReject() {
    guard let rejectView = self.rejectView,
          let rejectTapView = self.rejectTapView else { return }
    
    rejectTapView.isUserInteractionEnabled = false
    rejectView.setRejectText("Twitterを開けません。")
    self.rejectAnimation()
  }
  
  func instagramOpenReject() {
    guard let rejectView = self.rejectView,
          let rejectTapView = self.rejectTapView else { return }
    
    rejectTapView.isUserInteractionEnabled = false
    rejectView.setRejectText("Instagramを開けません。")
    self.rejectAnimation()
  }
  
  func openUrl(url: URL) {
    let urlString = url.absoluteString
    let webUrlString = ANIFunction.shared.webURLScheme(urlString: urlString)
    
    if let webUrl = URL(string: webUrlString) {
      let safariViewController = SFSafariViewController(url: webUrl)
      self.present(safariViewController, animated: true, completion: nil)
    }
  }
}

//MARK: ANIImageBrowserViewControllerDelegate
extension ANIOtherProfileViewController: ANIImageBrowserViewControllerDelegate {
  func imageBrowserDidDissmiss() {
    UIApplication.shared.statusBarStyle = .default
  }
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANIOtherProfileViewController: ANIPopupOptionViewControllerDelegate {
  func deleteContribution() {
  }
  
  func reportContribution() {
    guard let contentType = self.contentType else { return }
    
    var message = ""
    if contentType == .user {
      message = "ユーザーを通報しますか？"
    } else {
      message = "投稿を通報しますか？"
    }
    
    let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    
    let reportAction = UIAlertAction(title: "通報", style: .default) { (action) in
      if !ANISessionManager.shared.isAnonymous {
        self.reportData()
      } else {
        self.reject()
      }
    }
    let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
    
    alertController.addAction(reportAction)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func optionTapped(index: Int) {
    guard let contentType = self.contentType,
          let contributionId = self.contributionId else { return }
    
    if contentType == .user {
      if let currentUserId = ANISessionManager.shared.currentUserUid {
        if index == 0 {
          guard let user = self.user,
                let userId = self.userId,
                let userName = user.userName else { return }
          
          let alertController = UIAlertController(title: "\(userName)さんをブロックしますか？", message: "ブロックされた人はあなたのプロフィールや投稿を見られなくなります。ブロックしたことは相手に通知されません。", preferredStyle: .alert)
          
          let blockAction = UIAlertAction(title: "ブロック", style: .default) { (action) in
            let database = Firestore.firestore()
            let today = ANIFunction.shared.getToday()
            
            database.collection(KEY_USERS).document(currentUserId).collection(KEY_BLOCK_USER_IDS).document(userId).setData([KEY_USER_ID: userId, KEY_DATE: today])
            database.collection(KEY_USERS).document(userId).collection(KEY_BLOCKING_USER_IDS).document(currentUserId).setData([KEY_USER_ID: currentUserId, KEY_DATE: today])
            
            self.unfollow(userId: userId, currentUserUid: currentUserId)
            
            self.navigationController?.popViewController(animated: true)
          }
          let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
          
          alertController.addAction(blockAction)
          alertController.addAction(cancelAction)
          
          self.present(alertController, animated: true, completion: nil)
        }
      } else {
        self.reject()
      }
    } else {
      if let currentUserId = ANISessionManager.shared.currentUserUid {
        if index == 0 {
          var alertTitle = ""
          var alertMessage = ""
          var collection = ""
          if contentType == .story {
            alertTitle = "このストーリーを非表示にしますか？"
            alertMessage = "非表示にしたストーリーはアプリの中で見えなくなります。後から非表示を解除することは出来ません。"
            collection = KEY_STORIES
          } else if contentType == .qna {
            alertTitle = "このs質問を非表示にしますか？"
            alertMessage = "非表示にしたs質問はアプリの中で見えなくなります。後から非表示を解除することは出来ません。"
            collection = KEY_QNAS
          }
          
          let alertController = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
          
          let hideAction = UIAlertAction(title: "非表示", style: .default) { (action) in
            let database = Firestore.firestore()
            
            self.activityIndicatorView?.startAnimating()
            
            DispatchQueue.global().async {
              database.collection(collection).document(contributionId).getDocument(completion: { (snapshot, error) in
                if let error = error {
                  DLog("Error get document: \(error)")
                  return
                }
                
                guard let snapshot = snapshot, let data = snapshot.data() else { return }
                
                if contentType == .story {
                  do {
                    let story = try FirestoreDecoder().decode(FirebaseStory.self, from: data)
                    
                    if let hideUserIds = story.hideUserIds {
                      var hideUserIdsTemp = hideUserIds
                      hideUserIdsTemp.append(currentUserId)
                      
                      database.collection(collection).document(contributionId).updateData([KEY_HIDE_USER_IDS: hideUserIdsTemp])
                      
                      self.updateDataAlgolia(objectId: contributionId, data: [KEY_HIDE_USER_IDS: hideUserIdsTemp as AnyObject], indexName: KEY_STORIES_INDEX)
                    } else {
                      let hideUserIds = [currentUserId]
                      
                      database.collection(collection).document(contributionId).updateData([KEY_HIDE_USER_IDS: hideUserIds])
                      
                      self.updateDataAlgolia(objectId: contributionId, data: [KEY_HIDE_USER_IDS: hideUserIds as AnyObject], indexName: KEY_STORIES_INDEX)
                    }
                    
                    DispatchQueue.main.async {
                      self.activityIndicatorView?.stopAnimating()
                      
                      ANINotificationManager.postDeleteStory(id: contributionId)
                    }
                  } catch let error {
                    DLog(error)
                  }
                } else if contentType == .qna {
                  do {
                    let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: data)
                    
                    if let hideUserIds = qna.hideUserIds {
                      var hideUserIdsTemp = hideUserIds
                      hideUserIdsTemp.append(currentUserId)
                      
                      database.collection(collection).document(contributionId).updateData([KEY_HIDE_USER_IDS: hideUserIdsTemp])
                      
                      self.updateDataAlgolia(objectId: contributionId, data: [KEY_HIDE_USER_IDS: hideUserIdsTemp as AnyObject], indexName: KEY_QNAS_INDEX)
                    } else {
                      let hideUserIds = [currentUserId]
                      
                      database.collection(collection).document(contributionId).updateData([KEY_HIDE_USER_IDS: hideUserIds])
                      
                      self.updateDataAlgolia(objectId: contributionId, data: [KEY_HIDE_USER_IDS: hideUserIds as AnyObject], indexName: KEY_QNAS_INDEX)
                    }
                    
                    DispatchQueue.main.async {
                      self.activityIndicatorView?.stopAnimating()

                      ANINotificationManager.postDeleteQna(id: contributionId)
                    }
                  } catch let error {
                    DLog(error)
                  }
                }
              })
            }
          }
          let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
          
          alertController.addAction(hideAction)
          alertController.addAction(cancelAction)
          
          self.present(alertController, animated: true, completion: nil)
        }
      } else {
        if index == 0 {
          self.reject()
        }
      }
    }
  }
  
  private func updateDataAlgolia(objectId: String, data: [String: AnyObject], indexName: String) {
    let index = ANISessionManager.shared.client.index(withName: indexName)
    
    DispatchQueue.global().async {
      index.partialUpdateObject(data, withID: objectId, completionHandler: { (content, error) -> Void in
        if error == nil {
          DLog("Object IDs: \(content!)")
        }
      })
    }
  }
}

//MAKR: data
extension ANIOtherProfileViewController {
  private func reportData() {
    guard let contentType = self.contentType,
          let contributionId = self.contributionId else { return }
    
    let database = Firestore.firestore()
    
    var contentTypeString = ""
    
    if contentType == .recruit {
      contentTypeString = "recurit"
    } else if contentType == .story {
      contentTypeString = "story"
    } else if contentType == .qna {
      contentTypeString = "qna"
    } else if contentType == .user {
      contentTypeString = "user"
    }
    
    let date = ANIFunction.shared.getToday()
    let values = ["contentType": contentTypeString, "date": date]
    database.collection(KEY_REPORTS).document(contributionId).collection(KEY_REPORT).addDocument(data: values)
  }
}
