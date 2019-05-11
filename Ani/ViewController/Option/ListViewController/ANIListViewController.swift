//
//  ANIListViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/25.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import FirebaseStorage
import InstantSearchClient

class ANIListViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var navigationTitleLabel: UILabel?
  private weak var backButton: UIButton?
  
  private weak var listView: ANIListView?
  
  var list: List?
  
  private var contentType: ContentType?
  private var contributionId: String?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  override func viewDidLoad() {
    setup()
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
    
    //navigationTitleLabel
    let navigationTitleLabel = UILabel()
    if let list = list {
      navigationTitleLabel.text = list.rawValue
    }
    navigationTitleLabel.textColor = ANIColor.dark
    navigationTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBase.addSubview(navigationTitleLabel)
    navigationTitleLabel.centerInSuperview()
    self.navigationTitleLabel = navigationTitleLabel
    
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
    
    //listView
    let listView = ANIListView()
    if let list = self.list {
      listView.list = list
    }
    listView.delegate = self
    self.view.addSubview(listView)
    listView.topToBottom(of: myNavigationBar)
    listView.edgesToSuperview(excluding: .top)
    self.listView = listView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = true
    self.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  func playVideo() {
    guard let listView = self.listView else { return }
    
    listView.playVideo()
  }
  
  private func stopVideo() {
    guard let listView = self.listView else { return }
    
    listView.stopVideo()
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(imageCellTapped: self, selector: #selector(presentImageBrowser(_:)))
    ANINotificationManager.receive(tapHashtag: self, selector: #selector(pushHashtagList))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func pushOtherProfile(_ notification: NSNotification) {
    guard let userId = notification.object as? String else { return }
    
    if let currentUserUid = ANISessionManager.shared.currentUserUid, currentUserUid != userId {
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
    self.present(imageBrowserViewController, animated: false, completion: nil)
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
  
  //MARK: action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
}

//MARK: ANIListViewDelegate
extension ANIListViewController: ANIListViewDelegate {
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
  
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser) {
    let supportViewController = ANISupportViewController()
    supportViewController.modalPresentationStyle = .overCurrentContext
    supportViewController.recruit = supportRecruit
    supportViewController.user = user
    self.tabBarController?.present(supportViewController, animated: false, completion: nil)
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
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANIListViewController: ANIPopupOptionViewControllerDelegate {
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
      self.reportData()
    }
    let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
    
    alertController.addAction(reportAction)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func optionTapped(index: Int) {
    guard let contentType = self.contentType,
          let contributionId = self.contributionId,
          let currentUserId = ANISessionManager.shared.currentUserUid else { return }
    
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
extension ANIListViewController {
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
      contentTypeString = "recurit"
    } else if contentType == .story {
      contentTypeString = "story"
    } else if contentType == .qna {
      contentTypeString = "qna"
    }
    
    let date = ANIFunction.shared.getToday()
    let values = ["contentType": contentTypeString, "date": date]
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

//MARK: UIGestureRecognizerDelegate
extension ANIListViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
