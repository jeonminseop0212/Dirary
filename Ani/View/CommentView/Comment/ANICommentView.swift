//
//  CommentView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/21.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase

protocol ANICommentViewDelegate {
  func reject()
  func popupOptionView(isMe: Bool, contentId: String, commentId: String)
  func commentCellTapped(comment: FirebaseComment, user: FirebaseUser)
  func loadedComments()
}

class ANICommentView: UIView {
  
  private weak var commentTableView: UITableView?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  var commentMode: CommentMode?
  
  var story: FirebaseStory? {
    didSet {
      guard let story = self.story,
            let storyId = story.id else { return }
      
      contentId = storyId
      loadComment()
    }
  }
  var qna: FirebaseQna? {
    didSet {
      guard let qna = self.qna,
            let qnaId = qna.id else { return }
      
      contentId = qnaId
      loadComment()
    }
  }
  private var contentId: String?
  
  private var comments = [FirebaseComment]()
  private var users = [FirebaseUser]()
  
  private var parentCommets = [FirebaseComment]()
  
  var selectedComment: FirebaseComment?
  
  private var originalScrollY: CGFloat = 0.0
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  private var isCellTapped: Bool = false
  
  var delegate: ANICommentViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //commentTableView
    let commentTableView = UITableView()
    commentTableView.separatorStyle = .none
    commentTableView.alpha = 0.0
    let contentCellId = NSStringFromClass(ANICommentContentCell.self)
    commentTableView.register(ANICommentContentCell.self, forCellReuseIdentifier: contentCellId)
    let commentCellId = NSStringFromClass(ANICommentCell.self)
    commentTableView.register(ANICommentCell.self, forCellReuseIdentifier: commentCellId)
    let parentCommentCellId = NSStringFromClass(ANIParentCommentCell.self)
    commentTableView.register(ANIParentCommentCell.self, forCellReuseIdentifier: parentCommentCellId)
    commentTableView.rowHeight = UITableView.automaticDimension
    commentTableView.dataSource = self
    commentTableView.delegate = self
    addSubview(commentTableView)
    commentTableView.edgesToSuperview()
    self.commentTableView = commentTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(deleteComment: self, selector: #selector(deleteComment))
  }
  
  @objc private func deleteComment(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let commentTableView = self.commentTableView else { return }
    
    for (index, comment) in comments.enumerated() {
      if comment.id == id {
        commentTableView.beginUpdates()
        comments.remove(at: index)
        let indexPath: IndexPath = [0, index + 1]
        commentTableView.deleteRows(at: [indexPath], with: .automatic)
        commentTableView.endUpdates()
      }
    }
  }
  
  private func isBlockComment(comment: FirebaseComment) -> Bool {
    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(comment.userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(comment.userId) {
      return true
    }
    
    return false
  }
  
  private func scrollTableViewIfNeed() {
    guard let selectedComment = self.selectedComment,
          let commentTableView = self.commentTableView else { return }
    
    for (index, comment) in comments.enumerated() {
      if comment.id == selectedComment.id {
        isCellTapped = true
        //delayをせ設定しないとcommentBarのheightが変わる前にscrollしてscrollポイントが少しずれる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          commentTableView.scrollToRow(at: IndexPath(row: index + 1, section: 0), at: .bottom, animated: true)
        }
      }
    }
  }
  
  private func loadedComments() {
    guard let commentTableView = self.commentTableView,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    commentTableView.reloadData()
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      activityIndicatorView.stopAnimating()
      
      UIView.animate(withDuration: 0.2, animations: {
        commentTableView.alpha = 1.0
      }, completion: { (complete) in
        self.delegate?.loadedComments()
        self.scrollTableViewIfNeed()
      })
    }
  }
}

