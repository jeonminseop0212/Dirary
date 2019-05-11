//
//  ANIStoryCommentView.swift
//  Ani
//
//  Created by jeonminseop on 2019/02/19.
//  Copyright © 2019 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import FirebaseFirestore
import CodableFirebase

protocol ANIContributionCommentViewDelegate {
  func loadedCommentUser(user: FirebaseUser)
}

class ANIContributionCommentView: UIView {
  
  private weak var lineView: UIView?
  private weak var titleLabel: UIView?
  
  private weak var stackView: UIStackView?
  
  private weak var commentOneLabelBase: UIView?
  private weak var commentOneLabel: UILabel?
  private weak var commentOneUserLabel: UILabel?
  private weak var deleteCommentLabel: UILabel?
  
  private weak var commentTwoLabelBase: UIView?
  private weak var commentLineBaseWidthConstraint: Constraint?
  private let COMMENT_LINE_BASE_WIDHT: CGFloat = 20.0
  private weak var commentLineBase: UIView?
  private weak var commentLine: UIView?
  private weak var commentTwoLabel: UILabel?
  private weak var commentTwoUserLabel: UILabel?
  
  var story: FirebaseStory? {
    didSet {
      guard let story = self.story,
            let comments = story.comments else { return }
      
      if comments[0].id != "" {
        if commentOneUser == nil {
          loadCommentOneUser()
        }
      }
      if commentTwoUser == nil {
        loadCommentTwoUser()
      }
      
      reloadLayout()
    }
  }
  
  var qna: FirebaseQna? {
    didSet {
      guard let qna = self.qna,
            let comments = qna.comments else { return }
      
      if comments[0].id != "" {
        if commentOneUser == nil {
          loadCommentOneUser()
        }
      }
      if commentTwoUser == nil {
        loadCommentTwoUser()
      }
      
      reloadLayout()
    }
  }
  
  var commentOneUser: FirebaseUser? {
    didSet {
      reloadCommentOneUserLayout()
    }
  }
  var commentTwoUser: FirebaseUser? {
    didSet {
      reloadCommentTwoUserLayout()
    }
  }
  
  var delegate: ANIContributionCommentViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = .white
    
    //lineView
    let lineView = UIView()
    lineView.backgroundColor = ANIColor.bg
    addSubview(lineView)
    lineView.leftToSuperview(offset: 14.0)
    lineView.rightToSuperview(offset: -14.0, priority: .defaultHigh)
    lineView.height(0.5)
    self.lineView = lineView
    
    //titleLabel
    let titleLabel = UILabel()
    titleLabel.text = "コメント"
    titleLabel.font = UIFont.systemFont(ofSize: 11.0)
    titleLabel.textColor = ANIColor.gray
    titleLabel.textAlignment = .center
    titleLabel.backgroundColor = .white
    addSubview(titleLabel)
    titleLabel.centerXToSuperview()
    titleLabel.topToSuperview(offset: 5.0)
    titleLabel.width(62.0)
    self.titleLabel = titleLabel
    
    lineView.centerY(to: titleLabel)
    
    //stackView
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.distribution = .equalSpacing
    stackView.spacing = 0.0
    addSubview(stackView)
    stackView.topToBottom(of: titleLabel)
    stackView.leftToSuperview()
    stackView.rightToSuperview()
    stackView.bottomToSuperview(priority: .defaultHigh)
    self.stackView = stackView
    
    //commentOneLabelBase
    let commentOneLabelBase = UIView()
    commentOneLabelBase.backgroundColor = .white
    stackView.addArrangedSubview(commentOneLabelBase)
    self.commentOneLabelBase = commentOneLabelBase
    
