//
//  ANIMessageViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/15.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIMessageViewCellDelegate {
  func loadedUser()
}

class ANIMessageViewCell: UITableViewCell {
  
  private weak var base: UIView?

  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 50.0
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  private weak var updateDateLabel: UILabel?
  private weak var messageLabel: UILabel?
  
  var chatGroup: FirebaseChatGroup? {
    didSet {
      guard let base = self.base else { return }
      
      base.backgroundColor = .white

      loadUser()
    }
  }
  
  private var user: FirebaseUser? {
    didSet {
      self.delegate?.loadedUser()
      reloadUserLayout()
      reloadLayout()
    }
  }
  
  var delegate: ANIMessageViewCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.selectionStyle = .none
    backgroundColor = .white
    self.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
    self.addGestureRecognizer(tapGesture)
    
    //base
    let base = UIView()
    base.backgroundColor = .white
    addSubview(base)
    base.edgesToSuperview()
    self.base = base
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    profileImageView.isUserInteractionEnabled = true
    let profileImageTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped))
    profileImageView.addGestureRecognizer(profileImageTapGesture)
    base.addSubview(profileImageView)
    profileImageView.topToSuperview(offset: 10.0)
    profileImageView.leftToSuperview(offset: 10.0)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    self.profileImageView = profileImageView
    
    //userNameLabel
    let userNameLabel = UILabel()
    userNameLabel.textColor = ANIColor.dark
    userNameLabel.font = UIFont.systemFont(ofSize: 16.0)
    base.addSubview(userNameLabel)
    userNameLabel.topToSuperview(offset: 13.0)
    userNameLabel.leftToRight(of: profileImageView, offset: 10.0)
    userNameLabel.height(18.0)
    self.userNameLabel = userNameLabel
    
    //updateDateLabel
    let updateDateLabel = UILabel()
    updateDateLabel.textColor = ANIColor.darkGray
    updateDateLabel.font = UIFont.systemFont(ofSize: 11.0)
    base.addSubview(updateDateLabel)
    updateDateLabel.centerY(to: userNameLabel)
    updateDateLabel.leftToRight(of: userNameLabel, offset: 10.0)
    updateDateLabel.rightToSuperview()
    updateDateLabel.width(70.0)
    self.updateDateLabel = updateDateLabel
    
    //messageLabel
    let messageLabel = UILabel()
    messageLabel.numberOfLines = 1
    messageLabel.font = UIFont.systemFont(ofSize: 14.0)
    messageLabel.textColor = ANIColor.subTitle
    base.addSubview(messageLabel)
    messageLabel.topToBottom(of: userNameLabel, offset: 10.0)
    messageLabel.left(to: userNameLabel)
    messageLabel.rightToSuperview(offset: -10.0)
    self.messageLabel = messageLabel
    
    //bottomSpace
    let spaceView = UIView()
    spaceView.backgroundColor = ANIColor.bg
    base.addSubview(spaceView)
    spaceView.topToBottom(of: profileImageView, offset: 10)
    spaceView.leftToSuperview()
    spaceView.rightToSuperview()
    spaceView.height(10.0)
    spaceView.bottomToSuperview()
  }
  
  private func reloadLayout() {
    guard let updateDateLabel = self.updateDateLabel,
          let messageLabel = self.messageLabel,
          let chatGroup = self.chatGroup,
          let base = self.base,
          let currentUserId = ANISessionManager.shared.currentUserUid else { return }
    
    let currentDate = ANIFunction.shared.getCurrentLocaleDateFromString(string: chatGroup.updateDate, format: "yyyy/MM/dd")
    updateDateLabel.text = currentDate
    messageLabel.text = chatGroup.lastMessage
    
    if let isHaveUnreadMessage = chatGroup.isHaveUnreadMessage, let currentUserIsHaveUnreadMessage = isHaveUnreadMessage[currentUserId] {
      if currentUserIsHaveUnreadMessage {
        base.backgroundColor = ANIColor.emerald.withAlphaComponent(0.1)
      } else {
        base.backgroundColor = .white
      }
    }
  }
  
  private func reloadUserLayout() {
    guard let profileImageView = self.profileImageView,
          let userNameLabel = self.userNameLabel else { return }
    
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
  
  @objc private func cellTapped() {
    guard let user = self.user else { return }
    
    ANINotificationManager.postMessageCellTapped(user: user)
  }
  
  @objc private func profileImageViewTapped() {
    guard let user = self.user,
          let userId = user.uid else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: userId)
  }
}

//MARK: data
extension ANIMessageViewCell {
  private func loadUser() {
    guard let chatGroup = self.chatGroup,
          let currentUserUid = ANISessionManager.shared.currentUserUid,
          let memberIds = chatGroup.memberIds else { return }
    
    for memberId in memberIds.keys {
      if currentUserUid != memberId {
        let database = Firestore.firestore()
        DispatchQueue.global().async {          
          database.collection(KEY_USERS).document(memberId).getDocument(completion: { (snapshot, error) in
            if let error = error {
              DLog("Error get document: \(error)")
              
              return
            }
            
            guard let snapshot = snapshot, let data = snapshot.data() else { return }
            
            do {
              let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
              
              self.user = user
            } catch let error {
              DLog(error)
            }
          })
        }
      }
    }
  }
}
