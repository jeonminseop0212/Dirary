//
//  CommentBar.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/22.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import GrowingTextView
import FirebaseFirestore
import CodableFirebase
import TinyConstraints

class ANICommentBar: UIView {
  
  private var parentCommentUserViewTopConstraint: Constraint?
  private weak var parentCommentUserView: UIView?
  private weak var parentUserNameLabel: UILabel?
  private weak var cancelCommentButton: UIButton?
  
  private weak var textViewBase: UIView?
  
  private weak var profileImageView: UIImageView?
  
  private weak var commentTextViewBG: UIView?
  private weak var commentTextView: GrowingTextView?
  
  private weak var commentContributionButton: UIButton?
  
  var commentMode: CommentMode?

  var story: FirebaseStory?
  var qna: FirebaseQna?
    
  var user: FirebaseUser?
  
  private var parentComment: FirebaseComment?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    setProfileImage()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //parentCommentUserView
    let parentCommentUserView = UIView()
    parentCommentUserView.backgroundColor = ANIColor.bg
    parentCommentUserView.alpha = 0.0
    addSubview(parentCommentUserView)
    parentCommentUserView.topToSuperview()
    parentCommentUserView.leftToSuperview()
    parentCommentUserView.rightToSuperview()
    parentCommentUserView.height(40.0)
    self.parentCommentUserView = parentCommentUserView
    