    //commentOneLabel
    let commentOneLabel = UILabel()
    commentOneLabel.text = " "
    commentOneLabel.font = UIFont.systemFont(ofSize: 14.0)
    commentOneLabel.numberOfLines = 0
    commentOneLabel.textColor = ANIColor.subTitle
    commentOneLabelBase.addSubview(commentOneLabel)
    commentOneLabel.topToSuperview(offset: 5.0)
    commentOneLabel.leftToSuperview(offset: 10.0)
    commentOneLabel.rightToSuperview(offset: -10.0, priority: .defaultHigh)
    commentOneLabel.height(max: 35.0)
    self.commentOneLabel = commentOneLabel
    
    //commentOneUserLabel
    let commentOneUserLabel = UILabel()
    commentOneUserLabel.text = " "
    commentOneUserLabel.numberOfLines = 1
    commentOneUserLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    commentOneLabelBase.addSubview(commentOneUserLabel)
    commentOneUserLabel.topToBottom(of: commentOneLabel, offset: 2.0)
    commentOneUserLabel.leftToSuperview(offset: 10.0)
    commentOneUserLabel.rightToSuperview(offset: -10.0, priority: .defaultHigh)
    commentOneUserLabel.bottomToSuperview()
    self.commentOneUserLabel = commentOneUserLabel
    
    //deleteCommentLabel
    let deleteCommentLabel = UILabel()
    deleteCommentLabel.backgroundColor = .white
    deleteCommentLabel.text = "削除されたコメントです。"
    deleteCommentLabel.isHidden = true
    deleteCommentLabel.font = UIFont.systemFont(ofSize: 14.0)
    deleteCommentLabel.textColor = ANIColor.subTitle
    deleteCommentLabel.numberOfLines = 1
    commentOneLabelBase.addSubview(deleteCommentLabel)
    deleteCommentLabel.topToSuperview()
    deleteCommentLabel.left(to: commentOneLabel)
    deleteCommentLabel.right(to: commentOneLabel)
    deleteCommentLabel.bottomToSuperview()
    self.deleteCommentLabel = deleteCommentLabel
    
    //commentTwoLabelBase
    let commentTwoLabelBase = UIView()
    commentTwoLabelBase.backgroundColor = .white
    stackView.addArrangedSubview(commentTwoLabelBase)
    self.commentTwoLabelBase = commentTwoLabelBase
    
    //commentLineBase
    let commentLineBase = UIView()
    commentLineBase.backgroundColor = .white
    commentTwoLabelBase.addSubview(commentLineBase)
    commentLineBase.edgesToSuperview(excluding: .right)
    commentLineBaseWidthConstraint = commentLineBase.width(COMMENT_LINE_BASE_WIDHT)
    self.commentLineBase = commentLineBase
    
    //commentLine
    let commentLine = UIView()
    commentLine.backgroundColor = ANIColor.bg
    commentLineBase.addSubview(commentLine)
    commentLine.topToSuperview(offset: 5.0)
    commentLine.rightToSuperview()
    commentLine.bottomToSuperview()
    commentLine.width(2.0)
    self.commentLine = commentLine
    
    //commentTwoLabel
    let commentTwoLabel = UILabel()
    commentTwoLabel.text = " "
    commentTwoLabel.font = UIFont.systemFont(ofSize: 14.0)
    commentTwoLabel.numberOfLines = 0
    commentTwoLabel.textColor = ANIColor.subTitle
    commentTwoLabelBase.addSubview(commentTwoLabel)
    commentTwoLabel.topToSuperview(offset: 5.0)
    commentTwoLabel.leftToRight(of: commentLineBase, offset: 10.0)
    commentTwoLabel.rightToSuperview(offset: -10.0, priority: .defaultHigh)
    commentTwoLabel.height(max: 35.0)
    self.commentTwoLabel = commentTwoLabel
    
