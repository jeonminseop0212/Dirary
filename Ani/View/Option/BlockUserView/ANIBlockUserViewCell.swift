//
//  ANIBlockUserViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/11/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore

protocol ANIBlockUserViewCellDelegate {
  func blockButtonTapped(user: FirebaseUser, isBlock: Bool)
}

class ANIBlockUserViewCell: UITableViewCell {
  
  private weak var stackView: UIStackView?
  private let PROFILE_IMAGE_VIEW_HEIGHT: CGFloat = 50.0
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  private weak var blockButton: ANIAreaButtonView?
  private weak var blockLabel: UILabel?
  
  var user: FirebaseUser? {
    didSet {
      reloadLayout()
      checkBlocked()
    }
  }
  
  private var isBlock: Bool = true
  
  var delegate: ANIBlockUserViewCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.selectionStyle = .none
    
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
    
    //blockButton
    let blockButton = ANIAreaButtonView()
    blockButton.baseCornerRadius = 10.0
    blockButton.base?.backgroundColor = .clear
    blockButton.base?.layer.borderWidth = 1.8
    blockButton.base?.layer.borderColor = ANIColor.emerald.cgColor
    blockButton.delegate = self
    stackView.addArrangedSubview(blockButton)
    blockButton.centerY(to: profileImageView)
    blockButton.width(85.0)
    blockButton.height(30.0)
    self.blockButton = blockButton
    
    //blockLabel
    let blockLabel = UILabel()
    blockLabel.font = UIFont.boldSystemFont(ofSize: 14)
    blockLabel.textColor = ANIColor.emerald
    blockLabel.text = "ブロック中"
    blockLabel.textAlignment = .center
    blockButton.addContent(blockLabel)
    blockLabel.edgesToSuperview()
    self.blockLabel = blockLabel
  }
  
  private func reloadLayout() {
    guard let profileImageView = self.profileImageView,
          let userNameLabel = self.userNameLabel,
          let user = self.user,
          let profileImageUrl = user.profileImageUrl else { return }
    
    profileImageView.sd_setImage(with: URL(string: profileImageUrl), completed: nil)
    userNameLabel.text = user.userName
  }
  
  private func checkBlocked() {
    guard let user = self.user,
          let userId = user.uid,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let blockButton = self.blockButton,
          let blockLabel = self.blockLabel else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_BLOCK_USER_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          if document.documentID == userId {
            blockButton.base?.backgroundColor = .clear
            blockLabel.text = "ブロック中"
            blockLabel.textColor = ANIColor.emerald
            self.isBlock = true
            
            break
          } else {
            blockButton.base?.backgroundColor = ANIColor.emerald
            blockLabel.text = "ブロック"
            blockLabel.textColor = .white
            self.isBlock = false
          }
        }
        
        if snapshot.documents.isEmpty {
          blockButton.base?.backgroundColor = ANIColor.emerald
          blockLabel.text = "ブロック"
          blockLabel.textColor = .white
          self.isBlock = false
        }
      })
    }
  }
}

//MARK: ANIButtonViewDelegate
extension ANIBlockUserViewCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === blockButton {
      guard let user = self.user else { return }
      
      self.delegate?.blockButtonTapped(user: user, isBlock: isBlock)
    }
  }
}
