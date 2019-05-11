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

protocol ANIRecruitViewCellDelegate {
  func cellTapped(recruit: FirebaseRecruit, user: FirebaseUser)
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser)
  func reject()
  func loadedRecruitIsLoved(indexPath: Int, isLoved: Bool)
  func loadedRecruitIsCliped(indexPath: Int, isCliped: Bool)
  func loadedRecruitIsSupported(indexPath: Int, isSupported: Bool)
  func loadedRecruitUser(user: FirebaseUser)
}

class ANIRecruitViewCell: UITableViewCell {
  
  private weak var base: UIView?
  private weak var tapArea: UIView?
  private weak var recruitImageView: UIImageView?
  private weak var basicInfoStackView: UIStackView?
  private weak var recruitStateLabel: UILabel?
  private weak var homeLabel: UILabel?
  private weak var ageLabel: UILabel?
  private weak var sexLabel: UILabel?
  private weak var titleLabel: UILabel?
  private weak var subTitleLabel: UILabel?
  private let PROFILE_IMAGE_HEIGHT: CGFloat = 32.0
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  private weak var supportCountLabel: UILabel?
  private weak var supportButton: UIButton?
  private weak var loveButtonBG: UIView?
  private weak var loveButton: ANICellButtonView?
  private weak var loveCountLabel: UILabel?
  private weak var clipButtonBG: UIView?
  private weak var clipButton: ANICellButtonView?
  
  var recruit: FirebaseRecruit? {
    didSet {
      guard let recruit = self.recruit else { return }
      
      if user == nil {
        loadUser()
      }
      if recruit.isCliped == nil {
        isClipped()
      }
      reloadLayout()
      observeLove()
      observeSupport()
    }
  }
  
  var indexPath: Int?
  
  var user: FirebaseUser? {
    didSet {
      self.reloadUserLayout()
    }
  }
  
  private var supportCount: Int = 0 {
    didSet {
      guard let supportCountLabel = self.supportCountLabel else { return }
      
      DispatchQueue.main.async {
        supportCountLabel.text = "\(self.supportCount)"
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
  
  private var loveListener: ListenerRegistration?
  private var supportListener: ListenerRegistration?
  
  var delegate: ANIRecruitViewCellDelegate?
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.selectionStyle = .none
    self.backgroundColor = ANIColor.bg
    
    //base
    let base = UIView()
    base.backgroundColor = .white
    base.layer.cornerRadius = 10.0
    base.layer.masksToBounds = true
    addSubview(base)
    base.topToSuperview(offset: 0)
    base.leftToSuperview(offset: 10)
    base.rightToSuperview(offset: -10)
    base.bottomToSuperview(offset: -10)
    self.base = base
    
    //tapArea
    let tapArea = UIView()
    tapArea.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cellTapped)))
    base.addSubview(tapArea)
    tapArea.edgesToSuperview(excluding: .bottom)
    self.tapArea = tapArea
    
    //recruitImageView
    let recruitImageView = UIImageView()
    recruitImageView.backgroundColor = ANIColor.gray
    recruitImageView.contentMode = .scaleAspectFill
    recruitImageView.clipsToBounds = true
    tapArea.addSubview(recruitImageView)
    let recruitImageViewHeight: CGFloat = UIScreen.main.bounds.width * UIViewController.HEADER_IMAGE_VIEW_RATIO
    recruitImageView.topToSuperview()
    recruitImageView.leftToSuperview()
    recruitImageView.rightToSuperview()
    recruitImageView.height(recruitImageViewHeight)
    self.recruitImageView = recruitImageView
    
    //basicInfoStackView
    let basicInfoStackView = UIStackView()
    basicInfoStackView.axis = .horizontal
    basicInfoStackView.distribution = .fillEqually
    basicInfoStackView.alignment = .center
    basicInfoStackView.spacing = 5.0
    tapArea.addSubview(basicInfoStackView)
    basicInfoStackView.topToBottom(of: recruitImageView, offset: 10.0)
    basicInfoStackView.leftToSuperview(offset: 10.0)
    basicInfoStackView.rightToSuperview(offset: -10.0)
    self.basicInfoStackView = basicInfoStackView
    
