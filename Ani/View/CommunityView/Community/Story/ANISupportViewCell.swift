//
//  ANISupportViewCell.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/20.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import ActiveLabel
import TinyConstraints

protocol ANISupportViewCellDelegate {
  func supportCellTapped(story: FirebaseStory, user: FirebaseUser)
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser)
  func reject()
  func loadedRecruit(recruitId: String, recruit: FirebaseRecruit?)
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool)
  func loadedStoryUser(user: FirebaseUser)
}

class ANISupportViewCell: UITableViewCell {
  
  private weak var stackView: UIStackView?

  private weak var base: UIView?
  private let RECRUIT_BASE_BORDER_WIDHT: CGFloat = 1.2
  private weak var deleteRecruitBase: UIView?
  private weak var deleteRecruitImageView: UIImageView?
  private weak var deleteRecruitAlertLabel: UILabel?
  
  private weak var recruitBase: UIView?
  private weak var recruitImageView: UIImageView?
  private weak var basicInfoStackView: UIStackView?
  private weak var recruitStateLabel: UILabel?
  private weak var homeLabel: UILabel?
  private weak var ageLabel: UILabel?
  private weak var sexLabel: UILabel?
  private weak var titleLabel: UILabel?
  private weak var subTitleLabel: UILabel?
  
  private weak var messageLabelBase: UIView?
  private weak var messageLabel: ActiveLabel?
  
  private weak var storyCommentView: ANIContributionCommentView?
  
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
  
  var delegate: ANISupportViewCellDelegate?
  
  var story: FirebaseStory? {
    didSet {
      guard let storyCommentView = self.storyCommentView else  { return }

      if user == nil {
        loadUser()
      }
      if recruit == nil, isDeleteRecruit == nil {
        loadRecruit()
      }
      
      storyCommentView.story = story

      reloadLayout()
      observeLove()
      observeComment()
    }
  }
  
  var recruit: FirebaseRecruit? {
    didSet {
      guard let recruitBase = self.recruitBase else { return }

      if let recruit = self.recruit {
        recruitBase.alpha = 1.0
        loadRecruitUser()
        reloadRecruitLayout(recruit: recruit)
      } else {
        recruitBase.alpha = 0.0
      }
    }
  }
  
