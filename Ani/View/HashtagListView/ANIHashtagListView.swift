//
//  ANIHashtagListView.swift
//  Ani
//
//  Created by jeonminseop on 2019/01/28.
//  Copyright © 2019 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import AVKit

protocol ANIHashtagListViewDelegate {
  func storyViewCellDidSelect(selectedStory: FirebaseStory, user: FirebaseUser)
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser)
  func qnaViewCellDidSelect(selectedQna: FirebaseQna, user:FirebaseUser)
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser)
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func reject()
}

class ANIHashtagListView: UIView {
  
  private weak var reloadView: ANIReloadView?
  
  private weak var hashtagTableView: UITableView?
  
  private weak var refreshControl: UIRefreshControl?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  var hashtag: String?
  var hashtagList: HashtagList? {
    didSet {
      guard let hashtagList = self.hashtagList,
            let activityIndicatorView = self.activityIndicatorView else { return }
      
      activityIndicatorView.startAnimating()
      
      switch hashtagList {
      case .story:
        loadStory(sender: nil)
      case .question:
        loadQna(sender: nil)
      }
    }
  }
  
  private let BASIC_DATE = "2000/01/01 00:00:00.000"
  
  private var stories = [FirebaseStory]()
  private var storyVideoAssets = [String: AVAsset]()
  private var qnas = [FirebaseQna]()
  private var supportRecruits = [String: FirebaseRecruit?]()
  
  private var users = [FirebaseUser]()
  
  private var isLastPage: Bool = false
  private var lastContent: QueryDocumentSnapshot?
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  private var beforeVideoViewCell: ANIVideoStoryViewCell?
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  private var scollViewContentOffsetY: CGFloat = 0.0
  
  var delegate: ANIHashtagListViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.bg
    
    //reloadView
    let reloadView = ANIReloadView()
    reloadView.alpha = 0.0
    reloadView.messege = "ストーリーがありません。"
    reloadView.delegate = self
    addSubview(reloadView)
    reloadView.dropShadow()
    reloadView.centerInSuperview()
    reloadView.leftToSuperview(offset: 50.0)
    reloadView.rightToSuperview(offset: -50.0)
    self.reloadView = reloadView
    
