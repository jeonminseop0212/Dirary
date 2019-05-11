//
//  ANIParentCommentCell.swift
//  Ani
//
//  Created by jeonminseop on 2019/01/09.
//  Copyright © 2019年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIParentCommentCellDelegate {
  func reject()
  func popupOptionView(isMe: Bool, contentId: String, commentId: String)
  func loadedCommentIsLoved(indexPath: Int, isLoved: Bool)
  func loadedCommentUser(user: FirebaseUser)
  func commentCellTapped(comment: FirebaseComment, user: FirebaseUser, indexPath: Int)
}

class ANIParentCommentCell: UITableViewCell {
  
  private weak var parentCommentView: UIView?
  private weak var parentCommentBG: UIView?
  private weak var parentCommentLabel: UILabel?
  private let PARENT_COMMENT_PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 20.0
  private weak var parentCommentProfileImageView: UIImageView?
  private weak var parentCommentUserNameLabel: UILabel?
  private weak var parentCommentLine: UIView?
  private weak var deleteParentCommentView: UIView?
  private weak var deleteLabel: UILabel?
  
  private weak var commentLabel: UILabel?
  
  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 25.0
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  
  private weak var loveButtonBG: UIView?
  private weak var loveButton: ANICellButtonView?
  private weak var loveCountLabel: UILabel?
  private weak var commentButton: UIButton?
  private weak var commentCountLabel: UILabel?
  private weak var optionButton: UIButton?
  
  private weak var line: UIImageView?
  
  var comment: FirebaseComment? {
    didSet {
      if user == nil {
        loadUser()
      }
      
      reloadLayout()
      observeLove()
    }
  }
  
  var parentComment: FirebaseComment? {
    didSet {
      reloadParentCommentLayout()
      
      if parentCommentUser == nil {
        loadParentCommentUser()
      }
    }
  }
  
  var user: FirebaseUser? {
    didSet {
      DispatchQueue.main.async {
        self.reloadUserLayout()
      }
    }
  }
  
  var parentCommentUser: FirebaseUser? {
    didSet {
      DispatchQueue.main.async {
        self.reloadParentCommentUserLayout()
      }
    }
  }
  
  var commentMode: CommentMode?
  var contentId: String?
  
  var indexPath: Int?
  
  private var loveListener: ListenerRegistration?
  
