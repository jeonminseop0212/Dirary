//
//  ANISearchViewController.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase
import FirebaseStorage
import InstantSearchClient

class ANISearchViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBarTopConstroint: Constraint?
  
  private weak var categoriesView: ANISearchCategoriesView?
  static let CATEGORIES_VIEW_HEIGHT: CGFloat = 47.0
  
  private weak var searchBar: UISearchBar?
  private weak var searchView: ANISearchView?
  
  private weak var popularUsersView: ANIPopularUsersView?
  
  private var selectedIndex: Int = 0 {
    didSet {
      guard let searchView = self.searchView,
            let searchBar = self.searchBar,
            let popularUsersView = self.popularUsersView else { return }

      if let text = searchBar.textField?.text, text != "" {
        searchView.searchText = text
      }

      if selectedIndex == 0 {
        searchView.selectedCategory = .user
      } else {
        searchView.selectedCategory = .qna
      }
      
      if searchBar.textField?.text != "" {
        UIView.animate(withDuration: 0.2) {
          popularUsersView.alpha = 0.0
        }
      }
    }
  }
  
  private var searchText: String = "" {
    didSet {
      guard let searchView = self.searchView,
            let searchBar = self.searchBar,
            let popularUsersView = self.popularUsersView else { return }

      searchView.searchText = searchText
      
      if searchBar.textField?.text != "" {
        UIView.animate(withDuration: 0.2) {
          popularUsersView.alpha = 0.0
        }
      }
    }
  }
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  private var rejectTapView: UIView?
  
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
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    guard let popularUsersView = self.popularUsersView else { return }
    
    removeNotifications()
    
    popularUsersView.endRefresh()
  }
  
  private func setup() {
    //basic
    ANIOrientation.lockOrientation(.portrait)
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    self.automaticallyAdjustsScrollViewInsets = false
    
    //searchView
    let searchView = ANISearchView()
    searchView.delegate = self
    self.view.addSubview(searchView)
    searchView.topToSuperview(usingSafeArea: true)
    searchView.edgesToSuperview(excluding: .top)
    self.searchView = searchView
    
    //popularUsersView
    let popularUsersView = ANIPopularUsersView()
    popularUsersView.delegate = self
    self.view.addSubview(popularUsersView)
    popularUsersView.topToSuperview(usingSafeArea: true)
    popularUsersView.edgesToSuperview(excluding: .top)
    self.popularUsersView = popularUsersView
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = .white
    self.view.addSubview(myNavigationBar)
    myNavigationBarTopConstroint = myNavigationBar.topToSuperview(usingSafeArea: true)
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //searchBar
    let searchBar = UISearchBar()
    searchBar.placeholder = "Search"
    searchBar.textField?.backgroundColor = ANIColor.lightGray
    searchBar.delegate = self
    searchBar.backgroundImage = UIImage()
    searchBar.tintColor = ANIColor.darkGray
    myNavigationBar.addSubview(searchBar)
    searchBar.topToSuperview()
    searchBar.leftToSuperview()
    searchBar.rightToSuperview()
    searchBar.bottomToSuperview()
    self.searchBar = searchBar
    
    //categoriesView
    let categoriesView = ANISearchCategoriesView()
    categoriesView.delegate = self
    self.view.addSubview(categoriesView)
    categoriesView.topToBottom(of: myNavigationBar)
    categoriesView.leftToSuperview()
    categoriesView.rightToSuperview()
    categoriesView.height(ANIRecruitViewController.FILTERS_VIEW_HEIGHT)
    self.categoriesView = categoriesView
    
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
    self.tabBarController?.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(viewScrolled: self, selector: #selector(hideKeyboard))
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(imageCellTapped: self, selector: #selector(presentImageBrowser(_:)))
    ANINotificationManager.receive(tapHashtag: self, selector: #selector(pushHashtagList))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func hideKeyboard() {
    guard let searchBar = self.searchBar,
      let searchBarTextField = searchBar.textField else { return }
    if searchBarTextField.isFirstResponder {
      searchBarTextField.resignFirstResponder()
      searchBar.setShowsCancelButton(false, animated: true)
      
      if let searchCancelButton = searchBar.cancelButton {
        searchCancelButton.alpha = 0.0
      }
    }
  }
  
  @objc private func pushOtherProfile(_ notification: NSNotification) {
    guard let userId = notification.object as? String else { return }
    
    let otherProfileViewController = ANIOtherProfileViewController()
    otherProfileViewController.hidesBottomBarWhenPushed = true
    otherProfileViewController.userId = userId
    self.navigationController?.pushViewController(otherProfileViewController, animated: true)
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
  
  @objc private func rejectViewTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
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
  
  private func navigationAnimation(scrollY: CGFloat) {
    guard let myNavigationBarTopConstroint = self.myNavigationBarTopConstroint,
          let searchBar = self.searchBar,
          let categoriesView = self.categoriesView,
          let categoryCollectionView = categoriesView.categoryCollectionView else { return }
    
    let topHeight = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT
    let newScrollY = topHeight + scrollY
    
    //navigation animate
    if topHeight < newScrollY {
      if scrollY < topHeight {
        myNavigationBarTopConstroint.constant = -scrollY
        self.view.layoutIfNeeded()
        
        let alpha = 1 - (scrollY / topHeight)
        searchBar.alpha = alpha
        categoryCollectionView.alpha = alpha
      } else {
        myNavigationBarTopConstroint.constant = -topHeight
        self.view.layoutIfNeeded()
        
        searchBar.alpha = 0.0
        categoryCollectionView.alpha = 0.0
      }
    } else {
      myNavigationBarTopConstroint.constant = 0.0
      self.view.layoutIfNeeded()
      
      searchBar.alpha = 1.0
      categoryCollectionView.alpha = 1.0
    }
  }
}

//MARK: UISearchBarDelegate
extension ANISearchViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    guard let searchBarTextField = searchBar.textField,
          let text = searchBarTextField.text else { return }
    
    if searchBarTextField.isFirstResponder {
      searchBarTextField.resignFirstResponder()
      
      self.searchText = text
    }
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    guard let searchBarTextField = searchBar.textField,
          let popularUsersView = self.popularUsersView else { return }
    
    if searchBarTextField.isFirstResponder {
      searchBarTextField.resignFirstResponder()
    }
    
    searchBar.setShowsCancelButton(false, animated: true)
    if let searchCancelButton = searchBar.cancelButton {
      searchCancelButton.alpha = 0.0
    }
    
    UIView.animate(withDuration: 0.2) {
      popularUsersView.alpha = 1.0
    }
  }

  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    searchBar.setShowsCancelButton(true, animated: true)
    if let searchCancelButton = searchBar.cancelButton {
      searchCancelButton.alpha = 1.0
    }
    return true
  }
}