    //recruitStateLabel
    let recruitStateLabel = UILabel()
    recruitStateLabel.textColor = .white
    recruitStateLabel.textAlignment = .center
    recruitStateLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    recruitStateLabel.layer.cornerRadius = 5.0
    recruitStateLabel.layer.masksToBounds = true
    recruitStateLabel.backgroundColor = ANIColor.emerald
    basicInfoStackView.addArrangedSubview(recruitStateLabel)
    recruitStateLabel.height(26.0)
    self.recruitStateLabel = recruitStateLabel
    
    //homeLabel
    let homeLabel = UILabel()
    homeLabel.textColor = ANIColor.darkGray
    homeLabel.textAlignment = .center
    homeLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    homeLabel.adjustsFontSizeToFitWidth = true
    homeLabel.layer.cornerRadius = 5.0
    homeLabel.layer.masksToBounds = true
    homeLabel.layer.borderColor = ANIColor.darkGray.cgColor
    homeLabel.layer.borderWidth = 1.2
    basicInfoStackView.addArrangedSubview(homeLabel)
    homeLabel.height(26.0)
    self.homeLabel = homeLabel
    
    //ageLabel
    let ageLabel = UILabel()
    ageLabel.textColor = ANIColor.darkGray
    ageLabel.textAlignment = .center
    ageLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    ageLabel.adjustsFontSizeToFitWidth = true
    ageLabel.layer.cornerRadius = 5.0
    ageLabel.layer.masksToBounds = true
    ageLabel.layer.borderColor = ANIColor.darkGray.cgColor
    ageLabel.layer.borderWidth = 1.2
    basicInfoStackView.addArrangedSubview(ageLabel)
    ageLabel.height(26.0)
    self.ageLabel = ageLabel
    
    //sexLabel
    let sexLabel = UILabel()
    sexLabel.textColor = ANIColor.darkGray
    sexLabel.textAlignment = .center
    sexLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    sexLabel.adjustsFontSizeToFitWidth = true
    sexLabel.layer.cornerRadius = 5.0
    sexLabel.layer.masksToBounds = true
    sexLabel.layer.borderColor = ANIColor.darkGray.cgColor
    sexLabel.layer.borderWidth = 1.2
    basicInfoStackView.addArrangedSubview(sexLabel)
    sexLabel.height(26.0)
    self.sexLabel = sexLabel
    
    //titleLabel
    let titleLabel = UILabel()
    titleLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    titleLabel.textAlignment = .left
    titleLabel.textColor = ANIColor.dark
    titleLabel.numberOfLines = 0
    tapArea.addSubview(titleLabel)
    titleLabel.topToBottom(of: basicInfoStackView, offset: 10.0)
    titleLabel.leftToSuperview(offset: 10.0)
    titleLabel.rightToSuperview(offset: -10.0)
    self.titleLabel = titleLabel
    
    //subTitleLabel
    let subTitleLabel = UILabel()
    subTitleLabel.numberOfLines = 3
    subTitleLabel.font = UIFont.systemFont(ofSize: 14.0)
    subTitleLabel.textColor = ANIColor.subTitle
    tapArea.addSubview(subTitleLabel)
    subTitleLabel.topToBottom(of: titleLabel, offset: 10.0)
    subTitleLabel.leftToSuperview(offset: 10.0)
    subTitleLabel.rightToSuperview(offset: -10.0)
    subTitleLabel.bottomToSuperview()
    self.subTitleLabel = subTitleLabel
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.isUserInteractionEnabled = true
    profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
    profileImageView.backgroundColor = ANIColor.gray
    base.addSubview(profileImageView)
    profileImageView.topToBottom(of: tapArea, offset: 10.0)
    profileImageView.leftToSuperview(offset: 10.0)
    profileImageView.bottomToSuperview(offset: -10.0)
    profileImageView.width(PROFILE_IMAGE_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_HEIGHT)
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
    self.profileImageView = profileImageView
    
