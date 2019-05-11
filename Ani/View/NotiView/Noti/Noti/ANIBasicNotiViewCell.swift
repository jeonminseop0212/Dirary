//
//  ANINotiViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/15.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import TinyConstraints

protocol ANIBasicNotiViewCellDelegate {
  func loadedNotiUser(user: FirebaseUser)
}

class ANIBasicNotiViewCell: UITableViewCell {
  
  private weak var base: UIView?
  private weak var stackView: UIStackView?
  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 50.0
  private weak var profileImageView: UIImageView?
  private weak var notiLabel: UILabel?
  
  private var spaceViewTopToProfileImageViewConstraint: Constraint?
  private var spaceViewTopToNotiLabelConstraint: Constraint?
  private weak var spaceView: UIView?
  
  var noti: FirebaseNotification? {
    didSet {
      if user == nil {
        loadUser()
      }
      reloadLayout()
    }
  }
  
  var user: FirebaseUser? {
    didSet {
      reloadUserLayout()
    }
  }
  
  var delegate: ANIBasicNotiViewCellDelegate?
  
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
    
    //base
    let base = UIView()
    base.backgroundColor = .white
    addSubview(base)
    base.edgesToSuperview()
    self.base = base
    
    //stackView
    let stackView = UIStackView()
    stackView.alignment = .top
    stackView.axis = .horizontal
    stackView.spacing = 10.0
    base.addSubview(stackView)
    stackView.topToSuperview(offset: 10.0)
    stackView.leftToSuperview(offset: 10.0)
    stackView.rightToSuperview(offset: -10.0)
    self.stackView = stackView
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    profileImageView.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped))
    profileImageView.addGestureRecognizer(tapGesture)
    stackView.addArrangedSubview(profileImageView)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    self.profileImageView = profileImageView

    //notiLabel
    let notiLabel = UILabel()
    notiLabel.numberOfLines = 0
    notiLabel.font = UIFont.systemFont(ofSize: 14.0)
    notiLabel.textColor = ANIColor.subTitle
    stackView.addArrangedSubview(notiLabel)
    self.notiLabel = notiLabel
    
    //bottomSpace
    let spaceView = UIView()
    spaceView.backgroundColor = ANIColor.bg
    base.addSubview(spaceView)
    spaceView.topToBottom(of: stackView, offset: 10.0)
    spaceView.leftToSuperview()
    spaceView.rightToSuperview()
    spaceView.height(10.0)
    spaceView.bottomToSuperview()
    self.spaceView = spaceView
  }
  
  private func reloadLayout() {
    guard let notiLabel = self.notiLabel,
          let noti = self.noti,
          let base = self.base else { return }
    
    notiLabel.text = noti.noti
    
    base.backgroundColor = .white
    if !checkRead(noti: noti) {
      base.backgroundColor = ANIColor.emerald.withAlphaComponent(0.1)
      UIView.animate(withDuration: 0.2, delay: 1, options: .curveEaseOut, animations: {
        base.backgroundColor = .white
      }, completion: nil)
    }
  }
  
  private func reloadUserLayout() {
    guard let profileImageView = self.profileImageView else { return }
    
    if let user = self.user, let profileImageUrl = user.profileImageUrl {
      profileImageView.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
    } else {
      profileImageView.image = UIImage()
    }
  }
  
  private func checkRead(noti: FirebaseNotification) -> Bool {
    guard let checkNotiDate = ANISessionManager.shared.checkNotiDate else { return false }
    
    let checkDate = ANIFunction.shared.dateFromString(string: checkNotiDate)
    let notiUpdateDate = ANIFunction.shared.dateFromString(string: noti.updateDate)
    
    if checkDate > notiUpdateDate {
      return true
    } else {
      return false
    }
  }
  
  @objc private func profileImageViewTapped() {
    guard let noti = self.noti else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: noti.userId)
  }
}

//MARK: data
extension ANIBasicNotiViewCell {
  func loadUser() {
    guard let noti = self.noti else { return }
    
    let database = Firestore.firestore()

    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(noti.userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          self.user = user
          self.delegate?.loadedNotiUser(user: user)
        } catch let error {
          DLog(error)
        }
      })
    }
  }
}