    //cancelCommentButton
    let cancelCommentButton = UIButton()
    cancelCommentButton.setImage(UIImage(named: "cancelCommentButton"), for: .normal)
    cancelCommentButton.addTarget(self, action: #selector(cancelComment), for: .touchUpInside)
    parentCommentUserView.addSubview(cancelCommentButton)
    cancelCommentButton.rightToSuperview(offset: -10.0)
    cancelCommentButton.centerYToSuperview()
    cancelCommentButton.width(25.0)
    cancelCommentButton.height(25.0)
    self.cancelCommentButton = cancelCommentButton
    
    //parentUserNameLabel
    let parentUserNameLabel = UILabel()
    parentUserNameLabel.textColor = ANIColor.darkGray
    parentUserNameLabel.font = UIFont.systemFont(ofSize: 13.0)
    parentCommentUserView.addSubview(parentUserNameLabel)
    parentUserNameLabel.leftToSuperview(offset: 15.0)
    parentUserNameLabel.rightToLeft(of: cancelCommentButton, offset: -10.0)
    parentUserNameLabel.centerYToSuperview()
    self.parentUserNameLabel = parentUserNameLabel
    
    //textViewBase
    let textViewBase = UIView()
    textViewBase.backgroundColor = .white
    addSubview(textViewBase)
    textViewBase.edgesToSuperview(excluding: .top)
    self.textViewBase = textViewBase
    
    parentCommentUserViewTopConstraint = parentCommentUserView.top(to: textViewBase, offset: 0.0)
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.layer.cornerRadius = 40.0 / 2
    profileImageView.layer.masksToBounds = true
    profileImageView.contentMode = .scaleAspectFill
    textViewBase.addSubview(profileImageView)
    profileImageView.width(40.0)
    profileImageView.height(40.0)
    profileImageView.bottomToSuperview(offset: -10.0)
    profileImageView.leftToSuperview(offset: 10.0)
    self.profileImageView = profileImageView
    
    //commentTextViewBG
    let commentTextViewBG = UIView()
    commentTextViewBG.layer.cornerRadius = profileImageView.layer.cornerRadius
    commentTextViewBG.layer.masksToBounds = true
    commentTextViewBG.layer.borderColor = ANIColor.gray.cgColor
    commentTextViewBG.layer.borderWidth = 1.0
    textViewBase.addSubview(commentTextViewBG)
    let bgInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    commentTextViewBG.leftToRight(of: profileImageView, offset: 10.0)
    commentTextViewBG.edgesToSuperview(excluding: .left, insets: bgInsets)
    self.commentTextViewBG = commentTextViewBG
    
    //commentContributionButton
    let commentContributionButton = UIButton()
    commentContributionButton.setTitle("投稿する", for: .normal)
    commentContributionButton.setTitleColor(ANIColor.emerald, for: .normal)
    commentContributionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
    commentContributionButton.addTarget(self, action: #selector(contribute), for: .touchUpInside)
    commentContributionButton.isEnabled = false
    commentContributionButton.alpha = 0.3
    commentTextViewBG.addSubview(commentContributionButton)
    commentContributionButton.rightToSuperview(offset: -10.0)
    commentContributionButton.centerY(to: profileImageView)
    commentContributionButton.height(to: profileImageView)
    commentContributionButton.width(60.0)
    self.commentContributionButton = commentContributionButton
    
    //commentTextView
    let commentTextView = GrowingTextView()
    commentTextView.textColor = ANIColor.dark
    commentTextView.font = UIFont.systemFont(ofSize: 15.0)
    commentTextView.placeholder = "コメント"
    commentTextView.showsVerticalScrollIndicator = false
    if let lineHeight = commentTextView.font?.lineHeight {
      commentTextView.minHeight = 30.0
      commentTextView.maxHeight = lineHeight * 6
    }
    commentTextView.delegate = self
    commentTextViewBG.addSubview(commentTextView)
    let insets = UIEdgeInsets(top: 2.5, left: 5.0, bottom: 2.5, right: 5.0)
    commentTextView.edgesToSuperview(excluding: .right,insets: insets)
    commentTextView.rightToLeft(of: commentContributionButton, offset: -5.0)
    self.commentTextView = commentTextView
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(viewScrolled: self, selector: #selector(keyboardHide))
  }
  
  func setProfileImage() {
    guard let profileImageView = self.profileImageView else { return }
    
    if let currentUser = ANISessionManager.shared.currentUser, let profileImageUrl = currentUser.profileImageUrl {
      profileImageView.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
    } else {
      profileImageView.image = UIImage()
    }
  }
  
  @objc private func keyboardHide() {
    guard let commentTextView = self.commentTextView else { return }
    commentTextView.endEditing(true)
  }
  
  private func updateCommentContributionButton(text: String) {
    guard let commentContributionButton = self.commentContributionButton else { return }
    
    if text.count > 0 {
      commentContributionButton.isEnabled = true
      commentContributionButton.alpha = 1.0
    } else {
      commentContributionButton.isEnabled = false
      commentContributionButton.alpha = 0.3
    }
  }
  
  private func updateNoti(commentId: String, comment: String) {
    guard let currentUser = ANISessionManager.shared.currentUser,
          let currentUserName = currentUser.userName,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let user = self.user,
          let contributionUserId = user.uid,
          let commentMode = self.commentMode else { return }
    
    let database = Firestore.firestore()
    
    do {
      var noti = ""
      var contributionKind = ""
      var notiId = ""
      var userId = ""
      if let parentComment = self.parentComment {
        guard currentUserId != parentComment.userId else { return }
        
        if commentMode == .story {
          guard let story = self.story,
                let storyId = story.id else { return }
          
          noti = "\(currentUserName)さんが「\(parentComment.comment)」コメントにコメントしました。\n\"\(comment)\""
          contributionKind = KEY_CONTRIBUTION_KIND_STORY_COMMENT
          notiId = storyId
          userId = parentComment.userId
        } else if commentMode == .qna {
          guard let qna = self.qna,
                let qnaId = qna.id else { return }
          
          noti = "\(currentUserName)さんが「\(parentComment.comment)」コメントにコメントしました。\n\"\(comment)\""
          contributionKind = KEY_CONTRIBUTION_KIND_QNA_COMMENT
          notiId = qnaId
          userId = parentComment.userId
        }
      } else {
        guard currentUserId != contributionUserId else { return }
        
        if commentMode == .story {
          guard let story = self.story,
                let storyId = story.id else { return }
          
          noti = "\(currentUserName)さんが「\(story.story)」ストーリーにコメントしました。\n\"\(comment)\""
          contributionKind = KEY_CONTRIBUTION_KIND_STROY
          notiId = storyId
          userId = contributionUserId
        } else if commentMode == .qna {
          guard let qna = self.qna,
                let qnaId = qna.id else { return }
          
          noti = "\(currentUserName)さんが「\(qna.qna)」質問にコメントしました。\n\"\(comment)\""
          contributionKind = KEY_CONTRIBUTION_KIND_QNA
          notiId = qnaId
          userId = contributionUserId
        }
      }
      
      let date = ANIFunction.shared.getToday()
      let notification = FirebaseNotification(userId: currentUserId, userName: currentUserName, noti: noti, contributionKind: contributionKind, notiKind: KEY_NOTI_KIND_COMMENT, notiId: notiId, commentId: commentId, updateDate: date)
      let id = NSUUID().uuidString
      let data = try FirestoreEncoder().encode(notification)
      
      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(userId).collection(KEY_NOTIFICATIONS).document(id).setData(data)
        database.collection(KEY_USERS).document(userId).updateData([KEY_IS_HAVE_UNREAD_NOTI: true])
      }
    } catch let error {
      DLog(error)
    }
  }
  
  func showParentCommentUser(comment: FirebaseComment, parentCommentUser: FirebaseUser, isAnimated: Bool) {
    guard let parentCommentUserViewTopConstraint = self.parentCommentUserViewTopConstraint,
          let parentCommentUserView = self.parentCommentUserView,
          let commentTextView = self.commentTextView,
          let parentUserNameLabel = self.parentUserNameLabel else { return }
    
    parentComment = comment
    
    if let parentCommentUserName = parentCommentUser.userName {
      parentUserNameLabel.text = parentCommentUserName + "さんにコメント"
    }
    
    commentTextView.becomeFirstResponder()
    
    parentCommentUserViewTopConstraint.constant = -40.0
    
    if isAnimated {
      UIView.animate(withDuration: 0.2) {
        parentCommentUserView.alpha = 1.0
      }
    } else {
      parentCommentUserView.alpha = 1.0
    }
  }
  
  private func hideParentCommentUser() {
    guard let parentCommentUserViewTopConstraint = self.parentCommentUserViewTopConstraint,
          let parentCommentUserView = self.parentCommentUserView,
          let parentUserNameLabel = self.parentUserNameLabel else { return }
    
    parentComment = nil
    
    parentUserNameLabel.text = ""
    
    UIView.animate(withDuration: 0.1, animations: {
      parentCommentUserView.alpha = 0.0
    }) { (complete) in
      parentCommentUserViewTopConstraint.constant = 0.0
    }
  }
  
  //MARK: action
  @objc private func contribute() {
    guard let commentTextView = self.commentTextView,
          let text = commentTextView.text,
          let currentuser = ANISessionManager.shared.currentUser,
          let uid = currentuser.uid,
          let commentMode = self.commentMode else { return }
    
    let database = Firestore.firestore()
    
    let id = NSUUID().uuidString
    let date = ANIFunction.shared.getToday()
    let comment = FirebaseComment(id: id, userId: uid, comment: text, date: date, isLoved: nil, parentCommentId: parentComment?.id ?? nil, parentCommentUserId: parentComment?.userId ?? nil)
    
    do {
      if let data = try FirebaseEncoder().encode(comment) as? [String : AnyObject] {
        switch commentMode {
        case .story:
          guard let story = self.story,
                let storyId = story.id else { return }
          
          DispatchQueue.global().async {
            database.collection(KEY_STORIES).document(storyId).collection(KEY_COMMENTS).document(id).setData(data)

            self.updateNoti(commentId: id, comment: comment.comment)
          }
        case .qna:
          guard let qna = self.qna,
                let qnaId = qna.id else { return }
          
          DispatchQueue.global().async {
            database.collection(KEY_QNAS).document(qnaId).collection(KEY_COMMENTS).document(id).setData(data)

            self.updateNoti(commentId: id, comment: comment.comment)
          }
        }
        
        ANIFunction.shared.showReviewAlertComment()
      }
    } catch let error {
      DLog(error)
    }
    
    commentTextView.text = ""
    commentTextView.endEditing(true)
    updateCommentContributionButton(text: commentTextView.text)
    hideParentCommentUser()
    parentComment = nil
  }
  
  @objc private func cancelComment() {
    hideParentCommentUser()
  }
}

//MARK: GrowingTextViewDelegate
extension ANICommentBar: GrowingTextViewDelegate {
  func textViewDidChange(_ textView: UITextView) {
    updateCommentContributionButton(text: textView.text)
  }
}