    //clipButtonBG
    let clipButtonBG = UIView()
    clipButtonBG.isUserInteractionEnabled = false
    clipButtonBG.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clipButtonBGTapped)))
    base.addSubview(clipButtonBG)
    clipButtonBG.centerY(to: profileImageView)
    clipButtonBG.rightToSuperview(offset: -10.0)
    clipButtonBG.width(30.0)
    clipButtonBG.height(30.0)
    self.clipButtonBG = clipButtonBG
    
    //clipButton
    let clipButton = ANICellButtonView()
    clipButton.image = UIImage(named: "cellClipButton")
    clipButton.unSelectedImage = UIImage(named: "cellClipButton")
    clipButton.selectedImage = UIImage(named: "cellClipButtonSelected")
    clipButton.delegate = self
    base.addSubview(clipButton)
    clipButton.centerY(to: profileImageView)
    clipButton.rightToSuperview(offset: -10.0)
    clipButton.width(30.0)
    clipButton.height(30.0)
    self.clipButton = clipButton
    
    //loveCountLabel
    let loveCountLabel = UILabel()
    loveCountLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    loveCountLabel.textColor = ANIColor.dark
    base.addSubview(loveCountLabel)
    loveCountLabel.centerY(to: profileImageView)
    loveCountLabel.rightToLeft(of: clipButton, offset: -5.0)
    loveCountLabel.width(25.0)
    loveCountLabel.height(20.0)
    self.loveCountLabel = loveCountLabel
    
    //loveButtonBG
    let loveButtonBG = UIView()
    loveButtonBG.isUserInteractionEnabled = false
    loveButtonBG.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loveButtonBGTapped)))
    base.addSubview(loveButtonBG)
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
    
    //supportCountLabel
    let supportCountLabel = UILabel()
    supportCountLabel.font = UIFont.boldSystemFont(ofSize: 14.0)
    supportCountLabel.textColor = ANIColor.dark
    base.addSubview(supportCountLabel)
    supportCountLabel.centerY(to: profileImageView)
    supportCountLabel.rightToLeft(of: loveButton, offset: -5.0)
    supportCountLabel.width(25.0)
    supportCountLabel.height(20.0)
    self.supportCountLabel = supportCountLabel
    
    //supportButton
    let supportButton = UIButton()
    supportButton.setImage(UIImage(named: "supportButton"), for: .normal)
    supportButton.addTarget(self, action: #selector(support), for: .touchUpInside)
    base.addSubview(supportButton)
    supportButton.centerY(to: profileImageView)
    supportButton.rightToLeft(of: supportCountLabel, offset: -5.0)
    supportButton.width(30.0)
    supportButton.height(30.0)
    self.supportButton = supportButton
    
    //userNameLabel
    let userNameLabel = UILabel()
    userNameLabel.font = UIFont.systemFont(ofSize: 13.0)
    userNameLabel.textColor = ANIColor.subTitle
    userNameLabel.numberOfLines = 2
    userNameLabel.isUserInteractionEnabled = true
    userNameLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
    base.addSubview(userNameLabel)
    userNameLabel.leftToRight(of: profileImageView, offset: 10.0)
    userNameLabel.rightToLeft(of: supportButton, offset: -10.0)
    userNameLabel.centerY(to: profileImageView)
    self.userNameLabel = userNameLabel
  }
  
  private func reloadLayout() {
    guard let recruitImageView = self.recruitImageView,
          let recruitStateLabel = self.recruitStateLabel,
          let homeLabel = self.homeLabel,
          let ageLabel = self.ageLabel,
          let sexLabel = self.sexLabel,
          let titleLabel = self.titleLabel,
          let subTitleLabel = self.subTitleLabel,
          let supportButton = self.supportButton,
          let loveButtonBG = self.loveButtonBG,
          let loveButton = self.loveButton,
          let clipButtonBG = self.clipButtonBG,
          let clipButton = self.clipButton,
          let recruit = self.recruit,
          let headerImageUrl = recruit.headerImageUrl else { return }
    
    recruitImageView.sd_setImage(with: URL(string: headerImageUrl), completed: nil)
    if recruit.recruitState == 0 {
      recruitStateLabel.text = "募集中"
      recruitStateLabel.backgroundColor  = ANIColor.emerald
    } else if recruit.recruitState == 1 {
      recruitStateLabel.text = "家族決定"
      recruitStateLabel.backgroundColor  = ANIColor.pink
    } else if recruit.recruitState == 2 {
      recruitStateLabel.text = "中止"
      recruitStateLabel.backgroundColor  = ANIColor.darkGray
    }
    homeLabel.text = recruit.home
    ageLabel.text = recruit.age
    sexLabel.text = recruit.sex
    titleLabel.text = recruit.title
    subTitleLabel.text = recruit.reason
    
    supportButton.setImage(UIImage(named: "supportButton"), for: .normal)
    if let isSupported = recruit.isSupported {
      if isSupported {
        supportButton.setImage(UIImage(named: "supportButtonSelected"), for: .normal)
      } else {
        supportButton.setImage(UIImage(named: "supportButton"), for: .normal)
      }
    }
    
    if ANISessionManager.shared.isAnonymous {
      loveButtonBG.isUserInteractionEnabled = true
      loveButton.isUserInteractionEnabled = false
    } else {
      loveButtonBG.isUserInteractionEnabled = false
      loveButton.isUserInteractionEnabled = true
    }
    loveButton.isSelected = false
    if let isLoved = recruit.isLoved {
      if isLoved {
        loveButton.isSelected = true
      } else {
        loveButton.isSelected = false
      }
    }
    
    if ANISessionManager.shared.isAnonymous {
      clipButtonBG.isUserInteractionEnabled = true
      clipButton.isUserInteractionEnabled = false
    } else {
      clipButtonBG.isUserInteractionEnabled = false
      clipButton.isUserInteractionEnabled = true
    }
    clipButton.isSelected = false
    if let isCliped = recruit.isCliped {
      if isCliped {
        clipButton.isSelected = true
      } else {
        clipButton.isSelected = false
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
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath else { return }
    
    self.loveCount = 0

    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.loveListener = database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_LOVE_IDS).addSnapshotListener({ (snapshot, error) in
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
                self.delegate?.loadedRecruitIsLoved(indexPath: indexPath, isLoved: true)
              } else {
                loveButton.isSelected = false
                self.delegate?.loadedRecruitIsLoved(indexPath: indexPath, isLoved: false)
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
  
  private func observeSupport() {
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let supportButton = self.supportButton,
          let indexPath = self.indexPath else { return }
    
    self.supportCount = 0
    
    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.supportListener = database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_SUPPORT_IDS).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        DispatchQueue.main.async {
          if let snapshot = snapshot {
            self.supportCount = snapshot.documents.count
            
            DispatchQueue.main.async {
              if let currentUserUid = ANISessionManager.shared.currentUserUid {
                var documentIDTemp = [String]()
                for document in snapshot.documents {
                  
                  documentIDTemp.append(document.documentID)
                }
                
                if documentIDTemp.contains(currentUserUid) {
                  supportButton.setImage(UIImage(named: "supportButtonSelected"), for: .normal)
                  self.delegate?.loadedRecruitIsSupported(indexPath: indexPath, isSupported: true)
                } else {
                  supportButton.setImage(UIImage(named: "supportButton"), for: .normal)
                  self.delegate?.loadedRecruitIsSupported(indexPath: indexPath, isSupported: false)
                }
              }
            }
          } else {
            self.supportCount = 0
            supportButton.setImage(UIImage(named: "supportButton"), for: .normal)
          }
        }
      })
    }
  }

  func unobserveSupport() {
    guard let supportListener = self.supportListener else { return }
    
    supportListener.remove()
  }

  private func isClipped() {
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let clipButton = self.clipButton,
          let indexPath = self.indexPath else { return }

    if let currentUserId = ANISessionManager.shared.currentUserUid {
      let database = Firestore.firestore()
      
      DispatchQueue.global().async {
        database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_CLIP_IDS).getDocuments(completion: { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            
            return
          }
          
          guard let snapshot = snapshot else { return }
          
          DispatchQueue.main.async {
            var documentIDTemp = [String]()
            for document in snapshot.documents {
              
              documentIDTemp.append(document.documentID)
            }
            
            if documentIDTemp.contains(currentUserId) {
              clipButton.isSelected = true
              self.delegate?.loadedRecruitIsCliped(indexPath: indexPath, isCliped: true)
            } else {
              self.delegate?.loadedRecruitIsCliped(indexPath: indexPath, isCliped: false)
            }
          }
        })
      }
    } else {
      clipButton.isSelected = false
    }
  }
  
  private func updateNoti() {
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let currentUser = ANISessionManager.shared.currentUser,
          let currentUserName = currentUser.userName,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let user = self.user,
          let userId = user.uid,
          currentUserId != userId else { return }

    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        var noti = ""
        
        if let snapshot = snapshot, snapshot.documents.count > 1 {
          noti = "\(currentUserName)さん、他\(snapshot.documents.count - 1)人が「\(recruit.title)」募集を「いいね」しました。"
        } else {
          noti = "\(currentUserName)さんが「\(recruit.title)」募集を「いいね」しました。"
        }
        
        do {
          let date = ANIFunction.shared.getToday()
          let notification = FirebaseNotification(userId: currentUserId, userName: currentUserName, noti: noti, contributionKind: KEY_CONTRIBUTION_KIND_RECRUIT, notiKind: KEY_NOTI_KIND_LOVE, notiId: recuritId, commentId: nil, updateDate: date)
          let data = try FirestoreEncoder().encode(notification)
          
          database.collection(KEY_USERS).document(userId).collection(KEY_NOTIFICATIONS).document(recuritId).setData(data)
          database.collection(KEY_USERS).document(userId).updateData([KEY_IS_HAVE_UNREAD_NOTI: true])
        } catch let error {
          DLog(error)
        }
      })
    }
  }
  
  //MARK: action
  private func love() {
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath else { return }

    let database = Firestore.firestore()
    
    if loveButton.isSelected == true {
      DispatchQueue.global().async {
        let date = ANIFunction.shared.getToday()
 
        DispatchQueue.global().async {
          database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_LOVE_IDS).document(currentUserId).setData([currentUserId: true, KEY_DATE: date])
        }
        
        DispatchQueue.global().async {
          database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_RECRUIT_IDS).document(recuritId).setData([KEY_DATE: date])
        }

        self.updateNoti()
        ANIFunction.shared.showReviewAlertLove()
        
        self.delegate?.loadedRecruitIsLoved(indexPath: indexPath, isLoved: true)
      }
    } else {
      DispatchQueue.global().async {
        database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_LOVE_IDS).document(currentUserId).delete()
      }
      
      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_RECRUIT_IDS).document(recuritId).delete()
      }
      
      self.delegate?.loadedRecruitIsLoved(indexPath: indexPath, isLoved: false)
    }
  }
  
  @objc private func support() {
    guard let supportButton = self.supportButton,
          let recruit = self.recruit,
          let user = self.user,
          let indexPath = self.indexPath else { return }
    
    if !ANISessionManager.shared.isAnonymous {
      if supportButton.imageView?.image == UIImage(named: "supportButton") {
        self.delegate?.supportButtonTapped(supportRecruit: recruit, user: user)
        self.delegate?.loadedRecruitIsSupported(indexPath: indexPath, isSupported: true)
      }
    } else {
      self.delegate?.reject()
      self.delegate?.loadedRecruitIsSupported(indexPath: indexPath, isSupported: false)
    }
  }
  
  private func clip() {
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let clipButton = self.clipButton,
          let indexPath = self.indexPath else { return }
    
    let database = Firestore.firestore()

    if clipButton.isSelected == true {
      DispatchQueue.global().async {
      database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_CLIP_IDS).document(currentUserId).setData([currentUserId: true])
      }
      
      DispatchQueue.global().async {
        let date = ANIFunction.shared.getToday()
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_CLIP_RECRUIT_IDS).document(recuritId).setData([KEY_DATE: date])
      }
      
      self.delegate?.loadedRecruitIsCliped(indexPath: indexPath, isCliped: true)
    } else {
      DispatchQueue.global().async {
        database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_CLIP_IDS).document(currentUserId).delete()
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_CLIP_RECRUIT_IDS).document(recuritId).delete()
        
        self.delegate?.loadedRecruitIsCliped(indexPath: indexPath, isCliped: false)
      }
    }
  }
  
  @objc private func loveButtonBGTapped() {
    self.delegate?.reject()
  }
  
  @objc private func clipButtonBGTapped() {
    self.delegate?.reject()
  }
  
  @objc private func profileImageViewTapped() {
    guard let recruit = self.recruit else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: recruit.userId)
  }
  
  @objc private func cellTapped() {
    guard let recruit = self.recruit,
          let user = self.user else { return }
    
    self.delegate?.cellTapped(recruit: recruit, user: user)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIRecruitViewCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.loveButton {
      love()
    }
    if view === self.clipButton {
      clip()
    }
  }
}

//MARK: data
extension ANIRecruitViewCell {
  private func loadUser() {
    guard let recruit = self.recruit else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(recruit.userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")

          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          self.user = user
          self.delegate?.loadedRecruitUser(user: user)
        } catch let error {
          DLog(error)
        }
      })
    }
  }
}
