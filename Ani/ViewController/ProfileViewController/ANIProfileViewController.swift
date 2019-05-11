//
//  ANIProfileViewController.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase
import FirebaseStorage
import InstantSearchClient
import SafariServices

class ANIProfileViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var navigationTitleLabel: UILabel?
  private weak var backButton: UIButton?
  private weak var optionButton: UIButton?
  private let OPTION_RIGTHT_GRADATION_VIEW_WIDTH: CGFloat = 35.0
  private weak var optionRightGradationView: UIView?
  
  private weak var needLoginView: ANINeedLoginView?
  
  var isBackButtonHide: Bool = true
  
  private weak var profileBasicView: ANIProfileBasicView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  
  private var currentUser: FirebaseUser? { return ANISessionManager.shared.currentUser }
  
  private var contentType: ContentType?
  private var contributionId: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
    setupNotifications()
    showNeedLoginView()
    reloadNavigationTitle()
    
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
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    ANIOrientation.lockOrientation(.portrait)
    
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
    if isBackButtonHide {
      backButton.alpha = 0.0
    } else {
      backButton.alpha = 1.0
    }
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
    
    //navigationTitleLabel
    let navigationTitleLabel = UILabel()
    if let currentUser = self.currentUser {
      navigationTitleLabel.text = currentUser.userName
    }
    navigationTitleLabel.textAlignment = .center
    navigationTitleLabel.textColor = ANIColor.dark
    navigationTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBase.addSubview(navigationTitleLabel)
    navigationTitleLabel.centerYToSuperview()
    navigationTitleLabel.leftToRight(of: backButton)
    navigationTitleLabel.rightToLeft(of: optionButton)
    self.navigationTitleLabel = navigationTitleLabel
    
    //optionRightGradationView
    let optionRightGradationView = UIView()
    let gradiationLayer = CAGradientLayer()
    gradiationLayer.startPoint = CGPoint(x: 0.8, y: 0.5)
    gradiationLayer.endPoint = CGPoint(x: 0, y: 0.5)
    gradiationLayer.frame = CGRect(x: 0, y: 0, width: OPTION_RIGTHT_GRADATION_VIEW_WIDTH, height: UIViewController.NAVIGATION_BAR_HEIGHT)
    gradiationLayer.colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor]
    optionRightGradationView.layer.addSublayer(gradiationLayer)
    myNavigationBase.addSubview(optionRightGradationView)
    optionRightGradationView.rightToLeft(of: optionButton, offset: 0.0)
    optionRightGradationView.width(OPTION_RIGTHT_GRADATION_VIEW_WIDTH)
    optionRightGradationView.topToSuperview()
    optionRightGradationView.bottomToSuperview()
    self.optionRightGradationView = optionRightGradationView
    
    //profileBasicView
    let profileBasicView = ANIProfileBasicView()
    profileBasicView.currentUser = currentUser
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
    
    //needLoginView
    let needLoginView = ANINeedLoginView()
    needLoginView.isHidden = true
    needLoginView.setupMessage(text: "プロフィールを利用するには\nログインが必要です")
    needLoginView.delegate = self
    self.view.addSubview(needLoginView)
    needLoginView.edgesToSuperview()
    self.needLoginView = needLoginView
  }
  
  private func showNeedLoginView() {
    guard let needLoginView = self.needLoginView else { return }
    
    if ANISessionManager.shared.isAnonymous == true {
      needLoginView.isHidden = false
    } else {
      needLoginView.isHidden = true
    }
  }
  
  func playVideo() {
    guard let profileBasicView = self.profileBasicView else { return }
    
    profileBasicView.playVideo()
  }
  
  private func stopVideo() {
    guard let profileBasicView = self.profileBasicView else { return }

    profileBasicView.stopVideo()
  }
  
  //MAKR: notification
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(imageCellTapped: self, selector: #selector(presentImageBrowser(_:)))
    ANINotificationManager.receive(profileEditButtonTapped: self, selector: #selector(openProfileEdit))
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
  
  @objc private func openProfileEdit() {
    let profileEditViewController = ANIProfileEditViewController()
    profileEditViewController.delegate = self
    profileEditViewController.currentUser = currentUser
    self.present(profileEditViewController, animated: true, completion: nil)
  }
  
  private func reloadNavigationTitle() {
    guard let navigationTitleLabel = self.navigationTitleLabel,
          let currentUser = self.currentUser else { return }
    
    navigationTitleLabel.text = currentUser.userName
  }
  
  private func rejectAnimation() {
    guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
          !isRejectAnimating else { return }
    
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
  
  //MARK: action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
  
  @objc private func option() {
    let optionViewController = ANIOptionViewController()
    optionViewController.hidesBottomBarWhenPushed = true
    self.navigationController?.pushViewController(optionViewController, animated: true)
  }
}

//MARK: ANIProfileBasicViewDelegate
extension ANIProfileViewController: ANIProfileBasicViewDelegate {
  func followingTapped() {
    guard let currentUser = self.currentUser else { return }
    
    let followUserViewController = ANIFollowUserViewContoller()
    followUserViewController.followUserViewMode = .following
    followUserViewController.userId = currentUser.uid
    followUserViewController.hidesBottomBarWhenPushed = true
    self.navigationController?.pushViewController(followUserViewController, animated: true)
  }
  
  func followerTapped() {
    guard let currentUser = self.currentUser else { return }

    let followUserViewController = ANIFollowUserViewContoller()
    followUserViewController.followUserViewMode = .follower
    followUserViewController.userId = currentUser.uid
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
    guard let rejectView = self.rejectView else { return }
    
    rejectView.setRejectText("ログインが必要です。")
    self.rejectAnimation()
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.contentType = contentType
    self.contributionId = id
    
    let popupOptionViewController = ANIPopupOptionViewController()
    popupOptionViewController.modalPresentationStyle = .overCurrentContext
    popupOptionViewController.isMe = isMe
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
    guard let rejectView = self.rejectView else { return }
    
    rejectView.setRejectText("Twitterを開けません。")
    self.rejectAnimation()
  }
  
  func instagramOpenReject() {
    guard let rejectView = self.rejectView else { return }
    
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

//MARK: ANIProfileEditViewControllerDelegate
extension ANIProfileViewController: ANIProfileEditViewControllerDelegate {
  func didEdit() {
    guard let profileBasicView = self.profileBasicView,
          let navigationTitleLabel = self.navigationTitleLabel,
          let currentUser = self.currentUser else { return }
    
    profileBasicView.currentUser = currentUser
    navigationTitleLabel.text = currentUser.userName
  }
}

//MARK: ANINeedLoginViewDelegate
extension ANIProfileViewController: ANINeedLoginViewDelegate {
  func loginButtonTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
  }
}

//MARK: ANIImageBrowserViewControllerDelegate
extension ANIProfileViewController: ANIImageBrowserViewControllerDelegate {
  func imageBrowserDidDissmiss() {
    UIApplication.shared.statusBarStyle = .default
  }
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANIProfileViewController: ANIPopupOptionViewControllerDelegate {
  func deleteContribution() {
    let alertController = UIAlertController(title: nil, message: "投稿を削除しますか？", preferredStyle: .alert)
    
    let deleteAction = UIAlertAction(title: "削除", style: .default) { (action) in
      self.deleteData()
    }
    let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
    
    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func reportContribution() {
  }
  
  func optionTapped(index: Int) {
  }
}

//MAKR: data
extension ANIProfileViewController {
  private func deleteData() {
    guard let contentType = self.contentType, let contributionId = self.contributionId else { return }
    
    let database = Firestore.firestore()
    
    var collection = ""
    var loveIDsCollection = ""
    
    if contentType == .story {
      collection = KEY_STORIES
      loveIDsCollection = KEY_LOVE_STORY_IDS
    } else if contentType == .qna {
      collection = KEY_QNAS
      loveIDsCollection = KEY_LOVE_QNA_IDS
    }
    
    DispatchQueue.global().async {
      database.collection(collection).document(contributionId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("get document error \(error)")
          
          return
        }
        
        database.collection(collection).document(contributionId).delete()
        self.deleteDataAlgolia(contentType: contentType, contributionId: contributionId)
        
        DispatchQueue.main.async {
          if contentType == .story {
            ANINotificationManager.postDeleteStory(id: contributionId)
          } else if contentType == .qna {
            ANINotificationManager.postDeleteQna(id: contributionId)
          }
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          if contentType == .story {
            let story = try FirestoreDecoder().decode(FirebaseStory.self, from: data)
            let storage = Storage.storage()

            if let urls = story.storyImageUrls {
              for url in urls {
                let storageRef = storage.reference(forURL: url)
                
                storageRef.delete { error in
                  if let error = error {
                    DLog(error)
                  }
                }
              }
            }
            
            if let videoUrl = story.storyVideoUrl {
              let storageRef = storage.reference(forURL: videoUrl)
              
              storageRef.delete { error in
                if let error = error {
                  DLog(error)
                }
              }
            }
            
            if let thumbnailImageUrl = story.thumbnailImageUrl {
              let storageRef = storage.reference(forURL: thumbnailImageUrl)
              
              storageRef.delete { error in
                if let error = error {
                  DLog(error)
                }
              }
            }
          } else if contentType == .qna {
            let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: data)
            
            if let urls = qna.qnaImageUrls {
              for url in urls {
                let storage = Storage.storage()
                let storageRef = storage.reference(forURL: url)
                
                storageRef.delete { error in
                  if let error = error {
                    DLog(error)
                  }
                }
              }
            }
          }
        } catch let error {
          DLog(error)
        }
      })
    }
    
    DispatchQueue.global().async {
      database.collection(collection).document(contributionId).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          database.collection(KEY_USERS).document(document.documentID).collection(loveIDsCollection).document(contributionId).delete()
          database.collection(collection).document(contributionId).collection(KEY_LOVE_IDS).document(document.documentID).delete()
        }
      })
      
      database.collection(collection).document(contributionId).collection(KEY_COMMENTS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          database.collection(collection).document(contributionId).collection(KEY_COMMENTS).document(document.documentID).delete()
        }
      })
    }
  }
  
  private func deleteDataAlgolia(contentType: ContentType, contributionId: String) {
    var index: Index?
    
    if contentType == .story {
      index = ANISessionManager.shared.client.index(withName: KEY_STORIES_INDEX)
    } else if contentType == .qna {
      index = ANISessionManager.shared.client.index(withName: KEY_QNAS_INDEX)
    }
    
    DispatchQueue.global().async {
      index?.deleteObject(withID: contributionId)
    }
  }
}

//MARK: UIGestureRecognizerDelegate
extension ANIProfileViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
