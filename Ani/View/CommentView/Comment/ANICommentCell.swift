//
//  ANICommentCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/21.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANICommentCellDelegate {
  func reject()
  func popupOptionView(isMe: Bool, contentId: String, commentId: String)
  func loadedCommentIsLoved(indexPath: Int, isLoved: Bool)
  func loadedCommentUser(user: FirebaseUser)
  func commentCellTapped(comment: FirebaseComment, user: FirebaseUser, indexPath: Int)
}

class ANICommentCell: UITableViewCell {
  
  private weak var commentLabel: UILabel?

  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 25.0
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  
  private weak var loveButtonBG: UIView?
  private weak var loveButton: ANICellButtonView?
  private weak var loveCountLabel: UILabel?
  private weak var commentButton: UIButton?
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
  
  var user: FirebaseUser? {
    didSet {
      DispatchQueue.main.async {
        self.reloadUserLayout()
      }
    }
  }
  
  var commentMode: CommentMode?
  var contentId: String?
  
  var indexPath: Int?
  
  private var loveListener: ListenerRegistration?
  
  var delegate: ANICommentCellDelegate?
  
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
    
    //commentLabel
    let commentLabel = UILabel()
    commentLabel.textColor = ANIColor.dark
    commentLabel.font = UIFont.systemFont(ofSize: 15.0)
    commentLabel.numberOfLines = 0
    addSubview(commentLabel)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    commentLabel.edgesToSuperview(excluding: .bottom, insets: insets)
    self.commentLabel = commentLabel
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    profileImageView.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped))
    profileImageView.addGestureRecognizer(tapGesture)
    addSubview(profileImageView)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.topToBottom(of: commentLabel, offset: 10.0)
    profileImageView.leftToSuperview(offset: 10.0)
    self.profileImageView = profileImageView
    
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
          let loveButton = self.loveButton else { return }
    
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
}

//MARK: ANIButtonViewDelegate
extension ANICommentCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.loveButton {
      love()
    }
  }
}

//MARK: data
extension ANICommentCell {
  private func loadUser() {
    guard let comment = self.comment else { return }
    
    DispatchQueue.global().async {
      let database = Firestore.firestore()
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
}
