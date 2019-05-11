//
//  ANIRecuruitView.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/06.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import TinyConstraints

protocol ANIQnaViewDelegate {
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
}

class ANIQnaView: UIView {
  
  private weak var reloadView: ANIReloadView?
  
  private weak var qnaTableView: UITableView?
  
  private weak var refreshControl: UIRefreshControl?
  
  private let NEW_QNA_BUTTON_OFFSET: CGFloat = ANICommunityViewController.NAVIGATION_BAR_HEIGHT + 7.0
  private let NEW_QNA_BUTTON_HEIGHT: CGFloat = 30.0
  private var newQnaButtonTopConstraint: Constraint?
  private weak var newQnaButton: ANIAreaButtonView?
  private weak var arrowImageView: UIImageView?
  private weak var newQnaLabel: UILabel?
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  private var qnas = [FirebaseQna]()
  private var users = [FirebaseUser]()
  
  var isCellSelected: Bool = false
  
  private var lastQna: QueryDocumentSnapshot?
  private var isLastQnaPage: Bool = false
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  private var isLoadedFirstData: Bool = false
  private var isNewQna: Bool = false
  private var isShowNewQnaButton: Bool = false
  
  private var scrollBeginingPoint: CGPoint?
  
  var delegate: ANIQnaViewDelegate?
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  static var shared: ANIQnaView?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    loadQna(sender: nil)
    setupNotifications()
    observeQna()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.bg
    
    //reloadView
    let reloadView = ANIReloadView()
    reloadView.alpha = 0.0
    reloadView.messege = "Q&Aがありません。"
    reloadView.delegate = self
    addSubview(reloadView)
    reloadView.dropShadow()
    reloadView.centerInSuperview()
    reloadView.leftToSuperview(offset: 50.0)
    reloadView.rightToSuperview(offset: -50.0)
    self.reloadView = reloadView
    
