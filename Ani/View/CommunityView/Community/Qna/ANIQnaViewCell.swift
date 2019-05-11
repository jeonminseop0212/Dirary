//
//  ANIQnaViewCell.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/08.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import TinyConstraints
import ActiveLabel

protocol ANIQnaViewCellDelegate {
  func cellTapped(qna: FirebaseQna, user: FirebaseUser)
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func loadedQnaIsLoved(indexPath: Int, isLoved: Bool)
  func loadedQnaUser(user: FirebaseUser)
}

class ANIQnaViewCell: UITableViewCell {
  private weak var stackView: UIStackView?

  private weak var qnaLabelBase: UIView?
  private weak var questionLabel: ActiveLabel?
  
  private var qnaImagesViewBase: UIView?
  private weak var qnaImagesView: ANIQnaImagesView?
  
  private weak var qnaCommentView: ANIContributionCommentView?
  
  private weak var bottomArea: UIView?
  private weak var profileImageView: UIImageView?
  private weak var userNameLabel: UILabel?
  private weak var loveButtonBG: UIView?
  private weak var loveButton: ANICellButtonView?
  private weak var loveCountLabel: UILabel?
  private weak var commentButton: UIButton?
  private weak var commentCountLabel: UILabel?
  private weak var optionButton: UIButton?
  