    //hashtagTableView
    let hashtagTableView = UITableView()
    let storyCellId = NSStringFromClass(ANIStoryViewCell.self)
    hashtagTableView.register(ANIStoryViewCell.self, forCellReuseIdentifier: storyCellId)
    let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
    hashtagTableView.register(ANIVideoStoryViewCell.self, forCellReuseIdentifier: videoStoryCellId)
    let supportCellId = NSStringFromClass(ANISupportViewCell.self)
    hashtagTableView.register(ANISupportViewCell.self, forCellReuseIdentifier: supportCellId)
    let qnaCellId = NSStringFromClass(ANIQnaViewCell.self)
    hashtagTableView.register(ANIQnaViewCell.self, forCellReuseIdentifier: qnaCellId)
    hashtagTableView.dataSource = self
    hashtagTableView.delegate = self
    hashtagTableView.separatorStyle = .none
    hashtagTableView.backgroundColor = ANIColor.bg
    hashtagTableView.alpha = 0.0
    hashtagTableView.rowHeight = UITableView.automaticDimension
    let refreshControl = UIRefreshControl()
    refreshControl.backgroundColor = .clear
    refreshControl.tintColor = ANIColor.moreDarkGray
    refreshControl.addTarget(self, action: #selector(reloadData(sender:)), for: .valueChanged)
    hashtagTableView.addSubview(refreshControl)
    self.refreshControl = refreshControl
    addSubview(hashtagTableView)
    hashtagTableView.edgesToSuperview()
    self.hashtagTableView = hashtagTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  func playVideo() {
    guard let listTableView = self.hashtagTableView else { return }
    
    let centerX = listTableView.center.x
    let centerY = listTableView.center.y + scollViewContentOffsetY + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = listTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = listTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        storyVideoView.play()
      }
    }
  }
  
  func stopVideo() {
    guard let listTableView = self.hashtagTableView else { return }
    
    let centerX = listTableView.center.x
    let centerY = listTableView.center.y + scollViewContentOffsetY + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = listTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = listTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        storyVideoView.stop()
      }
    }
  }
  
  @objc private func reloadData(sender:  UIRefreshControl?) {
    guard let hashtagList = self.hashtagList else { return }
    
    switch hashtagList {
    case .story:
      self.loadStory(sender: sender)
    case .question:
      self.loadQna(sender: sender)
    }
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(deleteStory: self, selector: #selector(deleteStory))
    ANINotificationManager.receive(deleteQna: self, selector: #selector(deleteQna))
  }
  
  @objc private func deleteStory(_ notification: NSNotification) {
    guard let id = notification.object as? String,
      let listTableView = self.hashtagTableView else { return }
    
    for (index, loveStory) in stories.enumerated() {
      if loveStory.id == id {
        stories.remove(at: index)
        
        if !stories.isEmpty {
          listTableView.beginUpdates()
          let indexPath: IndexPath = [0, index]
          listTableView.deleteRows(at: [indexPath], with: .automatic)
          listTableView.endUpdates()
        } else {
          listTableView.reloadData()
        }
      }
    }
  }
  
  @objc private func deleteQna(_ notification: NSNotification) {
    guard let id = notification.object as? String,
      let listTableView = self.hashtagTableView else { return }
    
    for (index, loveQna) in qnas.enumerated() {
      if loveQna.id == id {
        qnas.remove(at: index)
        
        if !qnas.isEmpty {
          listTableView.beginUpdates()
          let indexPath: IndexPath = [0, index]
          listTableView.deleteRows(at: [indexPath], with: .automatic)
          listTableView.endUpdates()
        } else {
          listTableView.reloadData()
        }
      }
    }
  }
  
  private func isBlockRecruit(recruit: FirebaseRecruit) -> Bool {
    guard let currentUserUid = ANISessionManager.shared.currentUserUid else { return false }
    
    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(recruit.userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(recruit.userId) {
      return true
    }
    if let hideUserIds = recruit.hideUserIds, hideUserIds.contains(currentUserUid) {
      return true
    }
    
    return false
  }
  
  private func isBlockStory(story: FirebaseStory) -> Bool {
    guard let currentUserUid = ANISessionManager.shared.currentUserUid else { return false }
    
    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(story.userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(story.userId) {
      return true
    }
    if let hideUserIds = story.hideUserIds, hideUserIds.contains(currentUserUid) {
      return true
    }
    if story.storyImageUrls == nil && story.recruitId == nil && story.thumbnailImageUrl == nil {
      return true
    }
    
    return false
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
  
  private func showReloadView() {
    guard let reloadView = self.reloadView,
          let hashtagTableView = self.hashtagTableView else { return }
    
    hashtagTableView.alpha = 0.0
    
    UIView.animate(withDuration: 0.2, animations: {
      reloadView.alpha = 1.0
    }) { (complete) in
      ANISessionManager.shared.isLoadedFirstData = true
      ANINotificationManager.postDismissSplash()
    }
  }
}

//MARK: UITableViewDataSource
extension ANIHashtagListView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let hashtagList = self.hashtagList else { return 0 }
    
    switch hashtagList {
    case .story:
      return stories.count
    case .question:
      return qnas.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let hashtagList = self.hashtagList else { return UITableViewCell() }
    
    switch hashtagList {
    case .story:
      if !stories.isEmpty {
        if let recruitId = stories[indexPath.row].recruitId {
          let supportCellId = NSStringFromClass(ANISupportViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: supportCellId, for: indexPath) as! ANISupportViewCell
          cell.delegate = self
          
          if let supportRecruit = supportRecruits[recruitId] {
            if let supportRecruit = supportRecruit {
              cell.recruit = supportRecruit
              cell.isDeleteRecruit = false
            } else {
              cell.recruit = nil
              cell.isDeleteRecruit = true
            }
          } else {
            cell.recruit = nil
            cell.isDeleteRecruit = nil
          }
          
          if users.contains(where: { $0.uid == stories[indexPath.row].userId }) {
            for user in users {
              if stories[indexPath.row].userId == user.uid {
                cell.user = user
                break
              }
            }
          } else {
            cell.user = nil
          }
          cell.indexPath = indexPath.row
          cell.story = stories[indexPath.row]
          
          return cell
        } else if stories[indexPath.row].thumbnailImageUrl != nil {
          let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: videoStoryCellId, for: indexPath) as! ANIVideoStoryViewCell
          cell.delegate = self
          
          if users.contains(where: { $0.uid == stories[indexPath.row].userId }) {
            for user in users {
              if stories[indexPath.row].userId == user.uid {
                cell.user = user
                break
              }
            }
          } else {
            cell.user = nil
          }
          
          if let storyVideoUrl = stories[indexPath.row].storyVideoUrl,
            storyVideoAssets.contains(where: { $0.0 == storyVideoUrl }) {
            cell.videoAsset = storyVideoAssets[storyVideoUrl]
          } else {
            cell.videoAsset = nil
          }
          
          cell.indexPath = indexPath.row
          cell.story = stories[indexPath.row]
          
          return cell
        } else {
          let storyCellId = NSStringFromClass(ANIStoryViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: storyCellId, for: indexPath) as! ANIStoryViewCell
          
          if users.contains(where: { $0.uid == stories[indexPath.row].userId }) {
            for user in users {
              if stories[indexPath.row].userId == user.uid {
                cell.user = user
                break
              }
            }
          } else {
            cell.user = nil
          }
          cell.indexPath = indexPath.row
          cell.story = stories[indexPath.row]
          cell.delegate = self
          
          return cell
        }
      } else {
        return UITableViewCell()
      }
    case .question:
      let qnaCellid = NSStringFromClass(ANIQnaViewCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: qnaCellid, for: indexPath) as! ANIQnaViewCell
      cell.delegate = self
      
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
      cell.indexPath = indexPath.row
      cell.qna = qnas[indexPath.row]
      
      return cell
    }
  }
}

//MARK: UITableViewDelegate
extension ANIHashtagListView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let hashtagList = self.hashtagList else { return }
    
    switch hashtagList {
    case .story:
      if !stories.isEmpty && stories.count > indexPath.row {
        if stories[indexPath.row].recruitId != nil, let cell = cell as? ANISupportViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
        } else if stories[indexPath.row].thumbnailImageUrl != nil, let cell = cell as? ANIVideoStoryViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
          cell.storyVideoView?.removeReachEndObserver()
          cell.storyVideoView?.stop()
        } else if let cell = cell as? ANIStoryViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
        }
      }
    case .question:
      if let cell = cell as? ANIQnaViewCell {
        cell.unobserveLove()
        cell.unobserveComment()
      }
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let hashtagList = self.hashtagList else { return }
    
    switch hashtagList {
    case .story:
      let element = self.stories.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreStory()
      }
    case .question:
      let element = self.qnas.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreQna()
      }
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
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let listTableView = self.hashtagTableView else { return }
    
    scollViewContentOffsetY = scrollView.contentOffset.y
    
    //play video
    let centerX = listTableView.center.x
    let centerY = listTableView.center.y + scrollView.contentOffset.y + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = listTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = listTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        if beforeVideoViewCell != videoCell {
          if let beforeVideoViewCell = self.beforeVideoViewCell,
            let beforeStoryVideoView = beforeVideoViewCell.storyVideoView {
            beforeStoryVideoView.stop()
          }
          
          storyVideoView.play()
          beforeVideoViewCell = videoCell
        }
      } else {
        if let beforeVideoViewCell = self.beforeVideoViewCell,
          let beforeStoryVideoView = beforeVideoViewCell.storyVideoView {
          beforeStoryVideoView.stop()
        }
        
        beforeVideoViewCell = nil
      }
    }
  }
}

