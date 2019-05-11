//
//  ANIUserSearchViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANIUserSearchViewCellDelegate {
  func reject()
}

class ANIUserSearchViewCell: UITableViewCell {
  
  private weak var stackView: UIStackView?
  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 50.0
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  private weak var followButton: ANIAreaButtonView?
  private weak var followLabel: UILabel?
  
  var user: FirebaseUser? {
    didSet {
      reloadLayout()
      checkFollowed()
      reloadFollowButtonLayout()
    }
  }
  
  var delegate: ANIUserSearchViewCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.selectionStyle = .none
    self.isUserInteractionEnabled = true
    self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
    
    //stackView
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.spacing = 10.0
    addSubview(stackView)
    let insets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    stackView.edgesToSuperview(insets: insets)
    self.stackView = stackView
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    profileImageView.backgroundColor = ANIColor.gray
    stackView.addArrangedSubview(profileImageView)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    self.profileImageView = profileImageView
    
    //userNameLabel
    let userNameLabel = UILabel()
    userNameLabel.textColor = ANIColor.dark
    stackView.addArrangedSubview(userNameLabel)
    userNameLabel.centerY(to: profileImageView)
    self.userNameLabel = userNameLabel
    
    //followButton
    let followButton = ANIAreaButtonView()
    followButton.baseCornerRadius = 10.0
    followButton.base?.backgroundColor = ANIColor.emerald
    followButton.base?.layer.borderWidth = 1.8
    followButton.base?.layer.borderColor = ANIColor.emerald.cgColor
    followButton.alpha = 0.0
    followButton.delegate = self
    stackView.addArrangedSubview(followButton)
    followButton.centerY(to: profileImageView)
    followButton.width(85.0)
    followButton.height(30.0)
    self.followButton = followButton
    
    //followLabel
    let followLabel = UILabel()
    followLabel.font = UIFont.boldSystemFont(ofSize: 14)
    followLabel.textColor = .white
    followLabel.text = "フォロー"
    followLabel.textAlignment = .center
    followButton.addContent(followLabel)
    followLabel.edgesToSuperview()
    self.followLabel = followLabel
  }
  
  private func reloadLayout() {
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
  
  private func reloadFollowButtonLayout() {
    guard let user = self.user,
          let currentUserUid = ANISessionManager.shared.currentUserUid,
          let followButton = self.followButton else { return }
    
    if user.uid == currentUserUid {
      followButton.isHidden = true
    } else {
      followButton.isHidden = false
    }
  }
  
  private func checkFollowed() {
    guard let user = self.user,
          let userId = user.uid,
          let followButton = self.followButton,
          let followLabel = self.followLabel else { return }
    
    if let currentUserId = ANISessionManager.shared.currentUserUid {
      let database = Firestore.firestore()
      
      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_FOLLOWING_USER_IDS).getDocuments(completion: { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            
            return
          }
          
          guard let snapshot = snapshot else { return }
          
          for document in snapshot.documents {
            if document.documentID == userId {
              followButton.base?.backgroundColor = .clear
              followLabel.text = "フォロー中"
              followLabel.textColor = ANIColor.emerald
              
              break
            } else {
              followButton.base?.backgroundColor = ANIColor.emerald
              followLabel.text = "フォロー"
              followLabel.textColor = .white
            }
          }
          
          if snapshot.documents.isEmpty {
            followButton.base?.backgroundColor = ANIColor.emerald
            followLabel.text = "フォロー"
            followLabel.textColor = .white
          }
          
          DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1, animations: {
              followButton.alpha = 1.0
            })
          }
        })
      }
    } else {
      followButton.base?.backgroundColor = ANIColor.emerald
      followLabel.text = "フォロー"
      followLabel.textColor = .white
      
      UIView.animate(withDuration: 0.1, animations: {
        followButton.alpha = 1.0
      })
    }
  }
  
  private func updateNoti() {
    guard let currentUser = ANISessionManager.shared.currentUser,
          let currentUserName = currentUser.userName,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let user = self.user,
          let userId = user.uid,
          currentUserId != userId else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      do {
        let noti = "\(currentUserName)さんがあなたをフォローしました。"
        let date = ANIFunction.shared.getToday()
        let notification = FirebaseNotification(userId: currentUserId, userName: currentUserName, noti: noti, contributionKind: KEY_CONTRIBUTION_KIND_USER, notiKind: KEY_NOTI_KIND_FOLLOW, notiId: currentUserId, commentId: nil, updateDate: date)
        let data = try FirestoreEncoder().encode(notification)
        
        database.collection(KEY_USERS).document(userId).collection(KEY_NOTIFICATIONS).document(currentUserId).setData(data)
        database.collection(KEY_USERS).document(userId).updateData([KEY_IS_HAVE_UNREAD_NOTI: true])
      } catch let error {
        DLog(error)
      }
    }
  }
  
  //MARK: action
  @objc private func profileImageViewTapped() {
    guard let user = self.user,
          let userId = user.uid else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: userId)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIUserSearchViewCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === followButton {
      guard let user = self.user,
            let userId = user.uid,
            let followButton = self.followButton,
            let followLabel = self.followLabel else { return }
      
      if let currentUserUid = ANISessionManager.shared.currentUserUid, !ANISessionManager.shared.isAnonymous {
        let database = Firestore.firestore()
        
        if followButton.base?.backgroundColor == ANIColor.emerald {
          DispatchQueue.global().async {
            let date = ANIFunction.shared.getToday()
            database.collection(KEY_USERS).document(currentUserUid).collection(KEY_FOLLOWING_USER_IDS).document(userId).setData([KEY_DATE: date])
            database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWER_IDS).document(currentUserUid).setData([KEY_DATE: date])
            
            self.updateNoti()
            ANIFunction.shared.showReviewAlertFollow()
          }
          
          followButton.base?.backgroundColor = .clear
          followLabel.text = "フォロー中"
          followLabel.textColor = ANIColor.emerald
        } else {
          DispatchQueue.global().async {
            database.collection(KEY_USERS).document(currentUserUid).collection(KEY_FOLLOWING_USER_IDS).document(userId).delete()
            database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWER_IDS).document(currentUserUid).delete()
          }
          
          followButton.base?.backgroundColor = ANIColor.emerald
          followLabel.text = "フォロー"
          followLabel.textColor = .white
        }
      } else {
        self.delegate?.reject()
      }
    }
  }
}