    //tableView
    let tableView = UITableView()
    tableView.contentInset = UIEdgeInsets(top: ANICommunityViewController.NAVIGATION_BAR_HEIGHT, left: 0, bottom: 0, right: 0)
    tableView.scrollIndicatorInsets  = UIEdgeInsets(top: ANICommunityViewController.NAVIGATION_BAR_HEIGHT, left: 0, bottom: 0, right: 0)
    tableView.backgroundColor = ANIColor.bg
    let id = NSStringFromClass(ANIQnaViewCell.self)
    tableView.register(ANIQnaViewCell.self, forCellReuseIdentifier: id)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorStyle = .none
    tableView.alpha = 0.0
    tableView.rowHeight = UITableView.automaticDimension
    let refreshControl = UIRefreshControl()
    refreshControl.backgroundColor = .clear
    refreshControl.tintColor = ANIColor.moreDarkGray
    refreshControl.addTarget(self, action: #selector(reloadData(sender:)), for: .valueChanged)
    tableView.addSubview(refreshControl)
    self.refreshControl = refreshControl
    addSubview(tableView)
    tableView.edgesToSuperview()
    self.qnaTableView = tableView
    
    //newQnaButton
    let newQnaButton = ANIAreaButtonView()
    newQnaButton.base?.backgroundColor = ANIColor.emerald
    newQnaButton.baseCornerRadius = NEW_QNA_BUTTON_HEIGHT / 2
    newQnaButton.dropShadow(opacity: 0.1)
    newQnaButton.delegate = self
    addSubview(newQnaButton)
    newQnaButtonTopConstraint = newQnaButton.topToSuperview(offset: -NEW_QNA_BUTTON_HEIGHT, usingSafeArea: true)
    newQnaButton.centerXToSuperview()
    newQnaButton.width(160.0)
    newQnaButton.height(NEW_QNA_BUTTON_HEIGHT)
    self.newQnaButton = newQnaButton
    
    //newQnaLabel
    let newQnaLabel = UILabel()
    newQnaLabel.text = "新しいQ&A"
    newQnaLabel.textAlignment = .center
    newQnaLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
    newQnaLabel.textColor = .white
    newQnaButton.addContent(newQnaLabel)
    newQnaLabel.centerXToSuperview(offset: 8.0)
    newQnaLabel.centerYToSuperview()
    self.newQnaLabel = newQnaLabel
    
    //arrowImageView
    let arrowImageView = UIImageView()
    arrowImageView.image = UIImage(named: "arrow")
    arrowImageView.contentMode = .scaleAspectFit
    newQnaButton.addContent(arrowImageView)
    arrowImageView.centerYToSuperview()
    arrowImageView.rightToLeft(of: newQnaLabel, offset: -5.0)
    arrowImageView.width(12.0)
    arrowImageView.height(11.0)
    self.arrowImageView = arrowImageView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  static func endRefresh() {
    guard let shared = ANIQnaView.shared,
          let refreshControl = shared.refreshControl,
          let qnaTableView = shared.qnaTableView else { return }
    
    refreshControl.endRefreshing()

    let topInset = ANICommunityViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    if qnaTableView.contentOffset.y + topInset < 0 {
      qnaTableView.scrollToRow(at: [0, 0], at: .top, animated: false)
    }
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    ANINotificationManager.receive(logout: self, selector: #selector(reloadQna))
    ANINotificationManager.receive(login: self, selector: #selector(reloadQna))
    ANINotificationManager.receive(communityTabTapped: self, selector: #selector(scrollToTop))
    ANINotificationManager.receive(deleteQna: self, selector: #selector(deleteQna))
  }
  
  @objc private func reloadData(sender:  UIRefreshControl?) {
    self.hideNewQnaButton()
    self.isNewQna = false
    
    self.loadQna(sender: sender)
  }
  
  @objc private func reloadQna() {
    guard let qnaTableView = self.qnaTableView else { return }
    
    self.hideNewQnaButton()
    self.isNewQna = false
    
    qnaTableView.alpha = 0.0
    
    loadQna(sender: nil)
  }
  
  @objc private func scrollToTop() {
    guard let qnaTableView = qnaTableView,
          !qnas.isEmpty,
          isCellSelected else { return }
    
    qnaTableView.scrollToRow(at: [0, 0], at: .top, animated: true)
  }
  
  @objc private func deleteQna(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let qnaTableView = self.qnaTableView else { return }
    
    for (index, qna) in qnas.enumerated() {
      if qna.id == id {
        qnas.remove(at: index)
        
        if !qnas.isEmpty {
          qnaTableView.beginUpdates()
          let indexPath: IndexPath = [0, index]
          qnaTableView.deleteRows(at: [indexPath], with: .automatic)
          qnaTableView.endUpdates()
        } else {
          qnaTableView.reloadData()
          qnaTableView.alpha = 0.0
          showReloadView(sender: nil)
        }
      }
    }
  }
  
  private func showReloadView(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView,
          let qnaTableView = self.qnaTableView else { return }
    
    activityIndicatorView.stopAnimating()
    
    qnaTableView.reloadData()
    qnaTableView.alpha = 0.0

    if let sender = sender {
      sender.endRefreshing()
    }
    
    UIView.animate(withDuration: 0.2, animations: {
      reloadView.alpha = 1.0
    })
    
    self.isLoading = false
  }
  
  private func isBlockQna(qna: FirebaseQna) -> Bool {
    guard let currentUserUid = ANISessionManager.shared.currentUserUid else { return false }

    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(qna.userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(qna.userId) {
      return true
    }
    if let hideUserIds = qna.hideUserIds, hideUserIds.contains(currentUserUid) {
      return true
    }
    
    return false
  }
  
  private func observeQna() {
    let database = Firestore.firestore()
    
    database.collection(KEY_QNAS).order(by: KEY_DATE, descending: true).limit(to: 1).addSnapshotListener { (snapshot, error) in
      if let error = error {
        DLog("stories observe error \(error)")
        return
      }
      
      guard let snapshot = snapshot else { return }
      
      snapshot.documentChanges.forEach({ (diff) in
        if diff.type == .added && self.isLoadedFirstData {
          self.isNewQna = true
          self.showNewQnaButton()
        }
      })
    }
  }
  
  private func showNewQnaButton() {
    guard let newQnaButtonTopConstraint = self.newQnaButtonTopConstraint,
          isNewQna,
          !isShowNewQnaButton else { return }
    
    isShowNewQnaButton = true
    
    newQnaButtonTopConstraint.constant = self.NEW_QNA_BUTTON_OFFSET
    
    UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
      self.layoutIfNeeded()
    }, completion: nil)
  }
  
  private func hideNewQnaButton() {
    guard let newQnaButtonTopConstraint = self.newQnaButtonTopConstraint,
          isNewQna,
          isShowNewQnaButton else { return }
    
    isShowNewQnaButton = false
    
    newQnaButtonTopConstraint.constant = -self.NEW_QNA_BUTTON_HEIGHT
    
    UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
      self.layoutIfNeeded()
    }, completion: nil)
  }
}

//MARK: UITableViewDataSource
extension ANIQnaView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return qnas.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let id = NSStringFromClass(ANIQnaViewCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ANIQnaViewCell
    cell.delegate = self

    if !qnas.isEmpty && qnas.count > indexPath.row {
      if users.contains(where: { $0.uid == qnas[indexPath.row].userId }) {
        for user in users {
          if qnas[indexPath.row].userId == user.uid {
            cell.user = user
            break
          }
        }
      } else {
        cell.user = nil
      }
      
      if let comments = qnas[indexPath.row].comments {
        var commentUsersTemp = [FirebaseUser?]()
        for comment in comments {
          if users.contains(where: { $0.uid == comment.userId }) {
            for user in users {
              if comment.userId == user.uid {
                commentUsersTemp.append(user)
                break
              }
            }
          } else {
            commentUsersTemp.append(nil)
          }
        }
        
        cell.commentUsers = commentUsersTemp
      } else {
        cell.commentUsers = nil
      }
      
      cell.indexPath = indexPath.row
      cell.qna = qnas[indexPath.row]
    }
    
    return cell
  }
}

//MARK: UITableViewDelegate
extension ANIQnaView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let cell = cell as? ANIQnaViewCell {
      cell.unobserveLove()
      cell.unobserveComment()
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let element = self.qnas.count - COUNT_LAST_CELL
    if !isLoading, indexPath.row >= element {
      loadMoreQna(sender: nil)
    }
    