//MARK: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate
extension ANIHashtagListView: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate {
  func storyCellTapped(story: FirebaseStory, user: FirebaseUser) {
    self.delegate?.storyViewCellDidSelect(selectedStory: story, user: user)
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.delegate?.popupOptionView(isMe: isMe, contentType: contentType, id: id)
  }
  
  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool) {
    guard let hashtagList = self.hashtagList else { return }
    
    if hashtagList == .story {
      var story = self.stories[indexPath]
      story.isLoved = isLoved
      self.stories[indexPath] = story
    }
  }
  
  func loadedStoryUser(user: FirebaseUser) {
    self.users.append(user)
  }
  
  func loadedVideo(urlString: String, asset: AVAsset) {
    storyVideoAssets[urlString] = asset
  }
  
  func reject() {
    self.delegate?.reject()
  }
}

//MARK: ANISupportViewCellDelegate
extension ANIHashtagListView: ANISupportViewCellDelegate {
  func supportCellTapped(story: FirebaseStory, user: FirebaseUser) {
    self.delegate?.storyViewCellDidSelect(selectedStory: story, user: user)
  }
  
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.supportCellRecruitTapped(recruit: recruit, user: user)
  }
  
  func loadedRecruit(recruitId: String, recruit: FirebaseRecruit?) {
    self.supportRecruits[recruitId] = recruit
  }
}

