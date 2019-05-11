//
//  ANIOtherProfileCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import ActiveLabel

protocol ANIOtherProfileCellDelegate {
  func followingTapped()
  func followerTapped()
  func reject()
  func twitterOpenReject()
  func instagramOpenReject()
  func openUrl(url: URL)
}

class ANIOtherProfileCell: UITableViewCell {
  
  private weak var nameLabel: UILabel?
  private let FOLLOW_BUTTON_HEIGHT: CGFloat = 30.0
  private let FOLLOW_BUTTON_WIDTH: CGFloat = 100.0
  private weak var followButton: ANIAreaButtonView?
  private weak var followLabel: UILabel?
  private weak var followingBG: UIView?
  private weak var followingCountLabel: UILabel?
  private weak var followingLabel: UILabel?
  private weak var followerBG: UIView?
  private weak var followerCountLabel: UILabel?
  private weak var followerLabel: UILabel?
  private weak var groupLabel: UILabel?
  private weak var instroduceStackView: UIStackView?
  private weak var twitterBG: UIView?
  private weak var twitterImageView: UIImageView?
  private weak var twitterLabel: UILabel?
  private weak var instagramBG: UIView?
  private weak var instagramImageView: UIImageView?
  private weak var instagramLabel: UILabel?
  private weak var introduceBG: UIView?
  private weak var introductionLabel: ActiveLabel?
  
  var user: FirebaseUser? {
    didSet {
      reloadLayout()
      
      if let uid = user?.uid, userId == nil {
        userId = uid
      }
    }
  }
  
  private var userId: String? {
    didSet {
      observeUserFollow()
    }
  }
  
  var isFollowed: Bool = false {
    didSet {
      reloadFollowLayout()
    }
  }
  
  var delegate: ANIOtherProfileCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    backgroundColor = .clear
    self.selectionStyle = .none
    
    //followButton
    let followButton = ANIAreaButtonView()
    followButton.base?.backgroundColor = ANIColor.emerald
    followButton.baseCornerRadius = FOLLOW_BUTTON_HEIGHT / 2
    followButton.delegate = self
    followButton.base?.layer.borderWidth = 1.8
    followButton.base?.layer.borderColor = ANIColor.emerald.cgColor
    addSubview(followButton)
    followButton.topToSuperview(offset: 10.0)
    followButton.rightToSuperview(offset: -10.0)
    followButton.width(FOLLOW_BUTTON_WIDTH)
    followButton.height(FOLLOW_BUTTON_HEIGHT)
    self.followButton = followButton
    
    //followLabel
    let followLabel = UILabel()
    followLabel.textColor = .white
    followLabel.text = "フォロー"
    followLabel.textAlignment = .center
    followLabel.font = UIFont.boldSystemFont(ofSize: 15)
    followButton.addContent(followLabel)
    followLabel.edgesToSuperview()
    self.followLabel = followLabel
    
    //nameLabel
    let nameLabel = UILabel()
    nameLabel.font = UIFont.boldSystemFont(ofSize: 19.0)
    nameLabel.textColor = ANIColor.dark
    nameLabel.numberOfLines = 0
    addSubview(nameLabel)
    nameLabel.topToSuperview(offset: 10.0)
    nameLabel.leftToSuperview(offset: 10.0)
    nameLabel.rightToLeft(of: followButton, offset: -10.0)
    self.nameLabel = nameLabel
    