  var qna: FirebaseQna? {
    didSet {
      guard let qnaCommentView = self.qnaCommentView else  { return }

      if user == nil {
        loadUser()
      }
      
      reloadLayout()
      
      qnaCommentView.qna = qna

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
      guard let qnaCommentView = self.qnaCommentView,
            let commentUsers = self.commentUsers else  { return }
      
      if !commentUsers.isEmpty {
        qnaCommentView.commentOneUser = commentUsers[0]
        
        if commentUsers.count > 1 {
          qnaCommentView.commentTwoUser = commentUsers[1]
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
  
  var delegate: ANIQnaViewCellDelegate?
  
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
    
    //qnaLabelBase
    let qnaLabelBase = UIView()
    qnaLabelBase.backgroundColor = .white
    stackView.addArrangedSubview(qnaLabelBase)
    self.qnaLabelBase = qnaLabelBase

    //questionLabel
    let questionLabel = ActiveLabel()
    questionLabel.font = UIFont.systemFont(ofSize: 14.0)
    questionLabel.textColor = ANIColor.subTitle
    questionLabel.numberOfLines = 0
    questionLabel.enabledTypes = [.hashtag]
    questionLabel.customize { (label) in
      label.hashtagColor = ANIColor.darkblue
    }
    questionLabel.handleHashtagTap { (hashtag) in
      ANINotificationManager.postTapHashtag(contributionKind: KEY_CONTRIBUTION_KIND_QNA, hashtag: hashtag)
    }
    qnaLabelBase.addSubview(questionLabel)
    questionLabel.topToSuperview(offset: 10.0)
    questionLabel.leftToSuperview(offset: 10.0)
    questionLabel.rightToSuperview(offset: -10.0)
    questionLabel.bottomToSuperview()
    self.questionLabel = questionLabel
    
    //qnaImagesViewBase
    let qnaImagesViewBase = UIView()
    qnaImagesViewBase.backgroundColor = .white
    qnaImagesViewBase.isHidden = true
    stackView.addArrangedSubview(qnaImagesViewBase)
    self.qnaImagesViewBase = qnaImagesViewBase
    
    //qnaImagesView
    let qnaImagesView = ANIQnaImagesView()
    qnaImagesViewBase.addSubview(qnaImagesView)
    qnaImagesView.topToBottom(of: questionLabel, offset: 10.0)
    qnaImagesView.leftToSuperview()
    qnaImagesView.rightToSuperview()
    qnaImagesView.height(UIScreen.main.bounds.width / 2 - 30, priority: .defaultHigh)
    qnaImagesView.bottomToSuperview()
    self.qnaImagesView = qnaImagesView
    
    //qnaCommentView
    let qnaCommentView = ANIContributionCommentView()
    qnaCommentView.delegate = self
    stackView.addArrangedSubview(qnaCommentView)
    self.qnaCommentView = qnaCommentView
    
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
    profileImageView.width(32.0)
    profileImageView.height(32.0)
    profileImageView.layer.cornerRadius = profileImageView.constraints[0].constant / 2
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
    loveCountLabel.rightToLeft(of: commentButton, offset: -5.0)
    loveCountLabel.width(25.0)
    loveCountLabel.height(20.0)
    self.loveCountLabel = loveCountLabel
    
    //loveButtonBG
    let loveButtonBG = UIView()
    loveButtonBG.isUserInteractionEnabled = false
    let loveButtonBGtapGesture = UITapGestureRecognizer(target: self, action: #selector(loveButtonBGTapped))
    loveButtonBG.addGestureRecognizer(loveButtonBGtapGesture)
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
    userNameLabel.rightToLeft(of: loveButton, offset: -10)
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
    guard let questionLabel = self.questionLabel,
          let qnaImagesViewBase = self.qnaImagesViewBase,
          let qnaImagesView = self.qnaImagesView,
          let qnaCommentView = self.qnaCommentView,
          let loveButtonBG = self.loveButtonBG,
          let loveButton = self.loveButton,
          let qna = self.qna else { return }
    
    questionLabel.text = qna.qna

    if let qnaImageUrls = qna.qnaImageUrls {
      qnaImagesView.imageUrls = qnaImageUrls
      qnaImagesViewBase.isHidden = false
    } else {
      qnaImagesViewBase.isHidden = true
    }
    
    if qna.comments != nil {
      qnaCommentView.isHidden = false
    } else {
      qnaCommentView.isHidden = true
    }

    if ANISessionManager.shared.isAnonymous {
      loveButtonBG.isUserInteractionEnabled = true
      loveButton.isUserInteractionEnabled = false
    } else {
      loveButtonBG.isUserInteractionEnabled = false
      loveButton.isUserInteractionEnabled = true
    }
    loveButton.isSelected = false
    if let isLoved = qna.isLoved {
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
    guard let qna = self.qna,
          let qnaId = qna.id,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath else { return }
    
    self.loveCount = 0

    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.loveListener = database.collection(KEY_QNAS).document(qnaId).collection(KEY_LOVE_IDS).addSnapshotListener({ (snapshot, error) in
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
                  self.delegate?.loadedQnaIsLoved(indexPath: indexPath, isLoved: true)
                } else {
                  loveButton.isSelected = false
                  self.delegate?.loadedQnaIsLoved(indexPath: indexPath, isLoved: false)
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
    guard let qna = self.qna,
          let qnaId = qna.id else { return }
    
    self.commentCount = 0

    let database = Firestore.firestore()
    DispatchQueue.global().async {
      self.commentListener = database.collection(KEY_QNAS).document(qnaId).collection(KEY_COMMENTS).addSnapshotListener({ (snapshot, error) in
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
    guard let qna = self.qna,
          let qnaId = qna.id,
          let currentUser = ANISessionManager.shared.currentUser,
          let currentUserName = currentUser.userName,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let user = self.user,
          let userId = user.uid,
          currentUserId != userId else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_QNAS).document(qnaId).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        var noti = ""
        
        if let snapshot = snapshot, snapshot.documents.count > 1 {
          noti = "\(currentUserName)さん、他\(snapshot.documents.count - 1)人が「\(qna.qna)」質問を「いいね」しました。"
        } else {
          noti = "\(currentUserName)さんが「\(qna.qna)」質問を「いいね」しました。"
        }
        
        do {
          let date = ANIFunction.shared.getToday()
          let notification = FirebaseNotification(userId: currentUserId, userName: currentUserName, noti: noti, contributionKind: KEY_CONTRIBUTION_KIND_QNA, notiKind: KEY_NOTI_KIND_LOVE, notiId: qnaId, commentId: nil, updateDate: date)
          if let data = try FirebaseEncoder().encode(notification) as? [String: AnyObject] {
            
            database.collection(KEY_USERS).document(userId).collection(KEY_NOTIFICATIONS).document(qnaId).setData(data)
            database.collection(KEY_USERS).document(userId).updateData([KEY_IS_HAVE_UNREAD_NOTI: true])
          }
        } catch let error {
          DLog(error)
        }
      })
    }
  }
  
  //MARK: action
  @objc private func love() {
    guard let qna = self.qna,
          let qnaId = qna.id,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let loveButton = self.loveButton,
          let indexPath = self.indexPath else { return }
    
    let database = Firestore.firestore()
    
    if loveButton.isSelected == true {
      DispatchQueue.global().async {
        let date = ANIFunction.shared.getToday()

        database.collection(KEY_QNAS).document(qnaId).collection(KEY_LOVE_IDS).document(currentUserId).setData([currentUserId: true, KEY_DATE: date])
        
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_QNA_IDS).document(qnaId).setData([KEY_DATE: date])
        
        self.updateNoti()
        ANIFunction.shared.showReviewAlertLove()
        
        self.delegate?.loadedQnaIsLoved(indexPath: indexPath, isLoved: true)
      }
    } else {
      DispatchQueue.global().async {
        database.collection(KEY_QNAS).document(qnaId).collection(KEY_LOVE_IDS).document(currentUserId).delete()
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_QNA_IDS).document(qnaId).delete()
        
        self.delegate?.loadedQnaIsLoved(indexPath: indexPath, isLoved: false)
      }
    }
  }
  
  @objc private func loveButtonBGTapped() {
    self.delegate?.reject()
  }
  
  @objc private func profileImageViewTapped() {
    guard let qna = self.qna else { return }
    
    ANINotificationManager.postProfileImageViewTapped(userId: qna.userId)
  }
  
  @objc private func cellTapped() {
    guard let qna = self.qna,
          let user = self.user else { return }
    
    self.delegate?.cellTapped(qna: qna, user: user)
  }
  
  @objc private func showOption() {
    guard let user = self.user,
          let qna = self.qna,
          let qnaId = qna.id else { return }
    
    let contentType: ContentType = .qna
    
    if let currentUserId = ANISessionManager.shared.currentUserUid, user.uid == currentUserId {
      self.delegate?.popupOptionView(isMe: true, contentType: contentType, id: qnaId)
    } else {
      self.delegate?.popupOptionView(isMe: false, contentType: contentType, id: qnaId)
    }
  }
}


//MARK: ANIButtonViewDelegate
extension ANIQnaViewCell: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.loveButton {
      love()
    }
  }
}

//MARK: ANIContributionCommentViewDelegate
extension ANIQnaViewCell: ANIContributionCommentViewDelegate {
  func loadedCommentUser(user: FirebaseUser) {
    self.delegate?.loadedQnaUser(user: user)
  }
}

//MARK: data
extension ANIQnaViewCell {
  private func loadUser() {
    guard let qna = self.qna else { return }
    
    DispatchQueue.global().async {
      let database = Firestore.firestore()
      database.collection(KEY_USERS).document(qna.userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          self.user = user
          self.delegate?.loadedQnaUser(user: user)
        } catch let error {
          DLog(error)
        }
      })
    }
  }
}