//MARK: ANIQnaViewCellDelegate
extension ANIHashtagListView: ANIQnaViewCellDelegate {
  func cellTapped(qna: FirebaseQna, user: FirebaseUser) {
    self.delegate?.qnaViewCellDidSelect(selectedQna: qna, user: user)
  }
  
  func loadedQnaIsLoved(indexPath: Int, isLoved: Bool) {
    guard let hashtagList = self.hashtagList else { return }
    
    if hashtagList == .question {
      var loveQna = self.qnas[indexPath]
      loveQna.isLoved = isLoved
      self.qnas[indexPath] = loveQna
    }
  }
  
  func loadedQnaUser(user: FirebaseUser) {
    self.users.append(user)
  }
}

//MARK: data
extension ANIHashtagListView {
  private func loadStory(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView,
          let hashtagTableView = self.hashtagTableView,
          let hashtag = self.hashtag else { return }
    
    reloadView.alpha = 0.0
    
    if !self.stories.isEmpty {
      self.stories.removeAll()
    }
    if !self.supportRecruits.isEmpty {
      self.supportRecruits.removeAll()
    }
    if !self.users.isEmpty {
      self.users.removeAll()
    }
    
    let database = Firestore.firestore()
    
    let group = DispatchGroup()
    
    group.enter()
    DispatchQueue(label: "story").async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_STORIES).whereField(KEY_HASHTAGS + "." + hashtag, isGreaterThan: self.BASIC_DATE).order(by: KEY_HASHTAGS + "." + hashtag, descending: true).limit(to: 15).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          group.leave()
          