    //followingBG
    let followingBG = UIView()
    followingBG.isUserInteractionEnabled = true
    let followingTapGesture = UITapGestureRecognizer(target: self, action: #selector(followingTapped))
    followingBG.addGestureRecognizer(followingTapGesture)
    addSubview(followingBG)
    followingBG.topToBottom(of: nameLabel, offset: 10.0)
    followingBG.leftToSuperview(offset: 10.0)
    self.followingBG = followingBG
    
    //followingCountLabel
    let followingCountLabel = UILabel()
    followingCountLabel.text = "0"
    followingCountLabel.textColor = ANIColor.dark
    followingCountLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    followingBG.addSubview(followingCountLabel)
    followingCountLabel.edgesToSuperview(excluding: .right)
    self.followingCountLabel = followingCountLabel
    
    //followingLabel
    let followingLabel = UILabel()
    followingLabel.text = "フォロー中"
    followingLabel.textColor = ANIColor.subTitle
    followingLabel.font = UIFont.systemFont(ofSize: 15.0)
    followingBG.addSubview(followingLabel)
    followingLabel.bottom(to: followingCountLabel)
    followingLabel.leftToRight(of: followingCountLabel, offset: 5.0)
    followingLabel.rightToSuperview()
    self.followingLabel = followingLabel
    
    //followerBG
    let followerBG = UIView()
    followerBG.isUserInteractionEnabled = true
    let followerTapGesture = UITapGestureRecognizer(target: self, action: #selector(followerTapped))
    followerBG.addGestureRecognizer(followerTapGesture)
    addSubview(followerBG)
    followerBG.topToBottom(of: nameLabel, offset: 10.0)
    followerBG.leftToRight(of: followingBG, offset: 20.0)
    self.followerBG = followerBG
    
    //followerCountLabel
    let followerCountLabel = UILabel()
    followerCountLabel.text = "0"
    followerCountLabel.textColor = ANIColor.dark
    followerCountLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    followerBG.addSubview(followerCountLabel)
    followerCountLabel.edgesToSuperview(excluding: .right)
    self.followerCountLabel = followerCountLabel
    
    //followerLabel
    let followerLabel = UILabel()
    followerLabel.text = "フォロワー"
    followerLabel.textColor = ANIColor.subTitle
    followerLabel.font = UIFont.systemFont(ofSize: 15.0)
    followerBG.addSubview(followerLabel)
    followerLabel.bottom(to: followerCountLabel)
    followerLabel.leftToRight(of: followerCountLabel, offset: 5.0)
    followerLabel.rightToSuperview()
    self.followerLabel = followerLabel
    
    //groupLabel
    let groupLabel = UILabel()
    groupLabel.font = UIFont.systemFont(ofSize: 17.0)
    groupLabel.textAlignment = .center
    groupLabel.textColor = ANIColor.dark
    addSubview(groupLabel)
    groupLabel.topToBottom(of: followingBG, offset: 10.0)
    groupLabel.leftToSuperview(offset: 10.0)
    self.groupLabel = groupLabel
    
    //instroduceStackView
    let instroduceStackView = UIStackView()
    instroduceStackView.axis = .vertical
    instroduceStackView.distribution = .equalSpacing
    instroduceStackView.spacing = 10.0
    addSubview(instroduceStackView)
    instroduceStackView.topToBottom(of: groupLabel, offset: 10.0)
    instroduceStackView.leftToSuperview(offset: 10.0)
    instroduceStackView.rightToSuperview(offset: -10.0)
    instroduceStackView.bottomToSuperview(offset: -10.0)
    self.instroduceStackView = instroduceStackView
    
    //twitterBG
    let twitterBG = UIView()
    twitterBG.backgroundColor = .white
    twitterBG.isHidden = true
    twitterBG.isUserInteractionEnabled = true
    twitterBG.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(twitterTapped)))
    instroduceStackView.addArrangedSubview(twitterBG)
    self.twitterBG = twitterBG
    
    //twitterImageView
    let twitterImageView = UIImageView()
    twitterImageView.image = UIImage(named: "twitter")
    twitterImageView.contentMode = .scaleAspectFit
    twitterBG.addSubview(twitterImageView)
    twitterImageView.width(20.0)
    twitterImageView.height(20.0)
    twitterImageView.topToSuperview()
    twitterImageView.leftToSuperview()
    self.twitterImageView = twitterImageView
    
    //twitterLabel
    let twitterLabel = UILabel()
    twitterLabel.numberOfLines = 0
    twitterLabel.font = UIFont.systemFont(ofSize: 17.0)
    twitterLabel.textColor = ANIColor.dark
    twitterBG.addSubview(twitterLabel)
    twitterLabel.topToSuperview(offset: -2.0)
    twitterLabel.leftToRight(of: twitterImageView, offset: 5.0)
    twitterLabel.rightToSuperview()
    twitterLabel.bottomToSuperview()
    self.twitterLabel = twitterLabel
    