//MARK: ANIUserSearchViewDelegate
extension ANISearchViewController: ANISearchViewDelegate {
  func searchViewDidScroll(scrollY: CGFloat) {
    guard let popularUsersView = self.popularUsersView else { return }
    
    if popularUsersView.alpha == 0.0 {
      navigationAnimation(scrollY: scrollY)
    }
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
}

//MARK: ANIPopularUsersViewDelegate
extension ANISearchViewController: ANIPopularUsersViewDelegate {
  func popularUsersViewDidScroll(scrollY: CGFloat) {
    guard let popularUsersView = self.popularUsersView else { return }

    if popularUsersView.alpha == 1.0 {
      navigationAnimation(scrollY: scrollY)
    }
  }
}

//MARK: ANISearchCategoriesViewDelegate
extension ANISearchViewController: ANISearchCategoriesViewDelegate {
  func didSelectedCell(index: Int) {
    selectedIndex = index
  }
}

//MARK: ANIImageBrowserViewControllerDelegate
extension ANISearchViewController: ANIImageBrowserViewControllerDelegate {
  func imageBrowserDidDissmiss() {
    UIApplication.shared.statusBarStyle = .default
  }
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANISearchViewController: ANIPopupOptionViewControllerDelegate {
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
    guard let contentType = self.contentType,
          let contributionId = self.contributionId else { return }
    
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
extension ANISearchViewController {
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
extension ANISearchViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