    //commentTwoUserLabel
    let commentTwoUserLabel = UILabel()
    commentTwoUserLabel.text = " "
    commentTwoUserLabel.numberOfLines = 1
    commentTwoUserLabel.font = UIFont.boldSystemFont(ofSize: 13.0)
    commentTwoLabelBase.addSubview(commentTwoUserLabel)
    commentTwoUserLabel.topToBottom(of: commentTwoLabel, offset: 2.0)
    commentTwoUserLabel.leftToRight(of: commentLineBase, offset: 10.0)
    commentTwoUserLabel.rightToSuperview(offset: -10.0, priority: .defaultHigh)
    commentTwoUserLabel.bottomToSuperview()
    self.commentTwoUserLabel = commentTwoUserLabel
  }
  
  private func reloadLayout() {
    guard let commentOneLabel = self.commentOneLabel,
          let deleteCommentLabel = self.deleteCommentLabel,
          let commentTwoLabelBase = self.commentTwoLabelBase,
          let commentLineBase = self.commentLineBase,
          let commentLineBaseWidthConstraint = self.commentLineBaseWidthConstraint,
          let commentTwoLabel = self.commentTwoLabel else { return }
    
    var contentComments = [FirebaseComment]()
    if let story = self.story, let comments = story.comments {
      contentComments = comments
    }
    if let qna = self.qna, let comments = qna.comments {
      contentComments = comments
    }
    
    if contentComments.count > 1 {
      commentTwoLabelBase.isHidden = false
      
      if contentComments[1].parentCommentId != nil {
        commentLineBase.isHidden = false
        commentLineBaseWidthConstraint.constant = COMMENT_LINE_BASE_WIDHT
      } else {
        commentLineBase.isHidden = true
        commentLineBaseWidthConstraint.constant = 0.0
      }
      
      commentOneLabel.text = contentComments[0].comment
      commentTwoLabel.text = contentComments[1].comment
    } else {
      commentTwoLabelBase.isHidden = true
      
      commentOneLabel.text = contentComments[0].comment
    }
    
    if contentComments[0].id == "" {
      deleteCommentLabel.isHidden = false
    } else {
      deleteCommentLabel.isHidden = true
    }
    
    self.layoutIfNeeded()
  }
  
  private func reloadCommentOneUserLayout() {
    guard let commentOneUser = self.commentOneUser,
          let commentOneUserLabel = self.commentOneUserLabel else { return }
    
    commentOneUserLabel.text = commentOneUser.userName
  }
  
  private func reloadCommentTwoUserLayout() {
    guard let commentTwoUser = self.commentTwoUser,
          let commentTwoUserLabel = self.commentTwoUserLabel else { return }
    
    commentTwoUserLabel.text = commentTwoUser.userName
  }
}

//MARK: data
extension ANIContributionCommentView {
  private func loadCommentOneUser() {
    var contentComments = [FirebaseComment]()
    if let story = self.story, let comments = story.comments {
      contentComments = comments
    }
    if let qna = self.qna, let comments = qna.comments {
      contentComments = comments
    }
    
    let database = Firestore.firestore()
    
    if !contentComments.isEmpty {
      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(contentComments[0].userId).getDocument(completion: { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            
            return
          }
          
          guard let snapshot = snapshot, let data = snapshot.data() else { return }
          
          do {
            let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
            
            self.delegate?.loadedCommentUser(user: user)
            
            DispatchQueue.main.async {
              self.commentOneUser = user
            }
          } catch let error {
            DLog(error)
          }
        })
      }
    }
  }
  
  private func loadCommentTwoUser() {
    var contentComments = [FirebaseComment]()
    if let story = self.story, let comments = story.comments {
      contentComments = comments
    }
    if let qna = self.qna, let comments = qna.comments {
      contentComments = comments
    }
    
    let database = Firestore.firestore()
    
    if contentComments.count > 1 {
      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(contentComments[1].userId).getDocument(completion: { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            
            return
          }
          
          guard let snapshot = snapshot, let data = snapshot.data() else { return }
          
          do {
            let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
            
            self.delegate?.loadedCommentUser(user: user)
            
            DispatchQueue.main.async {
              self.commentTwoUser = user
            }
          } catch let error {
            DLog(error)
          }
        })
      }
    }
  }
}