  var delegate: ANIParentCommentCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //basic
    self.selectionStyle = .none
    self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(commentCellTapped)))
    
    //parentCommentView
    let parentCommentView = UIView()
    parentCommentView.isUserInteractionEnabled = true
    parentCommentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(parentCommentViewTapped)))
    addSubview(parentCommentView)
    parentCommentView.edgesToSuperview(excluding: .bottom)
    self.parentCommentView = parentCommentView
    
    //parentCommentLabel
    let parentCommentLabel = UILabel()
    parentCommentLabel.textColor = ANIColor.dark
    parentCommentLabel.font = UIFont.systemFont(ofSize: 14.0)
    parentCommentLabel.numberOfLines = 0
    parentCommentView.addSubview(parentCommentLabel)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    parentCommentLabel.edgesToSuperview(excluding: .bottom, insets: insets)
    self.parentCommentLabel = parentCommentLabel
    
    //parentCommentProfileImageView
    let parentCommentProfileImageView = UIImageView()
    parentCommentProfileImageView.backgroundColor = ANIColor.gray
    parentCommentProfileImageView.layer.cornerRadius = PARENT_COMMENT_PROFILE_IMAGE_VIEW_HEIGHT / 2
    parentCommentProfileImageView.layer.masksToBounds = true
    parentCommentProfileImageView.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(parentCommentProfileImageViewTapped))
    parentCommentProfileImageView.addGestureRecognizer(tapGesture)
    parentCommentView.addSubview(parentCommentProfileImageView)
    parentCommentProfileImageView.width(PARENT_COMMENT_PROFILE_IMAGE_VIEW_HEIGHT)
    parentCommentProfileImageView.height(PARENT_COMMENT_PROFILE_IMAGE_VIEW_HEIGHT)
    parentCommentProfileImageView.topToBottom(of: parentCommentLabel, offset: 10.0)
    parentCommentProfileImageView.leftToSuperview(offset: 10.0)
    parentCommentProfileImageView.bottomToSuperview(offset: -10.0)
    self.parentCommentProfileImageView = parentCommentProfileImageView
    
    //parentCommentUserNameLabel
    let parentCommentUserNameLabel = UILabel()
    parentCommentUserNameLabel.text = "aoaoaoao"
    parentCommentUserNameLabel.textColor = ANIColor.dark
    parentCommentUserNameLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    parentCommentUserNameLabel.numberOfLines = 2
    parentCommentView.addSubview(parentCommentUserNameLabel)
    parentCommentUserNameLabel.leftToRight(of: parentCommentProfileImageView, offset: 10.0)
    parentCommentUserNameLabel.rightToSuperview(offset: -10.0)
    parentCommentUserNameLabel.centerY(to: parentCommentProfileImageView)
    self.parentCommentUserNameLabel = parentCommentUserNameLabel
    
    //deleteParentCommentVIew
    let deleteParentCommentView = UIView()
    deleteParentCommentView.backgroundColor = .white
    deleteParentCommentView.isHidden = true
    parentCommentView.addSubview(deleteParentCommentView)
    deleteParentCommentView.edgesToSuperview()
    self.deleteParentCommentView = deleteParentCommentView
    
    //deleteLabel
    let deleteLabel = UILabel()
    deleteLabel.textColor = ANIColor.dark
    deleteLabel.font = UIFont.systemFont(ofSize: 14.0)
    deleteLabel.text = "削除されたコメントです。"
    deleteParentCommentView.addSubview(deleteLabel)
    deleteLabel.leftToSuperview(offset: 10.0)
    deleteLabel.centerYToSuperview()
    self.deleteLabel = deleteLabel
    
    //parentCommentLine
    let parentCommentLine = UIView()
    parentCommentLine.backgroundColor = ANIColor.bg
    addSubview(parentCommentLine)
    parentCommentLine.width(2.0)
    parentCommentLine.topToBottom(of: parentCommentProfileImageView, offset: 5.0)
    parentCommentLine.centerX(to: parentCommentProfileImageView)
    self.parentCommentLine = parentCommentLine
    
    //commentLabel
    let commentLabel = UILabel()
    commentLabel.textColor = ANIColor.dark
    commentLabel.font = UIFont.systemFont(ofSize: 15.0)
    commentLabel.numberOfLines = 0
    addSubview(commentLabel)
    commentLabel.topToBottom(of: parentCommentView)
    commentLabel.leftToRight(of: parentCommentLine, offset: 10.0)
    commentLabel.rightToSuperview(offset: -10.0)
    self.commentLabel = commentLabel
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    profileImageView.isUserInteractionEnabled = true
    profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
    addSubview(profileImageView)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.topToBottom(of: commentLabel, offset: 10.0)
    profileImageView.leftToRight(of: parentCommentLine, offset: 10.0)
    self.profileImageView = profileImageView
    
    //parentCommentLineBottom
    parentCommentLine.bottom(to: profileImageView)
    
    //optionButton
    let optionButton = UIButton()
    optionButton.setImage(UIImage(named: "commentOptionButton"), for: .normal)
    optionButton.addTarget(self, action: #selector(showOption), for: .touchUpInside)
    addSubview(optionButton)
    optionButton.centerY(to: profileImageView)
    optionButton.rightToSuperview(offset: -10.0)
    optionButton.width(20.0)
    optionButton.height(20.0)
    self.optionButton = optionButton
    
    //commentButton
    let commentButton = UIButton()
    commentButton.setImage(UIImage(named: "commentCommentButton"), for: .normal)
    commentButton.addTarget(self, action: #selector(commentCellTapped), for: .touchUpInside)
    addSubview(commentButton)
    commentButton.centerY(to: profileImageView)
    commentButton.rightToLeft(of: optionButton, offset: -10.0)
    commentButton.width(20.0)
    commentButton.height(20.0)
    self.commentButton = commentButton
    
    //loveCountLabel
    let loveCountLabel = UILabel()
    loveCountLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    loveCountLabel.textColor = ANIColor.dark
    addSubview(loveCountLabel)
    loveCountLabel.centerY(to: profileImageView)
    loveCountLabel.rightToLeft(of: commentButton, offset: -5.0)
    loveCountLabel.width(20.0)
    loveCountLabel.height(20.0)
    self.loveCountLabel = loveCountLabel
    
    //loveButtonBG
    let loveButtonBG = UIView()
    loveButtonBG.isUserInteractionEnabled = false
    loveButtonBG.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loveButtonBGTapped)))
    addSubview(loveButtonBG)
    loveButtonBG.centerY(to: profileImageView)
    loveButtonBG.rightToLeft(of: loveCountLabel, offset: -5.0)
    loveButtonBG.width(20.0)
    loveButtonBG.height(20.0)
    self.loveButtonBG = loveButtonBG
    
    //loveButton
    let loveButton = ANICellButtonView()
    loveButton.image = UIImage(named: "commentLoveButton")
    loveButton.unSelectedImage = UIImage(named: "commentLoveButton")
    loveButton.selectedImage = UIImage(named: "commentLoveButtonSelected")
    loveButton.delegate = self
    addSubview(loveButton)
    loveButton.centerY(to: profileImageView)
    loveButton.rightToLeft(of: loveCountLabel, offset: -5.0)
    loveButton.width(20.0)
    loveButton.height(20.0)
    self.loveButton = loveButton
    
    //userNameLabel
    let userNameLabel = UILabel()
    userNameLabel.textColor = ANIColor.dark
    userNameLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    userNameLabel.numberOfLines = 2
    addSubview(userNameLabel)
    userNameLabel.leftToRight(of: profileImageView, offset: 10.0)
    userNameLabel.rightToLeft(of: loveButton, offset: -10.0)
    userNameLabel.centerY(to: profileImageView)
    self.userNameLabel = userNameLabel
    
    //line
    let line = UIImageView()
    line.image = UIImage(named: "line")
    addSubview(line)
    line.height(0.5)
    line.topToBottom(of: profileImageView, offset: 10.0)
    line.edgesToSuperview(excluding: .top)
    self.line = line
  }
  
  private func reloadLayout() {
    guard let commentLabel = self.commentLabel,
          let comment = self.comment,
          let loveButtonBG = self.loveButtonBG,
          let loveButton = self.loveButton,
          let parentCommentUserNameLabel = self.parentCommentUserNameLabel,
          let parentCommentProfileImageView = self.parentCommentProfileImageView else { return }
    
    commentLabel.text = comment.comment
    
    if ANISessionManager.shared.isAnonymous {
      loveButtonBG.isUserInteractionEnabled = true
      loveButton.isUserInteractionEnabled = false
    } else {
      loveButtonBG.isUserInteractionEnabled = false
      loveButton.isUserInteractionEnabled = true
    }
    
    loveButton.isSelected = false
    if let isLoved = comment.isLoved {
      if isLoved {
        loveButton.isSelected = true
      } else {
        loveButton.isSelected = false
      }
    }
    
    parentCommentProfileImageView.image = UIImage()
    parentCommentUserNameLabel.text = ""
  }
  
  private func reloadParentCommentLayout() {
    guard let parentCommentLabel = self.parentCommentLabel,
          let deleteParentCommentView = self.deleteParentCommentView else { return }
    
    if let parentComment = self.parentComment {
      parentCommentLabel.text = parentComment.comment
      deleteParentCommentView.isHidden = true
    } else {
      deleteParentCommentView.isHidden = false
    }
  }
  
  private func reloadUserLayout() {
    guard let userNameLabel = self.userNameLabel,
          let profileImageView = self.profileImageView else { return }
    
    if let user = self.user, let profileImageUrl = user.profileImageUrl {
      profileImageView.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
    } else {
      profileImageView.image = UIImage()
    }
    
    if let user = self.user, let userName = user.userName {
      userNameLabel.text = userName
    } else {
      userNameLabel.text = ""
    }
  }
  
  private func reloadParentCommentUserLayout() {
    guard let parentCommentUser = self.parentCommentUser,
          let parentCommentProfileImageView = self.parentCommentProfileImageView,
          let parentCommentUserNameLabel = self.parentCommentUserNameLabel else { return }
    
    if let parentCommentUser = self.parentCommentUser, let profileImageUrl = parentCommentUser.profileImageUrl {
      parentCommentProfileImageView.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
    } else {
      parentCommentProfileImageView.image = UIImage()
    }
    parentCommentUserNameLabel.text = parentCommentUser.userName
  }
  
  @objc private func showOption() {
    guard let comment = self.comment,
          let contentId = self.contentId else { return }
    
    if let currentUserId = ANISessionManager.shared.currentUserUid, comment.userId == currentUserId {
      self.delegate?.popupOptionView(isMe: true, contentId: contentId, commentId: comment.id)
    } else {
      self.delegate?.popupOptionView(isMe: false, contentId: contentId, commentId: comment.id)
    }
  }
  
  private func observeLove() {
    guard let commentMode = self.commentMode,
          let contentId = self.contentId,
          let comment = self.comment,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath,
          let loveCountLabel = self.loveCountLabel else { return }
    
    loveCountLabel.text = "0"
    
    var collection = ""
    if commentMode == .story {
      collection = KEY_STORIES
    } else if commentMode == .qna {
      collection = KEY_QNAS
    }
    
    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.loveListener = database.collection(collection).document(contentId).collection(KEY_COMMENTS).document(comment.id).collection(KEY_LOVE_IDS).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        if let snapshot = snapshot {
          loveCountLabel.text = "\(snapshot.documents.count)"
          
          DispatchQueue.main.async {
            if let currentUserUid = ANISessionManager.shared.currentUserUid {
              var documentIDTemp = [String]()
              for document in snapshot.documents {
                documentIDTemp.append(document.documentID)
              }
              
              if documentIDTemp.contains(currentUserUid) {
                loveButton.isSelected = true
                self.delegate?.loadedCommentIsLoved(indexPath: indexPath, isLoved: true)
              } else {
                loveButton.isSelected = false
                self.delegate?.loadedCommentIsLoved(indexPath: indexPath, isLoved: false)
              }
            } else {
              loveButton.isSelected = false
            }
          }
        } else {
          loveCountLabel.text = "0"
          loveButton.isSelected = false
        }
      })
    }
  }
  
  func unobserveLove() {
    guard let loveListener = self.loveListener else { return }
    
    loveListener.remove()
  }
  
  private func updateNoti() {
    guard let commentMode = self.commentMode,
          let contentId = self.contentId,
          let comment = self.comment,
          let currentUser = ANISessionManager.shared.currentUser,
          let currentUserName = currentUser.userName,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let user = self.user,
          let userId = user.uid,
          currentUserId != userId else { return }
    
    let database = Firestore.firestore()
    
    var collection = ""
    var contributionKind = ""
    if commentMode == .story {
      collection = KEY_STORIES
      contributionKind = KEY_CONTRIBUTION_KIND_STORY_COMMENT
    } else if commentMode == .qna {
      collection = KEY_QNAS
      contributionKind = KEY_CONTRIBUTION_KIND_QNA_COMMENT
    }
    
    DispatchQueue.global().async {
      database.collection(collection).document(contentId).collection(KEY_COMMENTS).document(comment.id).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        var noti = ""
        
        if let snapshot = snapshot, snapshot.documents.count > 1 {
          noti = "\(currentUserName)さん、他\(snapshot.documents.count - 1)人が「\(comment.comment)」コメントを「いいね」しました。"
        } else {
          noti = "\(currentUserName)さんが「\(comment.comment)」コメントを「いいね」しました。"
        }
        
        do {
          let date = ANIFunction.shared.getToday()
          let notification = FirebaseNotification(userId: currentUserId, userName: currentUserName, noti: noti, contributionKind: contributionKind, notiKind: KEY_NOTI_KIND_LOVE, notiId: contentId, commentId: comment.id, updateDate: date)
          let data = try FirestoreEncoder().encode(notification)
          
          database.collection(KEY_USERS).document(userId).collection(KEY_NOTIFICATIONS).document(comment.id).setData(data)
          database.collection(KEY_USERS).document(userId).updateData([KEY_IS_HAVE_UNREAD_NOTI: true])
        } catch let error {
          DLog(error)
        }
      })
    }
  }
  
  //MARK: action
  @objc private func profileImageViewTapped() {
    guard let comment = self.comment else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: comment.userId)
  }
  
  @objc private func parentCommentProfileImageViewTapped() {
    guard let comment = self.comment,
          let parentCommentUserId = comment.parentCommentUserId else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: parentCommentUserId)
  }
  
  @objc private func loveButtonBGTapped() {
    self.delegate?.reject()
  }
  
  @objc private func love() {
    guard let comment = self.comment,
          let contentId = self.contentId,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath else { return }
    
    let database = Firestore.firestore()
    
    var collection = ""
    if commentMode == .story {
      collection = KEY_STORIES
    } else if commentMode == .qna {
      collection = KEY_QNAS
    }
    
    if loveButton.isSelected == true {
      let date = ANIFunction.shared.getToday()
      
      DispatchQueue.global().async {
        database.collection(collection).document(contentId).collection(KEY_COMMENTS).document(comment.id).collection(KEY_LOVE_IDS).document(currentUserId).setData([currentUserId: true, KEY_DATE: date])
      }
      
      self.updateNoti()
      ANIFunction.shared.showReviewAlertLove()
      
      self.delegate?.loadedCommentIsLoved(indexPath: indexPath, isLoved: true)
    } else {
      DispatchQueue.global().async {
        database.collection(collection).document(contentId).collection(KEY_COMMENTS).document(comment.id).collection(KEY_LOVE_IDS).document(currentUserId).delete()
      }
      
      self.delegate?.loadedCommentIsLoved(indexPath: indexPath, isLoved: false)
    }
  }
  
  @objc private func commentCellTapped() {
    guard let comment = self.comment,
          let user = self.user,
          let indexPath = self.indexPath else { return }
    
    self.delegate?.commentCellTapped(comment: comment, user: user, indexPath: indexPath)
  }
  
  @objc private func parentCommentViewTapped() {
    guard let parentComment = self.parentComment,
          let parentCommentUser = self.parentCommentUser,
          let indexPath = self.indexPath else { return }
    
    self.delegate?.commentCellTapped(comment: parentComment, user: parentCommentUser, indexPath: indexPath)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIParentCommentCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.loveButton {
      love()
    }
  }
}

//MARK: data
extension ANIParentCommentCell {
  private func loadUser() {
    guard let comment = self.comment else { return }

    let database = Firestore.firestore()

    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(comment.userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          self.user = user
          self.delegate?.loadedCommentUser(user: user)
        } catch let error {
          DLog(error)
        }
      })
    }
  }
  
  private func loadParentCommentUser() {
    guard let parentComment = self.parentComment else { return }

    let database = Firestore.firestore()

    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(parentComment.userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")

          return
        }

        guard let snapshot = snapshot, let data = snapshot.data() else { return }

        do {
          let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          self.parentCommentUser = user
          self.delegate?.loadedCommentUser(user: user)
        } catch let error {
          DLog(error)
        }
      })
    }
  }
}