    self.cellHeight[indexPath] = cell.frame.size.height
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    if let height = self.cellHeight[indexPath] {
      return height
    } else {
      return UITableView.automaticDimension
    }
  }
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    scrollBeginingPoint = scrollView.contentOffset
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    //new story button show or hide
    if let scrollBeginingPoint = self.scrollBeginingPoint {
      if scrollBeginingPoint.y < scrollView.contentOffset.y {
        hideNewQnaButton()
      } else {
        showNewQnaButton()
      }
    }
  }
}

//MARK: ANIQnaViewCellDelegate
extension ANIQnaView: ANIQnaViewCellDelegate {
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.delegate?.popupOptionView(isMe: isMe, contentType: contentType, id: id)
  }
  
  func cellTapped(qna: FirebaseQna, user: FirebaseUser) {
  }
  
  func reject() {
    self.delegate?.reject()
  }
  
  func loadedQnaIsLoved(indexPath: Int, isLoved: Bool) {
    if qnas.count > indexPath {
      var qna = self.qnas[indexPath]
      qna.isLoved = isLoved
      self.qnas[indexPath] = qna
    }
  }
  
  func loadedQnaUser(user: FirebaseUser) {
    self.users.append(user)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIQnaView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    guard let qnaTableView = self.qnaTableView,
          let refreshControl = self.refreshControl else { return }
    
    hideNewQnaButton()
    isNewQna = false
    
    refreshControl.beginRefreshing()
    let offsetY = 60 + ANICommunityViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    qnaTableView.setContentOffset(CGPoint(x: 0.0, y: -offsetY), animated: true)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.loadQna(sender: refreshControl)
    }
  }
}

//MARK: ANIReloadViewDelegate
extension ANIQnaView: ANIReloadViewDelegate {
  func reloadButtonTapped() {
    hideNewQnaButton()
    isNewQna = false
    
    loadQna(sender: nil)
  }
}

//MARK: data
extension ANIQnaView {
  @objc private func loadQna(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView else { return }
    
    reloadView.alpha = 0.0
    
    if !self.qnas.isEmpty {
      self.qnas.removeAll()
    }
    if !self.users.isEmpty {
      self.users.removeAll()
    }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastQnaPage = false

      database.collection(KEY_QNAS).order(by: KEY_DATE, descending: true).limit(to: 25).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastQna = snapshot.documents.last else {
                if !self.qnas.isEmpty {
                  self.qnas.removeAll()
                }
                
                self.isLoading = false
                
                self.showReloadView(sender: sender)
                return }
        
        self.lastQna = lastQna
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: document.data())
            if !self.isBlockQna(qna: qna) {
              self.qnas.append(qna)
            }
            