          return
        }
        
        guard let snapshot = snapshot,
          let lastStory = snapshot.documents.last else {
            if !self.stories.isEmpty {
              self.stories.removeAll()
            }
            
            group.leave()
            return }
        
        self.lastContent = lastStory
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let story = try FirestoreDecoder().decode(FirebaseStory.self, from: document.data())
            
            if !self.isBlockStory(story: story) {
              if let storyVideoUrl = story.storyVideoUrl,
                let url = URL(string: storyVideoUrl),
                !self.storyVideoAssets.contains(where: { $0.0 == storyVideoUrl }) {
                let asset = AVAsset(url: url)
                self.storyVideoAssets[storyVideoUrl] = asset
              }
              
              self.stories.append(story)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                group.leave()
              }
            }
          } catch let error {
            DLog(error)
            
            group.leave()
          }
        }
      })
    }
    
    group.notify(queue: DispatchQueue(label: "story")) {
      DispatchQueue.main.async {
        self.isLoading = false
        
        if let sender = sender {
          sender.endRefreshing()
        }
        
        activityIndicatorView.stopAnimating()
        
        if self.lastContent != nil {
          hashtagTableView.reloadData()
          
          if self.stories.isEmpty {
            self.loadMoreStory()
          } else {
            if hashtagTableView.alpha == 0 {
              UIView.animate(withDuration: 0.2, animations: {
                hashtagTableView.alpha = 1.0
              })
            }
          }
        } else {
          self.showReloadView()
        }
      }
    }
  }
  
  private func loadMoreStory() {
    guard let hashtagTableView = self.hashtagTableView,
          let lastContent = self.lastContent,
          let activityIndicatorView = self.activityIndicatorView,
          let hashtag = self.hashtag,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_STORIES).whereField(KEY_HASHTAGS + "." + hashtag, isGreaterThan: self.BASIC_DATE).order(by: KEY_HASHTAGS + "." + hashtag, descending: true).start(afterDocument: lastContent).limit(to: 15).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastStory = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          return
        }
        
        self.lastContent = lastStory
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let story = try FirestoreDecoder().decode(FirebaseStory.self, from: document.data())
            
            if !self.isBlockStory(story: story) {
              if let storyVideoUrl = story.storyVideoUrl,
                let url = URL(string: storyVideoUrl),
                !self.storyVideoAssets.contains(where: { $0.0 == storyVideoUrl }) {
                let asset = AVAsset(url: url)
                self.storyVideoAssets[storyVideoUrl] = asset
              }
              
              self.stories.append(story)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                hashtagTableView.reloadData()
                
                self.isLoading = false
                
                if self.stories.isEmpty {
                  self.loadMoreStory()
                } else {
                  if hashtagTableView.alpha == 0 {
                    activityIndicatorView.stopAnimating()
                    
                    UIView.animate(withDuration: 0.2, animations: {
                      hashtagTableView.alpha = 1.0
                    })
                  }
                }
              }
            }
          } catch let error {
            DLog(error)
            self.isLoading = false
          }
        }
      })
    }
  }
  
  private func loadQna(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView,
          let hashtagTableView = self.hashtagTableView,
          let hashtag = self.hashtag else { return }
    
    reloadView.alpha = 0.0
    
    if !self.qnas.isEmpty {
      self.qnas.removeAll()
    }
    if !self.users.isEmpty {
      self.users.removeAll()
    }
    
    let database = Firestore.firestore()
    
    let group = DispatchGroup()
    
    group.enter()
    DispatchQueue(label: "qna").async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_QNAS).whereField(KEY_HASHTAGS + "." + hashtag, isGreaterThan: self.BASIC_DATE).order(by: KEY_HASHTAGS + "." + hashtag, descending: true).limit(to: 25).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          group.leave()
          
          return
        }
        
        guard let snapshot = snapshot,
          let lastQna = snapshot.documents.last else {
            if !self.qnas.isEmpty {
              self.qnas.removeAll()
            }
            
            group.leave()
            return }
        
        self.lastContent = lastQna
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: document.data())
            
            if !self.isBlockQna(qna: qna) {
              self.qnas.append(qna)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                group.leave()
              }
            }
          } catch let error {
            DLog(error)
            
            group.leave()
          }
        }
      })
    }
    
    group.notify(queue: DispatchQueue(label: "qna")) {
      DispatchQueue.main.async {
        self.isLoading = false
        
        if let sender = sender {
          sender.endRefreshing()
        }
        
        activityIndicatorView.stopAnimating()
        
        if self.lastContent != nil {
          hashtagTableView.reloadData()
          
          if self.qnas.isEmpty {
            self.loadMoreQna()
          } else {
            if hashtagTableView.alpha == 0 {
              UIView.animate(withDuration: 0.2, animations: {
                hashtagTableView.alpha = 1.0
              })
            }
          }
        } else {
          self.showReloadView()
        }
      }
    }
  }
  
  private func loadMoreQna() {
    guard let hashtagTableView = self.hashtagTableView,
          let lastContent = self.lastContent,
          let activityIndicatorView = self.activityIndicatorView,
          let hashtag = self.hashtag,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_QNAS).whereField(KEY_HASHTAGS + "." + hashtag, isGreaterThan: self.BASIC_DATE).order(by: KEY_HASHTAGS + "." + hashtag, descending: true).start(afterDocument: lastContent).limit(to: 25).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastQna = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          return
        }
        
        self.lastContent = lastQna
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
          let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: document.data())
            
            if !self.isBlockQna(qna: qna) {
              self.qnas.append(qna)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                hashtagTableView.reloadData()
                
                self.isLoading = false
                
                if self.qnas.isEmpty {
                  self.loadMoreQna()
                } else {
                  if hashtagTableView.alpha == 0 {
                    activityIndicatorView.stopAnimating()
                    
                    UIView.animate(withDuration: 0.2, animations: {
                      hashtagTableView.alpha = 1.0
                    })
                    
                    ANISessionManager.shared.isLoadedFirstData = true
                  }
                  
                  ANINotificationManager.postDismissSplash()
                }
              }
            }
          } catch let error {
            DLog(error)
            self.isLoading = false
          }
        }
      })
    }
  }
}

//MARK: ANIReloadViewDelegate
extension ANIHashtagListView: ANIReloadViewDelegate {
  func reloadButtonTapped() {
    guard let hashtagList = self.hashtagList else { return }
    
    switch hashtagList {
    case .story:
      self.loadStory(sender: nil)
    case .question:
      self.loadQna(sender: nil)
    }
  }
}