  var isDeleteRecruit: Bool? {
    didSet {
      guard let isDeleteRecruit = self.isDeleteRecruit,
            let deleteRecruitImageView = self.deleteRecruitImageView,
            let deleteRecruitAlertLabel = self.deleteRecruitAlertLabel else { return }

      if isDeleteRecruit {
        deleteRecruitImageView.isHidden = false
        deleteRecruitAlertLabel.isHidden = false
      } else {
        deleteRecruitImageView.isHidden = true
        deleteRecruitAlertLabel.isHidden = true
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
  
  var commentUsers: [FirebaseUser?]? {
    didSet {
      guard let storyCommentView = self.storyCommentView,
            let commentUsers = self.commentUsers else { return }
      
      if !commentUsers.isEmpty {
        storyCommentView.commentOneUser = commentUsers[0]
        
        if commentUsers.count > 1 {
          storyCommentView.commentTwoUser = commentUsers[1]
        }
      }
    }
  }

  private var recruitUser: FirebaseUser?
  
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
    
    //base
    let base = UIView()
    base.backgroundColor = .white
    stackView.addArrangedSubview(base)
    self.base = base
    
    //deleteRecruitBase
    let deleteRecruitBase = UIView()
    deleteRecruitBase.backgroundColor = .white
    deleteRecruitBase.layer.cornerRadius = 10.0
    deleteRecruitBase.layer.masksToBounds = true
    deleteRecruitBase.layer.borderColor = ANIColor.gray.cgColor
    deleteRecruitBase.layer.borderWidth = RECRUIT_BASE_BORDER_WIDHT
    base.addSubview(deleteRecruitBase)
    self.deleteRecruitBase = deleteRecruitBase
    
    //deleteRecruitImageView
    let deleteRecruitImageView = UIImageView()
    deleteRecruitImageView.image = UIImage(named: "notSee")
    deleteRecruitImageView.contentMode = .scaleAspectFill
    deleteRecruitImageView.isHidden = true
    deleteRecruitBase.addSubview(deleteRecruitImageView)
    deleteRecruitImageView.width(UIScreen.main.bounds.width * 0.12)
    deleteRecruitImageView.heightToWidth(of: deleteRecruitImageView)
    deleteRecruitImageView.centerXToSuperview()
    deleteRecruitImageView.centerYToSuperview(offset: -20.0)
    self.deleteRecruitImageView = deleteRecruitImageView
    
    //deleteRecruitAlertLabel
    let deleteRecruitAlertLabel = UILabel()
    deleteRecruitAlertLabel.text = "削除された募集です"
    deleteRecruitAlertLabel.textColor = ANIColor.dark
    deleteRecruitAlertLabel.textAlignment = .center
    deleteRecruitAlertLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    deleteRecruitAlertLabel.isHidden = true
    deleteRecruitBase.addSubview(deleteRecruitAlertLabel)
    deleteRecruitAlertLabel.topToBottom(of: deleteRecruitImageView, offset: 20)
    deleteRecruitAlertLabel.leftToSuperview(offset: 10)
    deleteRecruitAlertLabel.rightToSuperview(offset: -10)
    self.deleteRecruitAlertLabel = deleteRecruitAlertLabel
    
    //recruitBase
    let recruitBase = UIView()
    recruitBase.backgroundColor = .white
    recruitBase.layer.cornerRadius = 10.0
    recruitBase.layer.masksToBounds = true
    recruitBase.layer.borderColor = ANIColor.gray.cgColor
    recruitBase.layer.borderWidth = RECRUIT_BASE_BORDER_WIDHT
    recruitBase.isUserInteractionEnabled = true
    recruitBase.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(recruitTapped)))
    base.addSubview(recruitBase)
    recruitBase.topToSuperview(offset: 10.0)
    recruitBase.leftToSuperview(offset: 10.0)
    recruitBase.rightToSuperview(offset: -10.0)
    recruitBase.bottomToSuperview()
    self.recruitBase = recruitBase
    
    deleteRecruitBase.edges(to: recruitBase)
    
    //recruitImageView
    let recruitImageView = UIImageView()
    recruitImageView.backgroundColor = ANIColor.gray
    recruitImageView.contentMode = .redraw
    recruitBase.addSubview(recruitImageView)
    let recruitImageViewHeight: CGFloat = (UIScreen.main.bounds.width - 20) * UIViewController.HEADER_IMAGE_VIEW_RATIO
    recruitImageView.topToSuperview()
    recruitImageView.leftToSuperview()
    recruitImageView.rightToSuperview()
    recruitImageView.height(recruitImageViewHeight, priority: .defaultHigh)
    self.recruitImageView = recruitImageView
    
    //basicInfoStackView
    let basicInfoStackView = UIStackView()
    basicInfoStackView.axis = .horizontal
    basicInfoStackView.distribution = .fillEqually
    basicInfoStackView.alignment = .center
    basicInfoStackView.spacing = 5.0
    recruitBase.addSubview(basicInfoStackView)
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
    recruitBase.addSubview(titleLabel)
    titleLabel.topToBottom(of: basicInfoStackView, offset: 10.0)
    titleLabel.leftToSuperview(offset: 10.0)
    titleLabel.rightToSuperview(offset: -10.0)
    self.titleLabel = titleLabel
    
    //subTitleLabel
    let subTitleLabel = UILabel()
    subTitleLabel.numberOfLines = 3
    subTitleLabel.font = UIFont.systemFont(ofSize: 14.0)
    subTitleLabel.textColor = ANIColor.subTitle
    recruitBase.addSubview(subTitleLabel)
    subTitleLabel.topToBottom(of: titleLabel, offset: 10.0, priority: .defaultHigh)
    subTitleLabel.leftToSuperview(offset: 10.0)
    subTitleLabel.rightToSuperview(offset: -10.0)
    subTitleLabel.bottomToSuperview(offset: -10)
    self.subTitleLabel = subTitleLabel
    
    //messageLabelBase
    let messageLabelBase = UIView()
    messageLabelBase.backgroundColor = .white
    stackView.addArrangedSubview(messageLabelBase)
    self.messageLabelBase = messageLabelBase
    
    //messageLabel
    let messageLabel = ActiveLabel()
    messageLabel.font = UIFont.systemFont(ofSize: 14.0)
    messageLabel.textAlignment = .left
    messageLabel.textColor = ANIColor.subTitle
    messageLabel.numberOfLines = 0
    messageLabel.enabledTypes = [.hashtag]
    messageLabel.customize { (label) in
      label.hashtagColor = ANIColor.darkblue
    }
    messageLabel.handleHashtagTap { (hashtag) in
      ANINotificationManager.postTapHashtag(contributionKind: KEY_CONTRIBUTION_KIND_STROY, hashtag: hashtag)
    }
    messageLabelBase.addSubview(messageLabel)
    messageLabel.topToBottom(of: recruitBase, offset: 10.0)
    messageLabel.leftToSuperview(offset: 10.0)
    messageLabel.rightToSuperview(offset: -10.0)
    messageLabel.bottomToSuperview()
    self.messageLabel = messageLabel
    
    //storyCommentView
    let storyCommentView = ANIContributionCommentView()
    storyCommentView.delegate = self
    stackView.addArrangedSubview(storyCommentView)
    self.storyCommentView = storyCommentView
    
    //bottomArea
    let bottomArea = UIView()
    addSubview(bottomArea)
    bottomArea.topToBottom(of: stackView, offset: 10.0)
    bottomArea.edgesToSuperview(excluding: .top)
    self.bottomArea = bottomArea
    
    //profileImageView
    let profileImageView = UIImageView()
    profileImageView.backgroundColor = ANIColor.gray
    profileImageView.isUserInteractionEnabled = true
    profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(profileImageViewTapped)))
    addSubview(profileImageView)
    profileImageView.top(to: bottomArea)
    profileImageView.leftToSuperview(offset: 10.0)
    profileImageView.width(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.height(PROFILE_IMAGE_VIEW_HEIGHT)
    profileImageView.layer.cornerRadius = PROFILE_IMAGE_VIEW_HEIGHT / 2
    profileImageView.layer.masksToBounds = true
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
    loveCountLabel.rightToLeft(of: commentButton, offset: -10.0)
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
    userNameLabel.leftToRight(of: profileImageView, offset: 10.0)
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
    guard let titleLabel = self.titleLabel,
          let subTitleLabel = self.subTitleLabel,
          let messageLabelBase = self.messageLabelBase,
          let messageLabel = self.messageLabel,
          let storyCommentView = self.storyCommentView,
          let loveButtonBG = self.loveButtonBG,
          let loveButton = self.loveButton,
          let story = self.story else { return }
    
    titleLabel.text = story.recruitTitle
    subTitleLabel.text = story.recruitSubTitle
    
    messageLabel.text = story.story
    if story.story == "" {
      messageLabelBase.isHidden = true
    } else {
      messageLabelBase.isHidden = false
    }
    
    if story.comments != nil {
      storyCommentView.isHidden = false
    } else {
      storyCommentView.isHidden = true
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
  
  private func reloadRecruitLayout(recruit: FirebaseRecruit) {
    guard let recruitImageView = self.recruitImageView,
          let recruitStateLabel = self.recruitStateLabel,
          let homeLabel = self.homeLabel,
          let ageLabel = self.ageLabel,
          let sexLabel = self.sexLabel,
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
  }
  
  private func loadRecruitUser() {
    guard let recruit = self.recruit else { return }
    
    DispatchQueue.global().async {
      let database = Firestore.firestore()
      database.collection(KEY_USERS).document(recruit.userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let recruitUser = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          
          self.recruitUser = recruitUser
        } catch let error {
          DLog(error)
        }
      })
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
    
    self.delegate?.supportCellTapped(story: story, user: user)
  }
  
  @objc private func recruitTapped() {
    guard let recruit = self.recruit,
          let recruitUser = self.recruitUser else { return }
    
    self.delegate?.supportCellRecruitTapped(recruit: recruit, user: recruitUser)
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
extension ANISupportViewCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.loveButton {
      love()
    }
  }
}

//MARK: ANIContributionCommentViewDelegate
extension ANISupportViewCell: ANIContributionCommentViewDelegate {
  func loadedCommentUser(user: FirebaseUser) {
    self.delegate?.loadedStoryUser(user: user)
  }
}

//MARK: data
extension ANISupportViewCell {
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
  
  private func loadRecruit() {
    guard let story = self.story,
          let recruitId = story.recruitId else { return }
    
    DispatchQueue.global().async {
      let database = Firestore.firestore()
      
      database.collection(KEY_RECRUITS).document(recruitId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else {
          self.delegate?.loadedRecruit(recruitId: recruitId ,recruit: nil)
          self.isDeleteRecruit = true
          return }
        
        do {
          let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: data)
          self.recruit = recruit
          self.delegate?.loadedRecruit(recruitId: recruitId ,recruit: recruit)
          self.isDeleteRecruit = false
        } catch let error {
          DLog(error)
          
          self.isDeleteRecruit = false
        }
      })
    }
  }
}
