//
//  ANIRecruitViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import StoreKit
import ActiveLabel
import TinyConstraints

protocol ANIStoryViewCellDelegate {
  func storyCellTapped(story: FirebaseStory, user: FirebaseUser)
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool)
  func loadedStoryUser(user: FirebaseUser)
}

class ANIStoryViewCell: UITableViewCell {
  private weak var stackView: UIStackView?
  private weak var tapArea: UIView?
  private weak var storyImagesView: ANIStoryImagesView?
  private weak var storyLabelBase: UIView?
  private weak var storyLabel: ActiveLabel?
  
  private weak var storyCommentView: ANIContributionCommentView?
  
  private var bottomAreaTopConstraint: Constraint?
  private weak var bottomArea: UIView?
  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 32.0
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  private weak var loveButtonBG: UIView?
  private weak var loveButton: ANICellButtonView?
  private weak var loveCountLabel: UILabel?
  private weak var commentButton: UIButton?
  private weak var commentCountLabel: UILabel?
  private weak var optionButton: UIButton?
  
  var story: FirebaseStory? {
    didSet {
      guard let storyCommentView = self.storyCommentView else  { return }
      
      if user == nil {
        loadUser()
      }
      
      reloadLayout()
      
      storyCommentView.story = story

      observeLove()
      observeComment()
    }
  }
  
  var user: FirebaseUser? {
    didSet {
      DispatchQueue.main.async {
        self.reloadUserLayout()
      }
    }
  }
  
  var commentUsers: [FirebaseUser?]? {
    didSet {
      guard let storyCommentView = self.storyCommentView,
            let commentUsers = self.commentUsers else  { return }

      if !commentUsers.isEmpty {
        storyCommentView.commentOneUser = commentUsers[0]
        
        if commentUsers.count > 1 {
          storyCommentView.commentTwoUser = commentUsers[1]
        }
      }
    }
  }
  
  private var loveCount: Int = 0 {
    didSet {
      guard let loveCountLabel = self.loveCountLabel else { return }
      
      DispatchQueue.main.async {
        loveCountLabel.text = "\(self.loveCount)"
      }
    }
  }
  
  private var commentCount: Int = 0 {
    didSet {
      guard let commentCountLabel = self.commentCountLabel else { return }
      
      DispatchQueue.main.async {
        commentCountLabel.text = "\(self.commentCount)"
      }
    }
  }
  
  private var loveListener: ListenerRegistration?
  private var commentListener: ListenerRegistration?
  
  var indexPath: Int?
  