//MARK: UITableViewDataSource
extension ANICommentView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return comments.count + 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let commentMode = self.commentMode else { return UITableViewCell() }

    if indexPath.row == 0 {
      let contentCellId = NSStringFromClass(ANICommentContentCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: contentCellId, for: indexPath) as! ANICommentContentCell
      
      switch commentMode {
      case .story:
          if let story = self.story {
            cell.content = story.story
          }
      case .qna:
        if let qna = self.qna {
          cell.content = qna.qna
        }
      }
      
      return cell
    } else if comments[indexPath.row - 1].parentCommentId != nil {
      let parentCommentCellId = NSStringFromClass(ANIParentCommentCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: parentCommentCellId, for: indexPath) as! ANIParentCommentCell
      cell.delegate = self
      
      if users.contains(where: { $0.uid == comments[indexPath.row - 1].userId }) {
        for user in users {
          if comments[indexPath.row - 1].userId == user.uid {
            cell.user = user
            break
          }
        }
      } else {
        cell.user = nil
      }
      if users.contains(where: { $0.uid == comments[indexPath.row - 1].parentCommentUserId }) {
        for user in users {
          if comments[indexPath.row - 1].parentCommentUserId == user.uid {
            cell.parentCommentUser = user
            break
          }
        }
      } else {
        cell.parentCommentUser = nil
      }
      if parentCommets.contains(where: { $0.id == comments[indexPath.row - 1].parentCommentId}) {
        for parentCommet in parentCommets {
          if comments[indexPath.row - 1].parentCommentId == parentCommet.id {
            cell.parentComment = parentCommet
          }
        }
      } else {
        cell.parentComment = nil
      }
      cell.indexPath = indexPath.row
      cell.commentMode = commentMode
      cell.contentId = contentId
      cell.comment = comments[indexPath.row - 1]
      
      return cell
    } else {
      let commentCellId = NSStringFromClass(ANICommentCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: commentCellId, for: indexPath) as! ANICommentCell
      cell.delegate = self
      
      if users.contains(where: { $0.uid == comments[indexPath.row - 1].userId }) {
        for user in users {
          if comments[indexPath.row - 1].userId == user.uid {
            cell.user = user
            break
          }
        }
      } else {
        cell.user = nil
      }
      cell.indexPath = indexPath.row
      cell.commentMode = commentMode
      cell.contentId = contentId
      cell.comment = comments[indexPath.row - 1]

      return cell
    }
  }
}

//MARK: UITableViewDelegate
extension ANICommentView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if !comments.isEmpty {
      if let cell = cell as? ANICommentCell {
        cell.unobserveLove()
      }
      if let cell = cell as? ANIParentCommentCell {
        cell.unobserveLove()
      }
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    self.cellHeight[indexPath] = cell.frame.size.height
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    if let height = self.cellHeight[indexPath] {
      return height
    } else {
      return UITableView.automaticDimension
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let scrollY = scrollView.contentOffset.y
    if (originalScrollY - scrollY) > 50 && !isCellTapped {
      ANINotificationManager.postViewScrolled()
    }
  }
  
  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    isCellTapped = false
  }
  
  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    originalScrollY = scrollView.contentOffset.y
    isCellTapped = false
  }
}

//MARK: ANICommentCellDelegate, ANIParentCommentCellDelegate
extension ANICommentView: ANICommentCellDelegate, ANIParentCommentCellDelegate {
  func commentCellTapped(comment: FirebaseComment, user: FirebaseUser, indexPath: Int) {
    guard let commentTableView = self.commentTableView else { return }
    
    self.delegate?.commentCellTapped(comment: comment, user: user)
    
    isCellTapped = true
    //delayをせ設定しないとcommentBarのheightが変わる前にscrollしてscrollポイントが少しずれる
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      commentTableView.scrollToRow(at: IndexPath(row: indexPath, section: 0), at: .bottom, animated: true)
    }
  }
  
  func reject() {
    self.delegate?.reject()
  }

  func popupOptionView(isMe: Bool, contentId: String, commentId: String) {
    self.delegate?.popupOptionView(isMe: isMe, contentId: contentId, commentId: commentId)
  }
  
  func loadedCommentIsLoved(indexPath: Int, isLoved: Bool) {
    if !self.comments.isEmpty {
      var comment = self.comments[indexPath - 1]
      comment.isLoved = isLoved
      self.comments[indexPath - 1] = comment
    }
  }
  
  func loadedCommentUser(user: FirebaseUser) {
    self.users.append(user)
  }
}

