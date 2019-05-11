//
//  ANICommentViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/21.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase

enum CommentMode {
  case story
  case qna
}

class ANICommentViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var backButton: UIButton?
  private let NAVIGATION_PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 30.0
  private weak var navigationProfileImageView: UIImageView?
  
  private weak var commentView: ANICommentView?
  
  private var commentBarBottomConstraint: Constraint?
  private var commentBarOriginalBottomConstraintConstant: CGFloat?
  private weak var commentBar: ANICommentBar?
  private weak var anonymousCommentTapView: UIView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  private var rejectTapView: UIView?
    
  var commentMode: CommentMode?
  
  var story: FirebaseStory?
  var qna: FirebaseQna?
  var user: FirebaseUser?
  var selectedComment: FirebaseComment?
  var selectedCommentUser: FirebaseUser?
  
  private var commentId: String?
  private var contentId: String?
  
  private var isfirstLoad: Bool = true
  
  override func viewDidLoad() {
    setup()
    passingData()
    setupNavigationProfileImage()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    setupNotifications()
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
    
    //navigationProfileImageView
    let navigationProfileImageView = UIImageView()
    navigationProfileImageView.contentMode = .scaleAspectFit
    navigationProfileImageView.layer.cornerRadius = NAVIGATION_PROFILE_IMAGE_VIEW_HEIGHT / 2
    navigationProfileImageView.layer.masksToBounds = true
    myNavigationBase.addSubview(navigationProfileImageView)
    navigationProfileImageView.width(NAVIGATION_PROFILE_IMAGE_VIEW_HEIGHT)
    navigationProfileImageView.height(NAVIGATION_PROFILE_IMAGE_VIEW_HEIGHT)
    navigationProfileImageView.centerInSuperview()
    self.navigationProfileImageView = navigationProfileImageView
    
    //commentBar
    let commentBar = ANICommentBar()
    self.view.addSubview(commentBar)
    commentBar.leftToSuperview()
    commentBar.rightToSuperview()
    commentBarBottomConstraint = commentBar.bottomToSuperview(usingSafeArea: true)
    commentBarOriginalBottomConstraintConstant = commentBarBottomConstraint?.constant
    self.commentBar = commentBar
    
    //anonymousCommentTapView
    let anonymousCommentTapView = UIView()
    if !ANISessionManager.shared.isAnonymous {
      anonymousCommentTapView.isUserInteractionEnabled = false
    } else {
      anonymousCommentTapView.isUserInteractionEnabled = true
    }
    let anonymousCommentTapGesture = UITapGestureRecognizer(target: self, action: #selector(rejectAnimation))
    anonymousCommentTapView.addGestureRecognizer(anonymousCommentTapGesture)
    self.view.addSubview(anonymousCommentTapView)
    anonymousCommentTapView.edges(to: commentBar)
    self.anonymousCommentTapView = anonymousCommentTapView
    
    //commentView
    let commentView = ANICommentView()
    commentView.delegate = self
    self.view.addSubview(commentView)
    commentView.topToBottom(of: myNavigationBar)
    commentView.leftToSuperview()
    commentView.rightToSuperview()
    commentView.bottomToTop(of: commentBar)
    self.commentView = commentView
    
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
  
  private func passingData() {
    guard let commentView = self.commentView,
          let commentBar = self.commentBar,
          let commentMode = self.commentMode,
          let user = self.user else { return }

    commentView.commentMode = commentMode
    commentBar.commentMode = commentMode
    commentBar.user = user
    
    switch commentMode {
    case .story:
      commentView.story = story
      commentBar.story = story
    case .qna:
      commentView.qna = qna
      commentBar.qna = qna
    }
    
    if let selectedComment = self.selectedComment {
      commentView.selectedComment = selectedComment
    }
  }
  
  private func setupNavigationProfileImage() {
    guard let navigationProfileImageView = self.navigationProfileImageView,
          let user = self.user,
          let profileImageUrl = user.profileImageUrl else { return }
    
    navigationProfileImageView.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
  }
  
  //MARK: notification
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
    ANINotificationManager.receive(keyboardWillHide: self, selector: #selector(keyboardWillHide))
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(login: self, selector: #selector(setAnonymousCommentTapViewUserInteractionEnabled))
    ANINotificationManager.receive(logout: self, selector: #selector(setAnonymousCommentTapViewUserInteractionEnabled))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
      let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
      let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
      let commentBarBottomConstraint = self.commentBarBottomConstraint,
      let window = UIApplication.shared.keyWindow else { return }
    
    let h = keyboardFrame.height
    let bottomSafeArea = window.safeAreaInsets.bottom
    
    commentBarBottomConstraint.constant = -h + bottomSafeArea
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
      let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
      let commentBarOriginalBottomConstraintConstant = self.commentBarOriginalBottomConstraintConstant,
      let commentBarBottomConstraint = self.commentBarBottomConstraint else { return }
    
    commentBarBottomConstraint.constant = commentBarOriginalBottomConstraintConstant
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
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
  
  @objc private func setAnonymousCommentTapViewUserInteractionEnabled() {
    guard let anonymousCommentTapView = self.anonymousCommentTapView,
          let commentBar = self.commentBar else { return }
    
    commentBar.setProfileImage()
    
    if !ANISessionManager.shared.isAnonymous {
      anonymousCommentTapView.isUserInteractionEnabled = false
    } else {
      anonymousCommentTapView.isUserInteractionEnabled = true
    }
  }
  
  @objc private func rejectAnimation() {
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
}

//MARK: ANICommentViewDelegate
extension ANICommentViewController: ANICommentViewDelegate {
  func reject() {
    self.rejectAnimation()
  }
  
  func popupOptionView(isMe: Bool, contentId: String, commentId: String) {
    self.contentId = contentId
    self.commentId = commentId
    
    let popupOptionViewController = ANIPopupOptionViewController()
    popupOptionViewController.modalPresentationStyle = .overCurrentContext
    popupOptionViewController.isMe = isMe
    popupOptionViewController.delegate = self
    self.tabBarController?.present(popupOptionViewController, animated: false, completion: nil)
  }
  
  func commentCellTapped(comment: FirebaseComment, user: FirebaseUser) {
    guard let commentBar = self.commentBar else { return }
    
    commentBar.showParentCommentUser(comment: comment, parentCommentUser: user, isAnimated: true)
  }
  
  func loadedComments() {
    guard let commentBar = self.commentBar else { return }
    
    if let selectedComment = self.selectedComment,
      let selectedCommentUser = self.selectedCommentUser,
      isfirstLoad {
      commentBar.showParentCommentUser(comment: selectedComment, parentCommentUser: selectedCommentUser, isAnimated: false)
      
      isfirstLoad = false
    }
  }
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANICommentViewController: ANIPopupOptionViewControllerDelegate {
  func deleteContribution() {
    let alertController = UIAlertController(title: nil, message: "コメントを削除しますか？", preferredStyle: .alert)
    
    let deleteAction = UIAlertAction(title: "削除", style: .default) { (action) in
      self.deleteData()
    }
    let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
    
    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func reportContribution() {
    let alertController = UIAlertController(title: nil, message: "コメントを通報しますか？", preferredStyle: .alert)
    
    let reportAction = UIAlertAction(title: "通報", style: .default) { (action) in
      if !ANISessionManager.shared.isAnonymous {
        self.reportData()
      } else {
        self.rejectAnimation()
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

//MARK: data
extension ANICommentViewController {
  private func deleteData() {
    guard let contentId = self.contentId,
          let commentId = self.commentId else { return }
    
    let database = Firestore.firestore()
    
    var collection = ""
    
    if commentMode == .story {
      collection = KEY_STORIES
    } else if commentMode == .qna {
      collection = KEY_QNAS
    }
    
    DispatchQueue.global().async {
     database.collection(collection).document(contentId).collection(KEY_COMMENTS).document(commentId).delete()
      DispatchQueue.main.async {
        ANINotificationManager.postDeleteComment(id: commentId)
      }
    }
    
    DispatchQueue.global().async {
      database.collection(collection).document(contentId).collection(KEY_COMMENTS).document(commentId).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")

          return
        }

        guard let snapshot = snapshot else { return }

        for document in snapshot.documents {
          database.collection(collection).document(contentId).collection(KEY_COMMENTS).document(commentId).collection(KEY_LOVE_IDS).document(document.documentID).delete()
        }
      })
    }
  }
  
  private func reportData() {
    guard let commentId = self.commentId else { return }
    
    let database = Firestore.firestore()
    
    let date = ANIFunction.shared.getToday()
    let values = [KEY_CONTENT_TYPE: KEY_COMMENT, KEY_DATE: date]
    database.collection(KEY_REPORTS).document(commentId).collection(KEY_REPORT).addDocument(data: values)
  }
}