  var delegate: ANIStoryViewCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    for touch: AnyObject in touches {
      if let myTouch: UITouch = touch as? UITouch, let touchView = myTouch.view, touchView != bottomArea {
        cellTapped()
      }
    }
  }
  
  private func setup() {
    self.selectionStyle = .none
    self.backgroundColor = .white
    
    //stackView
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.spacing = 0.0
    addSubview(stackView)
    stackView.edgesToSuperview(excluding: .bottom)
    self.stackView = stackView
    
    //tapArea
    let tapArea = UIView()
    tapArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTapped)))
    stackView.addArrangedSubview(tapArea)
    self.tapArea = tapArea
    
    //storyImagesView
    let storyImagesView = ANIStoryImagesView()
    tapArea.addSubview(storyImagesView)
    storyImagesView.edgesToSuperview()
    self.storyImagesView = storyImagesView
    
    //storyLabelBase
    let storyLabelBase = UIView()
    storyLabelBase.backgroundColor = .white
    stackView.addArrangedSubview(storyLabelBase)
    self.storyLabelBase = storyLabelBase

    //storyLabel
    let storyLabel = ActiveLabel()
    storyLabel.font = UIFont.systemFont(ofSize: 14.0)
    storyLabel.textAlignment = .left
    storyLabel.textColor = ANIColor.subTitle
    storyLabel.numberOfLines = 0
    storyLabel.enabledTypes = [.hashtag]
    storyLabel.customize { (label) in
      label.hashtagColor = ANIColor.darkblue
    }
    storyLabel.handleHashtagTap { (hashtag) in
      ANINotificationManager.postTapHashtag(contributionKind: KEY_CONTRIBUTION_KIND_STROY, hashtag: hashtag)
    }
    storyLabelBase.addSubview(storyLabel)
    storyLabel.topToSuperview(offset: 5.0)
    storyLabel.leftToSuperview(offset: 10.0)
    storyLabel.rightToSuperview(offset: -10.0, priority: .defaultHigh)
    storyLabel.bottomToSuperview()
    self.storyLabel = storyLabel
    
    //storyCommentView
    let storyCommentView = ANIContributionCommentView()
    storyCommentView.delegate = self
    stackView.addArrangedSubview(storyCommentView)
    self.storyCommentView = storyCommentView
    
    //bottomArea
    let bottomArea = UIView()
    addSubview(bottomArea)
    bottomAreaTopConstraint = bottomArea.topToBottom(of: stackView, offset: 10.0)
    bottomArea.edgesToSuperview(excluding: .top)
    self.bottomArea = bottomArea
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.isUserInteractionEnabled = true
    profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    addSubview(profileImageView)
    profileImageView.top(to: bottomArea)
    profileImageView.leftToSuperview(offset: 10.0)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    self.profileImageView = profileImageView
    
    //optionButton
    let optionButton = UIButton()
    optionButton.setImage(UIImage(named: "cellOptionButton"), for: .normal)
    optionButton.addTarget(self, action: #selector(showOption), for: .touchUpInside)
    addSubview(optionButton)
    optionButton.centerY(to: profileImageView)
    optionButton.rightToSuperview(offset: -10.0)
    optionButton.width(30.0)
    optionButton.height(30.0)
    self.optionButton = optionButton

    //commentCountLabel
    let commentCountLabel = UILabel()
    commentCountLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    commentCountLabel.textColor = ANIColor.dark
    addSubview(commentCountLabel)
    commentCountLabel.centerY(to: profileImageView)
    commentCountLabel.rightToLeft(of: optionButton, offset: -5.0)
    commentCountLabel.width(25.0)
    commentCountLabel.height(20.0)
    self.commentCountLabel = commentCountLabel

    //commentButton
    let commentButton = UIButton()
    commentButton.setImage(UIImage(named: "commentButton"), for: .normal)
    commentButton.addTarget(self, action: #selector(cellTapped), for: .touchUpInside)
    addSubview(commentButton)
    commentButton.centerY(to: profileImageView)
    commentButton.rightToLeft(of: commentCountLabel, offset: -5.0)
    commentButton.width(30.0)
    commentButton.height(30.0)
    self.commentButton = commentButton
    
    //loveCountLabel
    let loveCountLabel = UILabel()
    loveCountLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    loveCountLabel.textColor = ANIColor.dark
    addSubview(loveCountLabel)
    loveCountLabel.centerY(to: profileImageView)
    loveCountLabel.rightToLeft(of: commentButton, offset: -5.0)
    loveCountLabel.width(25.0)
    loveCountLabel.height(20.0)
    self.loveCountLabel = loveCountLabel
    
    //loveButtonBG
    let loveButtonBG = UIView()
    loveButtonBG.isUserInteractionEnabled = false
    loveButtonBG.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loveButtonBGTapped)))
    addSubview(loveButtonBG)
    loveButtonBG.centerY(to: profileImageView)
    loveButtonBG.rightToLeft(of: loveCountLabel, offset: -5.0)
    loveButtonBG.width(30.0)
    loveButtonBG.height(30.0)
    self.loveButtonBG = loveButtonBG
    
    //loveButton
    let loveButton = ANICellButtonView()
    loveButton.image = UIImage(named: "loveButton")
    loveButton.unSelectedImage = UIImage(named: "loveButton")
    loveButton.selectedImage = UIImage(named: "loveButtonSelected")
    loveButton.delegate = self
    addSubview(loveButton)
    loveButton.centerY(to: profileImageView)
    loveButton.rightToLeft(of: loveCountLabel, offset: -5.0)
    loveButton.width(30.0)
    loveButton.height(30.0)
    self.loveButton = loveButton

    //userNameLabel
    let userNameLabel = UILabel()
    userNameLabel.font = UIFont.systemFont(ofSize: 13.0)
    userNameLabel.textColor = ANIColor.subTitle
    userNameLabel.numberOfLines = 2
    userNameLabel.isUserInteractionEnabled = true
    userNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
    addSubview(userNameLabel)
    userNameLabel.leftToRight(of: profileImageView, offset: 10.0, priority: .defaultHigh)
    userNameLabel.rightToLeft(of: loveButton, offset: -10.0)
    userNameLabel.centerY(to: profileImageView)
    self.userNameLabel = userNameLabel
    
    //bottomSpace
    let spaceView = UIView()
    spaceView.backgroundColor = ANIColor.bg
    addSubview(spaceView)
    spaceView.topToBottom(of: profileImageView, offset: 10)
    spaceView.leftToSuperview()
    spaceView.rightToSuperview()
    spaceView.height(10.0)
    spaceView.bottomToSuperview(priority: .defaultHigh)
  }
  
  private func reloadLayout() {
    guard let storyImagesView = self.storyImagesView,
          let storyLabelBase = self.storyLabelBase,
          let storyLabel = self.storyLabel,
          let storyCommentView = self.storyCommentView,
          let bottomAreaTopConstraint = self.bottomAreaTopConstraint,
          let loveButtonBG = self.loveButtonBG,
          let loveButton = self.loveButton,
          let story = self.story else { return }
    
    if let storyImageUrls = story.storyImageUrls {
      storyImagesView.imageUrls = storyImageUrls
      storyImagesView.pageControl?.numberOfPages = storyImageUrls.count
    }
    storyLabel.text = story.story

    if story.story == "" {
      storyLabelBase.isHidden = true
    } else {
      storyLabelBase.isHidden = false
    }
    
    if story.comments != nil {
      storyCommentView.isHidden = false
    } else {
      storyCommentView.isHidden = true
    }
    
    if story.story == "" && story.comments == nil {
      bottomAreaTopConstraint.constant = 5.0
    } else {
      bottomAreaTopConstraint.constant = 10.0
    }
    
    if ANISessionManager.shared.isAnonymous {
      loveButtonBG.isUserInteractionEnabled = true
      loveButton.isUserInteractionEnabled = false
    } else {
      loveButtonBG.isUserInteractionEnabled = false
      loveButton.isUserInteractionEnabled = true
    }
    
    loveButton.isSelected = false
    if let isLoved = story.isLoved {
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
  
  private func observeLove() {
    guard let story = self.story,
          let storyId = story.id,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath else { return }
    
    self.loveCount = 0
    
    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.loveListener = database.collection(KEY_STORIES).document(storyId).collection(KEY_LOVE_IDS).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        if let snapshot = snapshot {
          self.loveCount = snapshot.documents.count
          
          DispatchQueue.main.async {
            if let currentUserUid = ANISessionManager.shared.currentUserUid {
              var documentIDTemp = [String]()
              for document in snapshot.documents {
                documentIDTemp.append(document.documentID)
              }
              
              if documentIDTemp.contains(currentUserUid) {
                loveButton.isSelected = true
                self.delegate?.loadedStoryIsLoved(indexPath: indexPath, isLoved: true)
              } else {
                loveButton.isSelected = false
                self.delegate?.loadedStoryIsLoved(indexPath: indexPath, isLoved: false)
              }
            } else {
              loveButton.isSelected = false
            }
          }
        } else {
          self.loveCount = 0
          loveButton.isSelected = false
        }
      })
    }
  }
  
  func unobserveLove() {
    guard let loveListener = self.loveListener else { return }
    
    loveListener.remove()
  }
  
  private func observeComment() {
    guard let story = self.story,
          let storyId = story.id else { return }
    
    self.commentCount = 0
    
    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.commentListener = database.collection(KEY_STORIES).document(storyId).collection(KEY_COMMENTS).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        if let snapshot = snapshot {
          self.commentCount = snapshot.documents.count
        } else {
          self.commentCount = 0
        }
      })
    }
  }
  
  func unobserveComment() {
    guard let commentListener = self.commentListener else { return }
    
    commentListener.remove()
  }
  
  private func updateNoti() {
    guard let story = self.story,
          let storyId = story.id,
          let currentUser = ANISessionManager.shared.currentUser,
          let currentUserName = currentUser.userName,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let user = self.user,
          let userId = user.uid,
          currentUserId != userId else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_STORIES).document(storyId).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        var noti = ""
        
        if let snapshot = snapshot, snapshot.documents.count > 1 {
          noti = "\(currentUserName)さん、他\(snapshot.documents.count - 1)人が「\(story.story)」ストーリーを「いいね」しました。"
        } else {
          noti = "\(currentUserName)さんが「\(story.story)」ストーリーを「いいね」しました。"
        }
        
        do {
          let date = ANIFunction.shared.getToday()
          let notification = FirebaseNotification(userId: currentUserId, userName: currentUserName, noti: noti, contributionKind: KEY_CONTRIBUTION_KIND_STROY, notiKind: KEY_NOTI_KIND_LOVE, notiId: storyId, commentId: nil, updateDate: date)
          let data = try FirestoreEncoder().encode(notification)
          
          database.collection(KEY_USERS).document(userId).collection(KEY_NOTIFICATIONS).document(storyId).setData(data)
          database.collection(KEY_USERS).document(userId).updateData([KEY_IS_HAVE_UNREAD_NOTI: true])
        } catch let error {
          DLog(error)
        }
      })
    }
  }
  
  //MARK: action
  @objc private func love() {
    guard let story = self.story,
          let storyId = story.id,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath else { return }
    
    let database = Firestore.firestore()
    
    if loveButton.isSelected == true {
      let date = ANIFunction.shared.getToday()
      
      DispatchQueue.global().async {
        database.collection(KEY_STORIES).document(storyId).collection(KEY_LOVE_IDS).document(currentUserId).setData([currentUserId: true, KEY_DATE: date])
      }
      
      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_STORY_IDS).document(storyId).setData([KEY_DATE: date])
      }
      
      DispatchQueue.global().async {
        database.collection(KEY_STORIES).document(storyId).updateData([KEY_LOVE_COUNT: self.loveCount + 1])
      }
        
      self.updateNoti()
      ANIFunction.shared.showReviewAlertLove()
      
      self.delegate?.loadedStoryIsLoved(indexPath: indexPath, isLoved: true)
    } else {
      DispatchQueue.global().async {
        database.collection(KEY_STORIES).document(storyId).collection(KEY_LOVE_IDS).document(currentUserId).delete()
      }
      
      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_STORY_IDS).document(storyId).delete()
      }
      
      DispatchQueue.global().async {
        database.collection(KEY_STORIES).document(storyId).updateData([KEY_LOVE_COUNT: self.loveCount - 1])
      }
      
      self.delegate?.loadedStoryIsLoved(indexPath: indexPath, isLoved: false)
    }
  }
  
  @objc private func loveButtonBGTapped() {
    self.delegate?.reject()
  }
  
  @objc private func profileImageViewTapped() {
    guard let story = self.story else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: story.userId)
  }
  
  @objc private func cellTapped() {
    guard let story = self.story,
          let user = self.user else { return }
    
    self.delegate?.storyCellTapped(story: story, user: user)
  }
  
  @objc private func showOption() {
    guard let user = self.user,
          let story = self.story,
          let storyId = story.id else { return }
    
    let contentType: ContentType = .story
    
    if let currentUserId = ANISessionManager.shared.currentUserUid, user.uid == currentUserId {
      self.delegate?.popupOptionView(isMe: true, contentType: contentType, id: storyId)
    } else {
      self.delegate?.popupOptionView(isMe: false, contentType: contentType, id: storyId)
    }
  }
}

//MARK: ANIButtonViewDelegate
extension ANIStoryViewCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.loveButton {
      love()
    }
  }
}

//MARK: ANIContributionCommentViewDelegate
extension ANIStoryViewCell: ANIContributionCommentViewDelegate {
  func loadedCommentUser(user: FirebaseUser) {
    self.delegate?.loadedStoryUser(user: user)
  }
}

//MARK: data
extension ANIStoryViewCell {
  private func loadUser() {
    guard let story = self.story else { return }
    
    DispatchQueue.global().async {
      let database = Firestore.firestore()
      database.collection(KEY_USERS).document(story.userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          self.user = user
          self.delegate?.loadedStoryUser(user: user)
        } catch let error {
          DLog(error)
        }
      })
    }
  }
}