            if index + 1 == snapshot.documents.count {
              if self.qnas.isEmpty {
                self.loadMoreQna(sender: sender)
              } else {
                self.loadQnaComment(qnas: self.qnas, sender: sender)
              }
            }
          } catch let error {
            DLog(error)
            
            if index + 1 == snapshot.documents.count {
              if self.qnas.isEmpty {
                self.loadMoreQna(sender: sender)
              } else {
                self.loadQnaComment(qnas: self.qnas, sender: sender)
              }
            }
          }
        }
      })
    }
  }
  
  private func loadMoreQna(sender: UIRefreshControl?) {
    guard let lastQna = self.lastQna,
          !isLoading,
          !isLastQnaPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_QNAS).order(by: KEY_DATE, descending: true).start(afterDocument: lastQna).limit(to: 25).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastQna = snapshot.documents.last else {
          self.isLastQnaPage = true
          self.isLoading = false
          
          if self.qnas.isEmpty {
            self.showReloadView(sender: sender)
          }
          return
        }
        
        self.lastQna = lastQna
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: document.data())
            if !self.isBlockQna(qna: qna) {
              self.qnas.append(qna)
            }
            
            if index + 1 == snapshot.documents.count {
              if self.qnas.isEmpty {
                self.loadMoreQna(sender: sender)
              } else {
                self.loadQnaComment(qnas: self.qnas, sender: sender)
              }
            }
          } catch let error {
            DLog(error)
            
            if index + 1 == snapshot.documents.count {
              if self.qnas.isEmpty {
                self.loadMoreQna(sender: sender)
              } else {
                self.loadQnaComment(qnas: self.qnas, sender: sender)
              }
            }
          }
        }
      })
    }
  }
  
  private func loadQnaComment(qnas: [FirebaseQna], sender: UIRefreshControl?) {
    let database = Firestore.firestore()
    
    var count = 0
    
    for (index, qna) in qnas.enumerated() {
      var commentsTemp = [FirebaseComment]()
      
      guard let qnaId = qna.id else { return }
      
      database.collection(KEY_QNAS).document(qnaId).collection(KEY_COMMENTS).order(by: KEY_DATE, descending: true).limit(to: 2).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        var isParentComment = false
        
        for (commentIndex, document) in snapshot.documents.enumerated() {
          do {
            let comment = try FirestoreDecoder().decode(FirebaseComment.self, from: document.data())
            
            if commentIndex == 0, let parentCommentId = comment.parentCommentId {
              isParentComment = true
              
              database.collection(KEY_QNAS).document(qnaId).collection(KEY_COMMENTS).document(parentCommentId).getDocument(completion: { (parentCommentSnapshot, parentCommentError) in
                if let parentCommentError = parentCommentError {
                  DLog("Error get document: \(parentCommentError)")
                  self.isLoading = false
                  
                  return
                }
                
                if let parentCommentSnapshot = parentCommentSnapshot, let data = parentCommentSnapshot.data() {
                  do {
                    let parentComment = try FirestoreDecoder().decode(FirebaseComment.self, from: data)
                    
                    commentsTemp.append(parentComment)
                    commentsTemp.append(comment)
                    
                    var qnaTemp = qna
                    qnaTemp.comments = commentsTemp
                    self.qnas[index] = qnaTemp
                    
                    count = count + 1
                    
                    if count == qnas.count {
                      self.loadDone(sender: sender)
                    }
                  } catch let error {
                    DLog(error)
                  }
                } else {
                  let parentComment = FirebaseComment(id: "", userId: "", comment: "", date: "", isLoved: nil, parentCommentId: nil, parentCommentUserId: nil)
                  
                  commentsTemp.append(parentComment)
                  commentsTemp.append(comment)
                  
                  var qnaTemp = qna
                  qnaTemp.comments = commentsTemp
                  self.qnas[index] = qnaTemp
                  
                  count = count + 1
                  
                  if count == qnas.count {
                    self.loadDone(sender: sender)
                  }
                }
              })
            } else if !isParentComment {
              commentsTemp.append(comment)
              
              if snapshot.documents.count == commentsTemp.count {
                var qnaTemp = qna
                qnaTemp.comments = commentsTemp.reversed()
                self.qnas[index] = qnaTemp
                
                count = count + 1
                
                if count == qnas.count {
                  self.loadDone(sender: sender)
                }
              }
            }
          } catch let error {
            DLog(error)
          }
        }
        
        if snapshot.documents.isEmpty {
          count = count + 1
          
          if count == qnas.count {
            self.loadDone(sender: sender)
          }
        }
      }
    }
  }
  
  private func loadDone(sender: UIRefreshControl?) {
    guard let qnaTableView = self.qnaTableView,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    DispatchQueue.main.async {
      self.isLoading = false
      
      if let sender = sender {
        sender.endRefreshing()
      }
      
      qnaTableView.reloadData()
      
      if qnaTableView.alpha == 0.0 {
        activityIndicatorView.stopAnimating()
        
        UIView.animate(withDuration: 0.2, animations: {
          qnaTableView.alpha = 1.0
        })
      }
      
      self.isLoadedFirstData = true
    }
  }
}
