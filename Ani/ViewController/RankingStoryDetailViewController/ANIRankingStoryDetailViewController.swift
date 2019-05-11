//
//  ANIStoryDetailViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/11/26.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase
import FirebaseStorage
import InstantSearchClient

class ANIRankingStoryDetailViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var backButton: UIButton?
  private weak var navigationCrownImageView: UIImageView?
  
  private weak var rankingStoryDetailView: ANIRankingStoryDetailView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  private var rejectTapView: UIView?
  
  var rankingStory: FirebaseStory?
  var ranking: Int = -1
  
  override func viewDidLoad() {
    setup()
    setupNavigationCrownImage(ranking: ranking)
  }
  
  override func viewWillAppear(_ animated: Bool) {
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
    
    //navigationCrownImageView
    let navigationCrownImageView = UIImageView()
    navigationCrownImageView.contentMode = .scaleAspectFit
    myNavigationBase.addSubview(navigationCrownImageView)
    navigationCrownImageView.width(24.0)
    navigationCrownImageView.height(23.0)
    navigationCrownImageView.centerInSuperview()
    self.navigationCrownImageView = navigationCrownImageView
    
    //rankingStoryDetailView
    let rankingStoryDetailView = ANIRankingStoryDetailView()
    rankingStoryDetailView.story = rankingStory
    rankingStoryDetailView.delegate = self
    self.view.addSubview(rankingStoryDetailView)
    rankingStoryDetailView.topToBottom(of: myNavigationBar)
    rankingStoryDetailView.edgesToSuperview(excluding: .top)
    self.rankingStoryDetailView = rankingStoryDetailView
    
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
    let rejectTapGesture = UITapGestureRecognizer(target: self, action: #selector(rejectViewTapped))
    rejectTapView.addGestureRecognizer(rejectTapGesture)
    rejectTapView.isHidden = true
    rejectTapView.backgroundColor = .clear
    self.view.addSubview(rejectTapView)
    rejectTapView.size(to: rejectView)
    rejectTapView.topToSuperview()
    self.rejectTapView = rejectTapView
  }
  
  func playVideo() {
    guard let rankingStoryDetailView = self.rankingStoryDetailView else { return }
    
    rankingStoryDetailView.playVideo()
  }
  
  private func stopVideo() {
    guard let rankingStoryDetailView = self.rankingStoryDetailView else { return }
    
    rankingStoryDetailView.stopVideo()
  }
  
  private func setupNavigationCrownImage(ranking: Int) {
    guard let navigationCrownImageView = self.navigationCrownImageView else { return }
    
    if ranking == 0 {
      navigationCrownImageView.image = UIImage(named: "goldCrown")
    } else if ranking == 1 {
      navigationCrownImageView.image = UIImage(named: "silverCrown")
    } else if ranking == 2 {
      navigationCrownImageView.image = UIImage(named: "brownCrown")
    }
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(tapHashtag: self, selector: #selector(pushHashtagList))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  //MARK: Action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
  
  @objc private func rejectViewTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
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
}

//MARK: ANIRankingStoryDetailViewDelegate
extension ANIRankingStoryDetailViewController: ANIRankingStoryDetailViewDelegate {
  func storyViewCellDidSelect(selectedStory: FirebaseStory, user: FirebaseUser) {
    let commentViewController = ANICommentViewController()
    commentViewController.hidesBottomBarWhenPushed = true
    commentViewController.commentMode = CommentMode.story
    commentViewController.story = selectedStory
    commentViewController.user = user
    self.navigationController?.pushViewController(commentViewController, animated: true)
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    let popupOptionViewController = ANIPopupOptionViewController()
    popupOptionViewController.modalPresentationStyle = .overCurrentContext
    popupOptionViewController.isMe = isMe
    popupOptionViewController.delegate = self
    self.tabBarController?.present(popupOptionViewController, animated: false, completion: nil)
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
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANIRankingStoryDetailViewController: ANIPopupOptionViewControllerDelegate {
  func deleteContribution() {
    let alertController = UIAlertController(title: nil, message: "投稿を削除しますか？", preferredStyle: .alert)
    
    let deleteAction = UIAlertAction(title: "削除", style: .default) { (action) in
      self.deleteStory()
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
        self.reportStory()
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
  }
}

//MAKR: ANIPopupOptionViewControllerDelegate
extension ANIRankingStoryDetailViewController {
  private func deleteStory() {
    guard let rankingStory = self.rankingStory,
          let rankingStoryId = rankingStory.id else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_STORIES).document(rankingStoryId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("get document error \(error)")
          
          return
        }
        
        database.collection(KEY_STORIES).document(rankingStoryId).delete()
        self.delegateStoryAlgolia(storyId: rankingStoryId)
        
        DispatchQueue.main.async {
          self.navigationController?.popViewController(animated: true)
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
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
        } catch let error {
          DLog(error)
        }
      })
    }
    
    DispatchQueue.global().async {
      database.collection(KEY_STORIES).document(rankingStoryId).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          database.collection(KEY_USERS).document(document.documentID).collection(KEY_LOVE_STORY_IDS).document(rankingStoryId).delete()
          database.collection(KEY_STORIES).document(rankingStoryId).collection(KEY_LOVE_IDS).document(document.documentID).delete()
        }
      })
      
      database.collection(KEY_STORIES).document(rankingStoryId).collection(KEY_COMMENTS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          database.collection(KEY_STORIES).document(rankingStoryId).collection(KEY_COMMENTS).document(document.documentID).delete()
        }
      })
    }
  }
  
  private func delegateStoryAlgolia(storyId: String) {
    let index = ANISessionManager.shared.client.index(withName: KEY_STORIES_INDEX)
    
    DispatchQueue.global().async {
      index.deleteObject(withID: storyId)
    }
  }
  
  private func reportStory() {
    guard let rankingStory = self.rankingStory,
          let rankingStoryId = rankingStory.id else { return }
    
    let database = Firestore.firestore()
    
    let contentTypeString = "story"
    let date = ANIFunction.shared.getToday()
    let values = ["contentType": contentTypeString, "date": date]
    database.collection(KEY_REPORTS).document(rankingStoryId).collection(KEY_REPORT).addDocument(data: values)
  }
}

