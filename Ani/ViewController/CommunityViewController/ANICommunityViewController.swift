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
import FirebaseStorage
import InstantSearchClient
import AVKit

class ANICommunityViewController: UIViewController {
  
  private weak var menuBar: ANICommunityMenuBar?
  private weak var containerCollectionView: UICollectionView?
  
  private let CONTRIBUTION_BUTTON_HEIGHT: CGFloat = 55.0
  private weak var contributionButon: ANIImageButtonView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  private var rejectTapView: UIView?
  
  private weak var uploadProgressView: ANIUploadProgressView?
  
  private var selectedIndex: Int = 0
  
  private var contentType: ContentType?
  private var contributionId: String?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
    UIApplication.shared.isStatusBarHidden = false
    setupNotifications()
    
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    } catch {
      DLog("AVAudioSession catgery set error \(error)")
    }
    
    playVideo()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    if !ANISessionManager.shared.isShowEvent {
      showEventIfNeeded()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    stopVideo()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
    
    ANIStoryView.endRefresh()
    ANIQnaView.endRefresh()
  }
  
  private func setup() {
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
    let storyId = NSStringFromClass(ANICommunityStoryCell.self)
    containerCollectionView.register(ANICommunityStoryCell.self, forCellWithReuseIdentifier: storyId)
    let qnaId = NSStringFromClass(ANICommunityQnaCell.self)
    containerCollectionView.register(ANICommunityQnaCell.self, forCellWithReuseIdentifier: qnaId)
    self.view.addSubview(containerCollectionView)
    containerCollectionView.edgesToSuperview()
    self.containerCollectionView = containerCollectionView
    
    //menuBar
    let menuBar = ANICommunityMenuBar()
    menuBar.delegate = self
    self.view.addSubview(menuBar)
    let menuBarHeight = UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT
    menuBar.topToSuperview()
    menuBar.leftToSuperview()
    menuBar.rightToSuperview()
    menuBar.height(menuBarHeight)
    self.menuBar = menuBar
    
    //contributionButon
    let contributionButon = ANIImageButtonView()
    contributionButon.image = UIImage(named: "contributionButton")
    contributionButon.superViewCornerRadius(radius: CONTRIBUTION_BUTTON_HEIGHT / 2)
    contributionButon.superViewDropShadow(opacity: 0.13)
    contributionButon.delegate = self
    self.view.addSubview(contributionButon)
    contributionButon.width(CONTRIBUTION_BUTTON_HEIGHT)
    contributionButon.height(CONTRIBUTION_BUTTON_HEIGHT)
    contributionButon.rightToSuperview(offset: -15.0)
    var tabBarHeight: CGFloat = 0.0
    if let tabBarController = self.tabBarController {
      tabBarHeight = tabBarController.tabBar.height
    }
    contributionButon.bottomToSuperview(offset: -(15.0 + tabBarHeight))
    self.contributionButon = contributionButon
    
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
    
    //uploadProgressView
    let uploadProgressView = ANIUploadProgressView()
    uploadProgressView.alpha = 0.95
    uploadProgressView.isHidden = true
    uploadProgressView.delegate = self
    self.view.addSubview(uploadProgressView)
    uploadProgressView.topToBottom(of: menuBar)
    uploadProgressView.leftToSuperview()
    uploadProgressView.rightToSuperview()
    uploadProgressView.height(50.0)
    self.uploadProgressView = uploadProgressView

    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = true
    self.tabBarController?.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  func playVideo() {
    guard let containerCollectionView = self.containerCollectionView else { return }
    
    for visibleCell in containerCollectionView.visibleCells {
      if let communityStoryCell = visibleCell as? ANICommunityStoryCell {
        communityStoryCell.playVideo()
      }
    }
  }
  
  private func stopVideo() {
    guard let containerCollectionView = self.containerCollectionView else { return }
    
    for visibleCell in containerCollectionView.visibleCells {
      if let communityStoryCell = visibleCell as? ANICommunityStoryCell {
        communityStoryCell.stopVideo()
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
  
  //MAKR: notification
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(imageCellTapped: self, selector: #selector(presentImageBrowser(_:)))
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(tapHashtag: self, selector: #selector(pushHashtagList))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
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
  
  //action
  @objc private func rejectViewTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
  }
}


//MARK: UICollectionViewDataSource
extension ANICommunityViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return 2
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if indexPath.item == 0 {
      let storyId = NSStringFromClass(ANICommunityStoryCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: storyId, for: indexPath) as! ANICommunityStoryCell
      
      cell.frame.origin.y = collectionView.frame.origin.y
      cell.delegate = self
      return cell
    } else {
      let qnaId = NSStringFromClass(ANICommunityQnaCell.self)
      let cell = collectionView.dequeueReusableCell(withReuseIdentifier: qnaId, for: indexPath) as! ANICommunityQnaCell
      cell.frame.origin.y = collectionView.frame.origin.y
      cell.delegate = self
      return cell
    }
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANICommunityViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: self.view.frame.width, height: self.view.frame.height)
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANICommunityViewController: UICollectionViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let menuBar = self.menuBar, let horizontalBarleftConstraint = menuBar.horizontalBarleftConstraint else { return }
    horizontalBarleftConstraint.constant = scrollView.contentOffset.x / 2
  }
  
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let menuBar = self.menuBar else { return }
    let indexPath = IndexPath(item: Int(targetContentOffset.pointee.x / view.frame.width), section: 0)
    menuBar.menuCollectionView?.selectItem(at: indexPath, animated: true, scrollPosition: .left)
    
    selectedIndex = indexPath.item
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if let cell = cell as? ANICommunityStoryCell {
      cell.isCellSelected = true
    } else if let cell = cell as? ANICommunityQnaCell {
      cell.isCellSelected = true
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if let cell = cell as? ANICommunityStoryCell {
      cell.isCellSelected = false
    } else if let cell = cell as? ANICommunityQnaCell {
      cell.isCellSelected = false
    }
  }
}

//MARK: ANIButtonViewDelegate
extension ANICommunityViewController: ANIButtonViewDelegate{
  func buttonViewTapped(view: ANIButtonView) {
    
    if view === self.contributionButon {
      if ANISessionManager.shared.isAnonymous == false {
        if selectedIndex == 0 {
          let contributionViewController = ANIContributionViewController()
          contributionViewController.navigationTitle = "STORY"
          contributionViewController.selectedContributionMode = ContributionMode.story
          contributionViewController.delegate = self
          let contributionNV = UINavigationController(rootViewController: contributionViewController)
          self.present(contributionNV, animated: true, completion: nil)
        } else {
          let contributionViewController = ANIContributionViewController()
          contributionViewController.navigationTitle = "Q&A"
          contributionViewController.selectedContributionMode = ContributionMode.qna
          contributionViewController.delegate = self
          let contributionNV = UINavigationController(rootViewController: contributionViewController)
          self.present(contributionNV, animated: true, completion: nil)
        }
      } else {
        reject()
      }
    }
  }
}

//MARK: ANICommunityMenuBarDelegate
extension ANICommunityViewController: ANICommunityMenuBarDelegate {
  func didSelectCell(index: IndexPath) {
    guard let containerCollectionView = self.containerCollectionView else { return }
    containerCollectionView.scrollToItem(at: index, at: .left, animated: true)
    selectedIndex = index.item
  }
}

//MARK: ANIStoryViewDelegate
extension ANICommunityViewController: ANIStoryViewDelegate {
  func didSelectStoryViewCell(selectedStory: FirebaseStory, user: FirebaseUser) {
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
  
  func reject() {
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
  
  func didSelectRankingCell(rankingStory: FirebaseStory, ranking: Int) {
    let rankingStoryDetailViewController = ANIRankingStoryDetailViewController()
    rankingStoryDetailViewController.hidesBottomBarWhenPushed = true
    rankingStoryDetailViewController.rankingStory = rankingStory
    rankingStoryDetailViewController.ranking = ranking
    self.navigationController?.pushViewController(rankingStoryDetailViewController, animated: true)
  }
  
  func showEvent(event: FirebaseEvent) {
    let eventPopupViewController = ANIEventPopupViewController()
    eventPopupViewController.event = event
    eventPopupViewController.modalPresentationStyle = .overCurrentContext
    self.tabBarController?.present(eventPopupViewController, animated: false, completion: nil)
  }
}

//MARK: ANIQnaViewDelegate
extension ANICommunityViewController: ANIQnaViewDelegate {
  func qnaViewCellDidSelect(selectedQna: FirebaseQna, user: FirebaseUser) {
    let commentViewController = ANICommentViewController()
    commentViewController.hidesBottomBarWhenPushed = true
    commentViewController.commentMode = CommentMode.qna
    commentViewController.qna = selectedQna
    commentViewController.user = user
    self.navigationController?.pushViewController(commentViewController, animated: true)
  }
}

//MARK: ANIImageBrowserViewControllerDelegate
extension ANICommunityViewController: ANIImageBrowserViewControllerDelegate {
  func imageBrowserDidDissmiss() {
    UIApplication.shared.statusBarStyle = .default
  }
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANICommunityViewController: ANIPopupOptionViewControllerDelegate {
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
    let alertController = UIAlertController(title: nil, message: "投稿を通報しますか？", preferredStyle: .alert)
    
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
    if let currentUserId = ANISessionManager.shared.currentUserUid {
      if index == 0 {
        guard let contentType = self.contentType,
              let contributionId = self.contributionId else { return }
        
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

//MARK: UIGestureRecognizerDelegate
extension ANICommunityViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

//MARK: ANIContributionViewControllerDelegate
extension ANICommunityViewController: ANIContributionViewControllerDelegate {
  func loadThumnailImage(thumbnailImage: UIImage?) {
    guard let uploadProgressView = self.uploadProgressView,
          let thumbnailImageView = uploadProgressView.thumbnailImageView else { return }

    if let thumbnailImage = thumbnailImage {
      thumbnailImageView.image = thumbnailImage
      thumbnailImageView.isHidden = false
    } else {
      thumbnailImageView.image = nil
      thumbnailImageView.isHidden = true
    }
  }
  
  func updateProgress(progress: CGFloat) {
    guard let uploadProgressView = self.uploadProgressView else { return }
    
    uploadProgressView.updateProgress(progress: progress)
    
    if progress != 1.0 {
      UIView.animate(withDuration: 0.2) {
        uploadProgressView.alpha = 0.95
      }
      uploadProgressView.isHidden = false
    }
  }
}

//MARK: ANIUploadProgressViewDelegate
extension ANICommunityViewController: ANIUploadProgressViewDelegate {
  func completeProgress() {
    guard let uploadProgressView = self.uploadProgressView else { return }
    
    UIView.animate(withDuration: 0.2, animations: {
      uploadProgressView.alpha = 0.0
    }) { (complete) in
      uploadProgressView.isHidden = true
    }
  }
}

//MAKR: data
extension ANICommunityViewController {
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
  
  private func reportData() {
    guard let contentType = self.contentType, let contributionId = self.contributionId else { return }
    
    let database = Firestore.firestore()
    
    var contentTypeString = ""

    if contentType == .recruit {
      contentTypeString = KEY_RECRUIT
    } else if contentType == .story {
      contentTypeString = KEY_STORY
    } else if contentType == .qna {
      contentTypeString = KEY_QNA
    }
    
    let date = ANIFunction.shared.getToday()
    let values = [KEY_CONTENT_TYPE: contentTypeString, KEY_DATE: date]
    database.collection(KEY_REPORTS).document(contributionId).collection(KEY_REPORT).addDocument(data: values)
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
