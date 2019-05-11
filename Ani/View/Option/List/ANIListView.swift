//
//  ANIListView.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/25.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import AVKit

protocol ANIListViewDelegate {
  func recruitViewCellDidSelect(selectedRecruit: FirebaseRecruit, user: FirebaseUser)
  func storyViewCellDidSelect(selectedStory: FirebaseStory, user: FirebaseUser)
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser)
  func qnaViewCellDidSelect(selectedQna: FirebaseQna, user:FirebaseUser)
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser)
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
}

class ANIListView: UIView {
  
  private weak var listTableView: UITableView?
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  var list: List? {
    didSet {
      guard let list = self.list,
            let activityIndicatorView = self.activityIndicatorView,
            let listTableView = self.listTableView else { return }
      
      activityIndicatorView.startAnimating()
      
      switch list {
      case .loveRecruit:
        listTableView.contentInset = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 0.0, right: 0.0)
        loadLoveRecruit()
      case .loveStroy:
        loadLoveStory()
      case .loveQuestion:
        loadLoveQna()
      case .clipRecruit:
        listTableView.contentInset = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 0.0, right: 0.0)
        loadClipRecruit()
      }
    }
  }
  
  private var loveRecruits = [FirebaseRecruit]()
  private var loveStories = [FirebaseStory]()
  private var storyVideoAssets = [String: AVAsset]()
  private var loveQnas = [FirebaseQna]()
  private var supportRecruits = [String: FirebaseRecruit?]()
  private var clipRecruits = [FirebaseRecruit]()
  
  private var users = [FirebaseUser]()
  
  private var isLastPage: Bool = false
  private var lastContent: QueryDocumentSnapshot?
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  private var beforeVideoViewCell: ANIVideoStoryViewCell?

  private var cellHeight = [IndexPath: CGFloat]()
  
  private var scollViewContentOffsetY: CGFloat = 0.0
  
  var delegate: ANIListViewDelegate?
  
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
    
    //listTableView
    let listTableView = UITableView()
    let recruitCellId = NSStringFromClass(ANIRecruitViewCell.self)
    listTableView.register(ANIRecruitViewCell.self, forCellReuseIdentifier: recruitCellId)
    let storyCellId = NSStringFromClass(ANIStoryViewCell.self)
    listTableView.register(ANIStoryViewCell.self, forCellReuseIdentifier: storyCellId)
    let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
    listTableView.register(ANIVideoStoryViewCell.self, forCellReuseIdentifier: videoStoryCellId)
    let supportCellId = NSStringFromClass(ANISupportViewCell.self)
    listTableView.register(ANISupportViewCell.self, forCellReuseIdentifier: supportCellId)
    let qnaCellId = NSStringFromClass(ANIQnaViewCell.self)
    listTableView.register(ANIQnaViewCell.self, forCellReuseIdentifier: qnaCellId)
    listTableView.dataSource = self
    listTableView.delegate = self
    listTableView.separatorStyle = .none
    listTableView.backgroundColor = ANIColor.bg
    listTableView.alpha = 0.0
    listTableView.rowHeight = UITableView.automaticDimension
    addSubview(listTableView)
    listTableView.edgesToSuperview()
    self.listTableView = listTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  func playVideo() {
    guard let listTableView = self.listTableView else { return }
    
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
    guard let listTableView = self.listTableView else { return }
    
    let centerX = listTableView.center.x
    let centerY = listTableView.center.y + scollViewContentOffsetY + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = listTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = listTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        storyVideoView.stop()
      }
    }
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(deleteRecruit: self, selector: #selector(deleteRecruit))
    ANINotificationManager.receive(deleteStory: self, selector: #selector(deleteStory))
    ANINotificationManager.receive(deleteQna: self, selector: #selector(deleteQna))
  }
  
  @objc private func deleteRecruit(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let list = self.list,
          let listTableView = self.listTableView else { return }
    
    if list == .loveRecruit {
      for (index, recruit) in loveRecruits.enumerated() {
        if recruit.id == id {
          loveRecruits.remove(at: index)
          
          if !loveRecruits.isEmpty {
            listTableView.beginUpdates()
            let indexPath: IndexPath = [0, index]
            listTableView.deleteRows(at: [indexPath], with: .automatic)
            listTableView.endUpdates()
          } else {
            listTableView.reloadData()
          }
        }
      }
    } else if list == .clipRecruit {
      for (index, recruit) in clipRecruits.enumerated() {
        if recruit.id == id {
          clipRecruits.remove(at: index)
          
          if !clipRecruits.isEmpty {
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
  }
  
  @objc private func deleteStory(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let listTableView = self.listTableView else { return }
    
    for (index, loveStory) in loveStories.enumerated() {
      if loveStory.id == id {
        loveStories.remove(at: index)
        
        if !loveStories.isEmpty {
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
          let listTableView = self.listTableView else { return }
    
    for (index, loveQna) in loveQnas.enumerated() {
      if loveQna.id == id {
        loveQnas.remove(at: index)
        
        if !loveQnas.isEmpty {
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
}

//MARK: UITableViewDataSource
extension ANIListView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard let list = self.list else { return 0 }
    
    switch list {
    case .loveRecruit:
      return loveRecruits.count
    case .loveStroy:
      return loveStories.count
    case .loveQuestion:
      return loveQnas.count
    case .clipRecruit:
      return clipRecruits.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let list = self.list else { return UITableViewCell() }
    
    switch list {
    case .loveRecruit:
      let recruitCellid = NSStringFromClass(ANIRecruitViewCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: recruitCellid, for: indexPath) as! ANIRecruitViewCell
      cell.delegate = self

      if users.contains(where: { $0.uid == loveRecruits[indexPath.row].userId }) {
        for user in users {
          if loveRecruits[indexPath.row].userId == user.uid {
            cell.user = user
            break
          }
        }
      } else {
        cell.user = nil
      }
      cell.indexPath = indexPath.row
      cell.recruit = loveRecruits[indexPath.row]
      
      return cell
    case .loveStroy:
      if !loveStories.isEmpty {
        if let recruitId = loveStories[indexPath.row].recruitId {
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

          if users.contains(where: { $0.uid == loveStories[indexPath.row].userId }) {
            for user in users {
              if loveStories[indexPath.row].userId == user.uid {
                cell.user = user
                break
              }
            }
          } else {
            cell.user = nil
          }
          cell.indexPath = indexPath.row
          cell.story = loveStories[indexPath.row]
          
          return cell
        } else if loveStories[indexPath.row].thumbnailImageUrl != nil {
          let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: videoStoryCellId, for: indexPath) as! ANIVideoStoryViewCell
          cell.delegate = self
          
          if users.contains(where: { $0.uid == loveStories[indexPath.row].userId }) {
            for user in users {
              if loveStories[indexPath.row].userId == user.uid {
                cell.user = user
                break
              }
            }
          } else {
            cell.user = nil
          }
          
          if let storyVideoUrl = loveStories[indexPath.row].storyVideoUrl,
            storyVideoAssets.contains(where: { $0.0 == storyVideoUrl }) {
            cell.videoAsset = storyVideoAssets[storyVideoUrl]
          } else {
            cell.videoAsset = nil
          }
          
          cell.indexPath = indexPath.row
          cell.story = loveStories[indexPath.row]
          
          return cell
        } else {
          let storyCellId = NSStringFromClass(ANIStoryViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: storyCellId, for: indexPath) as! ANIStoryViewCell
          
          if users.contains(where: { $0.uid == loveStories[indexPath.row].userId }) {
            for user in users {
              if loveStories[indexPath.row].userId == user.uid {
                cell.user = user
                break
              }
            }
          } else {
            cell.user = nil
          }
          cell.indexPath = indexPath.row
          cell.story = loveStories[indexPath.row]
          cell.delegate = self
          
          return cell
        }
      } else {
        return UITableViewCell()
      }
    case .loveQuestion:
      let qnaCellid = NSStringFromClass(ANIQnaViewCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: qnaCellid, for: indexPath) as! ANIQnaViewCell
      cell.delegate = self

      if users.contains(where: { $0.uid == loveQnas[indexPath.row].userId }) {
        for user in users {
          if loveQnas[indexPath.row].userId == user.uid {
            cell.user = user
            break
          }
        }
      } else {
        cell.user = nil
      }
      cell.indexPath = indexPath.row
      cell.qna = loveQnas[indexPath.row]
      
      return cell
    case .clipRecruit:
      let recruitCellid = NSStringFromClass(ANIRecruitViewCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: recruitCellid, for: indexPath) as! ANIRecruitViewCell
      cell.delegate = self

      if users.contains(where: { $0.uid == clipRecruits[indexPath.row].userId }) {
        for user in users {
          if clipRecruits[indexPath.row].userId == user.uid {
            cell.user = user
            break
          }
        }
      } else {
        cell.user = nil
      }
      cell.indexPath = indexPath.row
      cell.recruit = clipRecruits[indexPath.row]
      
      return cell
    }
  }
}

//MARK: UITableViewDelegate
extension ANIListView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let list = self.list else { return }
    
    switch list {
    case .loveRecruit:
      if let cell = cell as? ANIRecruitViewCell {
        cell.unobserveLove()
        cell.unobserveSupport()
      }
    case .loveStroy:
      if !loveStories.isEmpty && loveStories.count > indexPath.row {
        if loveStories[indexPath.row].recruitId != nil, let cell = cell as? ANISupportViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
        } else if loveStories[indexPath.row].thumbnailImageUrl != nil, let cell = cell as? ANIVideoStoryViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
          cell.storyVideoView?.removeReachEndObserver()
          cell.storyVideoView?.stop()
        } else if let cell = cell as? ANIStoryViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
        }
      }
    case .loveQuestion:
      if let cell = cell as? ANIQnaViewCell {
        cell.unobserveLove()
        cell.unobserveComment()
      }
    case .clipRecruit:
      if let cell = cell as? ANIRecruitViewCell {
        cell.unobserveLove()
        cell.unobserveSupport()
      }
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let list = self.list else { return }
    
    switch list {
    case .loveRecruit:
      let element = self.loveRecruits.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreLoveRecruit()
      }
    case .loveStroy:
      let element = self.loveStories.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreLoveStory()
      }
    case .loveQuestion:
      let element = self.loveQnas.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreLoveQna()
      }
    case .clipRecruit:
      let element = self.clipRecruits.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreClipRecruit()
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
    guard let listTableView = self.listTableView else { return }
    
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

//MARK: ANIRecruitViewCellDelegate
extension ANIListView: ANIRecruitViewCellDelegate {
  func reject() {
    DLog("reject")
  }
  
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.supportButtonTapped(supportRecruit: supportRecruit, user: user)
  }
  
  func cellTapped(recruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.recruitViewCellDidSelect(selectedRecruit: recruit, user: user)
  }
  
  func loadedRecruitIsLoved(indexPath: Int, isLoved: Bool) {
    guard let list = self.list else { return }

    if list == .loveRecruit {
      var recruit = self.loveRecruits[indexPath]
      recruit.isLoved = isLoved
      self.loveRecruits[indexPath] = recruit
    } else if list == .clipRecruit {
      var recruit = self.clipRecruits[indexPath]
      recruit.isLoved = isLoved
      self.clipRecruits[indexPath] = recruit
    }
  }
  
  func loadedRecruitIsCliped(indexPath: Int, isCliped: Bool) {
    guard let list = self.list else { return }
    
    if list == .loveRecruit {
      var recruit = self.loveRecruits[indexPath]
      recruit.isCliped = isCliped
      self.loveRecruits[indexPath] = recruit
    } else if list == .clipRecruit {
      var recruit = self.clipRecruits[indexPath]
      recruit.isCliped = isCliped
      self.clipRecruits[indexPath] = recruit
    }
  }
  
  func loadedRecruitIsSupported(indexPath: Int, isSupported: Bool) {
    guard let list = self.list else { return }
    
    if list == .loveRecruit {
      var recruit = self.loveRecruits[indexPath]
      recruit.isSupported = isSupported
      self.loveRecruits[indexPath] = recruit
    } else if list == .clipRecruit {
      var recruit = self.clipRecruits[indexPath]
      recruit.isSupported = isSupported
      self.clipRecruits[indexPath] = recruit
    }
  }
  
  func loadedRecruitUser(user: FirebaseUser) {
    self.users.append(user)
  }
}

//MARK: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate
extension ANIListView: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate {
  func storyCellTapped(story: FirebaseStory, user: FirebaseUser) {
    self.delegate?.storyViewCellDidSelect(selectedStory: story, user: user)
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.delegate?.popupOptionView(isMe: isMe, contentType: contentType, id: id)
  }
  
  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool) {
    guard let list = self.list else { return }

    if list == .loveStroy {
      var story = self.loveStories[indexPath]
      story.isLoved = isLoved
      self.loveStories[indexPath] = story
    }
  }
  
  func loadedStoryUser(user: FirebaseUser) {
    self.users.append(user)
  }
  
  func loadedVideo(urlString: String, asset: AVAsset) {
    storyVideoAssets[urlString] = asset
  }
}

//MARK: ANISupportViewCellDelegate
extension ANIListView: ANISupportViewCellDelegate {
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
extension ANIListView: ANIQnaViewCellDelegate {
  func cellTapped(qna: FirebaseQna, user: FirebaseUser) {
    self.delegate?.qnaViewCellDidSelect(selectedQna: qna, user: user)
  }
  
  func loadedQnaIsLoved(indexPath: Int, isLoved: Bool) {
    guard let list = self.list else { return }

    if list == .loveQuestion {
      var loveQna = self.loveQnas[indexPath]
      loveQna.isLoved = isLoved
      self.loveQnas[indexPath] = loveQna
    }
  }
  
  func loadedQnaUser(user: FirebaseUser) {
    self.users.append(user)
  }
}

//MARK: data
extension ANIListView {
  private func loadLoveRecruit() {
    guard let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_RECRUIT_IDS).order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false

          return
        }
        
        guard let snapshot = snapshot,
              let lastContent = snapshot.documents.last else {
                self.isLoading = false
                activityIndicatorView.stopAnimating()
                return }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var loveRecruitsTemp = [FirebaseRecruit?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          group.enter()
          loveRecruitsTemp.append(nil)
          
          DispatchQueue(label: "loveRecruit").async {
            database.collection(KEY_RECRUITS).document(document.documentID).getDocument(completion: { (recruitSnapshot, recruitError) in
              if let recruitError = recruitError {
                DLog("Error get document: \(recruitError)")
                self.isLoading = false
                
                return
              }
              
              guard let recruitSnapshot = recruitSnapshot, let data = recruitSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: data)
                loveRecruitsTemp[index] = recruit
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }

        group.notify(queue: DispatchQueue(label: "loveRecruit")) {
          DispatchQueue.main.async {
            guard let listTableView = self.listTableView else { return }
            
            for loveRecruit in loveRecruitsTemp {
              if let loveRecruit = loveRecruit {
                if !self.isBlockRecruit(recruit: loveRecruit) {
                  self.loveRecruits.append(loveRecruit)
                }
              }
            }
            
            listTableView.reloadData()
            
            self.isLoading = false
            
            if self.loveRecruits.isEmpty {
              self.loadMoreLoveRecruit()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
  
  private func loadMoreLoveRecruit() {
    guard let listTableView = self.listTableView,
          let lastContent = self.lastContent,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_RECRUIT_IDS).order(by: KEY_DATE, descending: true).start(afterDocument: lastContent).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }

        guard let snapshot = snapshot else { return }
        guard let lastContent = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          activityIndicatorView.stopAnimating()
          return
        }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var loveRecruitsTemp = [FirebaseRecruit?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          loveRecruitsTemp.append(nil)
          
          DispatchQueue(label: "loveRecruit").async {
            database.collection(KEY_RECRUITS).document(document.documentID).getDocument(completion: { (recruitSnapshot, recruitError) in
              if let recruitError = recruitError {
                DLog("Error get document: \(recruitError)")
                self.isLoading = false
                
                return
              }
              
              guard let recruitSnapshot = recruitSnapshot, let data = recruitSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: data)
                loveRecruitsTemp[index] = recruit
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "loveRecruit")) {
          DispatchQueue.main.async {
            for loveRecruit in loveRecruitsTemp {
              if let loveRecruit = loveRecruit {
                if !self.isBlockRecruit(recruit: loveRecruit) {
                  self.loveRecruits.append(loveRecruit)
                }
              }
            }
            listTableView.reloadData()
            
            self.isLoading = false
            
            if self.loveRecruits.isEmpty {
              self.loadMoreLoveRecruit()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
  
  private func loadLoveStory() {
    guard let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_STORY_IDS).order(by: KEY_DATE, descending: true).limit(to: 10).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastContent = snapshot.documents.last else {
                self.isLoading = false
                activityIndicatorView.stopAnimating()
                return }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var loveStoriesTemp = [FirebaseStory?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          loveStoriesTemp.append(nil)
          
          DispatchQueue(label: "loveStory").async {
            database.collection(KEY_STORIES).document(document.documentID).getDocument(completion: { (storySnapshot, storyError) in
              if let storyError = storyError {
                DLog("Error get document: \(storyError)")
                self.isLoading = false
                
                return
              }
              
              guard let storySnapshot = storySnapshot, let data = storySnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let story = try FirestoreDecoder().decode(FirebaseStory.self, from: data)
                loveStoriesTemp[index] = story
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()                
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "loveStory")) {
          DispatchQueue.main.async {
            guard let listTableView = self.listTableView else { return }
            
            for loveStory in loveStoriesTemp {
              if let loveStory = loveStory {
                if !self.isBlockStory(story: loveStory) {
                  self.loveStories.append(loveStory)
                }
              }
            }
            
            listTableView.reloadData()
            
            self.isLoading = false

            if self.loveStories.isEmpty {
              self.loadMoreLoveStory()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
  
  private func loadMoreLoveStory() {
    guard let listTableView = self.listTableView,
          let lastContent = self.lastContent,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_STORY_IDS).order(by: KEY_DATE, descending: true).start(afterDocument: lastContent).limit(to: 10).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastContent = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          activityIndicatorView.stopAnimating()
          return
        }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var loveStoriesTemp = [FirebaseStory?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          loveStoriesTemp.append(nil)
          
          DispatchQueue(label: "loveStory").async {
            database.collection(KEY_STORIES).document(document.documentID).getDocument(completion: { (storySnapshot, storyError) in
              if let storyError = storyError {
                DLog("Error get document: \(storyError)")
                self.isLoading = false
                
                return
              }
              
              guard let storySnapshot = storySnapshot, let data = storySnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let story = try FirestoreDecoder().decode(FirebaseStory.self, from: data)
                loveStoriesTemp[index] = story
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "loveStory")) {
          DispatchQueue.main.async {
            for loveStory in loveStoriesTemp {
              if let loveStory = loveStory {
                if !self.isBlockStory(story: loveStory) {
                  self.loveStories.append(loveStory)
                }
              }
            }
            listTableView.reloadData()
            
            self.isLoading = false
            
            if self.loveStories.isEmpty {
              self.loadMoreLoveStory()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
  
  private func loadLoveQna() {
    guard let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_QNA_IDS).order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastContent = snapshot.documents.last else {
                self.isLoading = false
                activityIndicatorView.stopAnimating()
                return }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var loveQnasTemp = [FirebaseQna?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          loveQnasTemp.append(nil)
          
          DispatchQueue(label: "loveQna").async {
            database.collection(KEY_QNAS).document(document.documentID).getDocument(completion: { (qnaSnapshot, qnaError) in
              if let qnaError = qnaError {
                DLog("Error get document: \(qnaError)")
                self.isLoading = false
                return
              }
              
              guard let qnaSnapshot = qnaSnapshot, let data = qnaSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: data)
                loveQnasTemp[index] = qna
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "loveQna")) {
          DispatchQueue.main.async {
            guard let listTableView = self.listTableView else { return }
            
            for loveQna in loveQnasTemp {
              if let loveQna = loveQna {
                if !self.isBlockQna(qna: loveQna) {
                  self.loveQnas.append(loveQna)
                }
              }
            }
            
            listTableView.reloadData()
            
            self.isLoading = false
            
            if self.loveQnas.isEmpty {
              self.loadMoreLoveQna()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
  
  private func loadMoreLoveQna() {
    guard let listTableView = self.listTableView,
          let lastContent = self.lastContent,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_LOVE_QNA_IDS).order(by: KEY_DATE, descending: true).start(afterDocument: lastContent).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastContent = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          activityIndicatorView.stopAnimating()
          return
        }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var loveQnasTemp = [FirebaseQna?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          loveQnasTemp.append(nil)
          
          DispatchQueue(label: "loveQna").async {
            database.collection(KEY_QNAS).document(document.documentID).getDocument(completion: { (qnaSnapshot, qnaError) in
              if let qnaError = qnaError {
                DLog("Error get document: \(qnaError)")
                self.isLoading = false
                
                return
              }
              
              guard let qnaSnapshot = qnaSnapshot, let data = qnaSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: data)
                loveQnasTemp[index] = qna
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "loveQna")) {
          DispatchQueue.main.async {
            for loveQna in loveQnasTemp {
              if let loveQna = loveQna {
                if !self.isBlockQna(qna: loveQna) {
                  self.loveQnas.append(loveQna)
                }
              }
            }
            listTableView.reloadData()
            
            self.isLoading = false
            
            if self.loveQnas.isEmpty {
              self.loadMoreLoveQna()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
  
  private func loadClipRecruit() {
    guard let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastPage = false
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_CLIP_RECRUIT_IDS).order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastContent = snapshot.documents.last else {
                self.isLoading = false
                activityIndicatorView.stopAnimating()
                return }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var clipRecruitsTemp = [FirebaseRecruit?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          group.enter()
          clipRecruitsTemp.append(nil)
          
          DispatchQueue(label: "clipRecruit").async {
            database.collection(KEY_RECRUITS).document(document.documentID).getDocument(completion: { (recruitSnapshot, recruitError) in
              if let recruitError = recruitError {
                DLog("Error get document: \(recruitError)")
                self.isLoading = false
                
                return
              }
              
              guard let recruitSnapshot = recruitSnapshot, let data = recruitSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: data)
                clipRecruitsTemp[index] = recruit
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "clipRecruit")) {
          DispatchQueue.main.async {
            guard let listTableView = self.listTableView else { return }
            
            for clipRecruit in clipRecruitsTemp {
              if let clipRecruit = clipRecruit {
                if !self.isBlockRecruit(recruit: clipRecruit) {
                  self.clipRecruits.append(clipRecruit)
                }
              }
            }
            
            listTableView.reloadData()
            
            self.isLoading = false

            if self.clipRecruits.isEmpty {
              self.loadMoreClipRecruit()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
  
  private func loadMoreClipRecruit() {
    guard let listTableView = self.listTableView,
          let lastContent = self.lastContent,
          let currentUserId = ANISessionManager.shared.currentUserUid,
          let activityIndicatorView = self.activityIndicatorView,
          !isLoading,
          !isLastPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_USERS).document(currentUserId).collection(KEY_CLIP_RECRUIT_IDS).order(by: KEY_DATE, descending: true).start(afterDocument: lastContent).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastContent = snapshot.documents.last else {
          self.isLastPage = true
          self.isLoading = false
          activityIndicatorView.stopAnimating()
          return
        }
        
        self.lastContent = lastContent
        
        let group = DispatchGroup()
        var clipRecruitsTemp = [FirebaseRecruit?]()
        
        for (index, document) in snapshot.documents.enumerated() {
          
          group.enter()
          clipRecruitsTemp.append(nil)
          
          DispatchQueue(label: "clipRecruit").async {
            database.collection(KEY_RECRUITS).document(document.documentID).getDocument(completion: { (recruitSnapshot, recruitError) in
              if let recruitError = recruitError {
                DLog("Error get document: \(recruitError)")
                self.isLoading = false
                group.leave()
                
                return
              }
              
              guard let recruitSnapshot = recruitSnapshot, let data = recruitSnapshot.data() else {
                group.leave()
                return
              }
              
              do {
                let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: data)
                clipRecruitsTemp[index] = recruit
                
                group.leave()
              } catch let error {
                DLog(error)
                
                group.leave()
              }
            })
          }
        }
        
        group.notify(queue: DispatchQueue(label: "clipRecruit")) {
          DispatchQueue.main.async {
            for clipRecruit in clipRecruitsTemp {
              if let clipRecruit = clipRecruit {
                if !self.isBlockRecruit(recruit: clipRecruit) {
                  self.clipRecruits.append(clipRecruit)
                }
              }
            }
            
            listTableView.reloadData()
            
            self.isLoading = false
            
            if self.clipRecruits.isEmpty {
              self.loadMoreClipRecruit()
            } else {
              activityIndicatorView.stopAnimating()
              
              UIView.animate(withDuration: 0.2, animations: {
                listTableView.alpha = 1.0
              })
            }
          }
        }
      })
    }
  }
}