    //instagramBG
    let instagramBG = UIView()
    instagramBG.backgroundColor = .white
    instagramBG.isHidden = true
    instagramBG.isUserInteractionEnabled = true
    instagramBG.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(instagramTapped)))
    instroduceStackView.addArrangedSubview(instagramBG)
    self.instagramBG = instagramBG
    
    //instagramImageView
    let instagramImageView = UIImageView()
    instagramImageView.image = UIImage(named: "instagram")
    instagramImageView.contentMode = .scaleAspectFit
    instagramBG.addSubview(instagramImageView)
    instagramImageView.width(20.0)
    instagramImageView.height(20.0)
    instagramImageView.topToSuperview()
    instagramImageView.leftToSuperview()
    self.instagramImageView = instagramImageView
    
    //twitterLabel
    let instagramLabel = UILabel()
    instagramLabel.numberOfLines = 0
    instagramLabel.font = UIFont.systemFont(ofSize: 17.0)
    instagramLabel.textColor = ANIColor.dark
    instagramBG.addSubview(instagramLabel)
    instagramLabel.topToSuperview(offset: -2.0)
    instagramLabel.leftToRight(of: instagramImageView, offset: 5.0)
    instagramLabel.rightToSuperview()
    instagramLabel.bottomToSuperview()
    self.instagramLabel = instagramLabel
    
    //introduceBG
    let introduceBG = UIView()
    introduceBG.backgroundColor = ANIColor.bg
    introduceBG.layer.cornerRadius = 10.0
    introduceBG.layer.masksToBounds = true
    introduceBG.isHidden = true
    instroduceStackView.addArrangedSubview(introduceBG)
    self.introduceBG = introduceBG
    
    //introductionLabel
    let introductionLabel = ActiveLabel()
    introductionLabel.font = UIFont.systemFont(ofSize: 17.0)
    introductionLabel.numberOfLines = 0
    introductionLabel.textColor = ANIColor.dark
    introductionLabel.enabledTypes = [.url]
    introductionLabel.urlMaximumLength = 30
    introductionLabel.customize { (label) in
      label.URLColor = ANIColor.darkblue
    }
    introductionLabel.handleURLTap { (url) in
      self.delegate?.openUrl(url: url)
    }
    introduceBG.addSubview(introductionLabel)
    introductionLabel.topToSuperview(offset: 10.0)
    introductionLabel.leftToSuperview(offset: 10.0)
    introductionLabel.rightToSuperview(offset: -10.0)
    introductionLabel.bottomToSuperview(offset: -10.0, priority: .defaultHigh)
    self.introductionLabel = introductionLabel
  }
  
  private func reloadLayout() {
    guard let nameLabel = self.nameLabel,
          let groupLabel = self.groupLabel,
          let twitterBG = self.twitterBG,
          let twitterLabel = self.twitterLabel,
          let instagramBG = self.instagramBG,
          let instagramLabel = self.instagramLabel,
          let introduceBG = self.introduceBG,
          let introductionLabel = self.introductionLabel,
          let user = self.user else { return }
    
    nameLabel.text = user.userName
    
    groupLabel.text = user.kind
    
    twitterLabel.text = user.twitterAccount
    if let twitterAccount = user.twitterAccount {
      if twitterAccount.count != 0 {
        twitterBG.isHidden = false
      } else {
        twitterBG.isHidden = true
      }
    } else {
      twitterBG.isHidden = true
    }
    
    instagramLabel.text = user.instagramAccount
    if let instagramAccount = user.instagramAccount {
      if instagramAccount.count != 0 {
        instagramBG.isHidden = false
      } else {
        instagramBG.isHidden = true
      }
    } else {
      instagramBG.isHidden = true
    }
    
    introductionLabel.text = user.introduce
    if let introduce = user.introduce {
      if introduce.count != 0 {
        introduceBG.isHidden = false
      } else {
        introduceBG.isHidden = true
      }
    } else {
      introduceBG.isHidden = true
    }
  }
  
  private func reloadFollowLayout() {
    guard let followButton = self.followButton,
          let followLabel = self.followLabel else { return }
    
    if isFollowed {
      followButton.base?.backgroundColor = .clear
      followLabel.text = "フォロー中"
      followLabel.textColor = ANIColor.emerald
    } else {
      followButton.base?.backgroundColor = ANIColor.emerald
      followLabel.text = "フォロー"
      followLabel.textColor = .white
    }
  }
  
  func observeUserFollow() {
    guard let userId = self.userId,
          let followingCountLabel = self.followingCountLabel,
          let followerCountLabel = self.followerCountLabel else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWING_USER_IDS).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }

        guard let snapshot = snapshot else { return }

        followingCountLabel.text = "\(snapshot.documents.count)"
      })
      
      database.collection(KEY_USERS).document(userId).collection(KEY_FOLLOWER_IDS).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }

        guard let snapshot = snapshot else { return }

        followerCountLabel.text = "\(snapshot.documents.count)"
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
  @objc private func followingTapped() {
    self.delegate?.followingTapped()
  }
  
  @objc private func followerTapped() {
    self.delegate?.followerTapped()
  }
  
  @objc private func twitterTapped() {
    guard let user = user,
      let twitterAccount = user.twitterAccount else { return }
    
    if let twitterUrl = URL(string: "twitter://user?screen_name=" + twitterAccount),
      UIApplication.shared.canOpenURL(twitterUrl) {
      UIApplication.shared.open(twitterUrl, options: [:], completionHandler: nil)
    } else {
      self.delegate?.twitterOpenReject()
    }
  }
  
  @objc private func instagramTapped() {
    guard let user = user,
          let instagramAccount = user.instagramAccount else { return }
    
    var instagramUserName = instagramAccount
    if instagramAccount.prefix(1) == "@" || instagramAccount.prefix(1) == "＠" {
      instagramUserName = String(instagramAccount.dropFirst())
    }
    
    if let instagramUrl = URL(string: "instagram://user?username=" + instagramUserName),
      UIApplication.shared.canOpenURL(instagramUrl) {
      UIApplication.shared.open(instagramUrl, options: [:], completionHandler: nil)
    } else {
      self.delegate?.instagramOpenReject()
    }
  }
}

//MARK: ANIButtonViewDelegate
extension ANIOtherProfileCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.followButton {
      guard let user = self.user,
            let userId = user.uid,
            let followButton = self.followButton,
            let followLabel = self.followLabel else { return }
      
      let database = Firestore.firestore()
      
      if let currentUserUid = ANISessionManager.shared.currentUserUid, !ANISessionManager.shared.isAnonymous {
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