//MARK: data
extension ANICommentView {
  private func loadComment() {
    guard let commentMode = self.commentMode,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    activityIndicatorView.startAnimating()
    
    let database = Firestore.firestore()
    
    if !self.users.isEmpty {
      self.users.removeAll()
    }
    
    var collection = ""
    var documentId = ""
    
    switch commentMode {
    case .story:
      guard let story = self.story,
            let storyId = story.id else { return }
      
      collection = KEY_STORIES
      documentId = storyId
    case .qna:
      guard let qna = self.qna,
            let qnaId = qna.id else { return }
      
      collection = KEY_QNAS
      documentId = qnaId
    }
    
    DispatchQueue.global().async {
      database.collection(collection).document(documentId).collection(KEY_COMMENTS).order(by: KEY_DATE, descending: false).addSnapshotListener({ (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        var count = 0
        var newComments = [FirebaseComment]()
        
        snapshot.documentChanges.forEach({ (diff) in
          if diff.type == .added {
            do {
              count = count + 1
              
              let comment = try FirestoreDecoder().decode(FirebaseComment.self, from: diff.document.data())
              
              if !self.isBlockComment(comment: comment) {
                self.comments.append(comment)
                newComments.append(comment)
              }
              
              if count == snapshot.documentChanges.count {
                DispatchQueue.main.async {
                  var needLoadParentCommentIds = [String]()
                  for newComment in newComments {
                    if let parentCommentId = newComment.parentCommentId,
                      !self.parentCommets.contains(where: { $0.id == parentCommentId }),
                      !needLoadParentCommentIds.contains(where: { $0 == parentCommentId }){
                      needLoadParentCommentIds.append(parentCommentId)
                    }
                  }
                  self.loadParentComment(parentCommentIds: needLoadParentCommentIds)
                }
              }
            } catch let error {
              DLog(error)
            }
          }
        })
        
        if snapshot.documents.isEmpty {
          DispatchQueue.main.async {
            self.loadedComments()
          }
        }
      })
    }
  }
  
  private func loadParentComment(parentCommentIds: [String]) {
    guard let commentMode = self.commentMode else { return }
    
    let database = Firestore.firestore()
    
    var collection = ""
    var documentId = ""
    
    switch commentMode {
    case .story:
      guard let story = self.story,
            let storyId = story.id else { return }
      
      collection = KEY_STORIES
      documentId = storyId
    case .qna:
      guard let qna = self.qna,
            let qnaId = qna.id else { return }
      
      collection = KEY_QNAS
      documentId = qnaId
    }
    
    var count = 0
    
    DispatchQueue.global().async {
      for parentCommentId in parentCommentIds {
        database.collection(collection).document(documentId).collection(KEY_COMMENTS).document(parentCommentId).getDocument { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            
            return
          }
          
          guard let snapshot = snapshot else { return }
          
          if let data = snapshot.data() {
            do {
              let comment = try FirestoreDecoder().decode(FirebaseComment.self, from: data)
              self.parentCommets.append(comment)
              
              count = count + 1
              
              if parentCommentIds.count == count {
                DispatchQueue.main.async {
                  self.loadedComments()
                }
              }
            } catch let error {
              DLog(error)
            }
          } else {
            count = count + 1

            if parentCommentIds.count == count {
              DispatchQueue.main.async {
                self.loadedComments()
              }
            }
          }
        }
      }
      
      if parentCommentIds.isEmpty {
        DispatchQueue.main.async {
          self.loadedComments()
        }
      }
    }
  }
}
