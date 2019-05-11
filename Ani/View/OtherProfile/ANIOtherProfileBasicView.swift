//
//  ANIOtherProfileBasicView.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import CodableFirebase
import AVKit

protocol ANIOtherProfileBasicViewDelegate {
  func loadedUser(user: FirebaseUser)
  func followingTapped()
  func followerTapped()
  func recruitViewCellDidSelect(selectedRecruit: FirebaseRecruit, user: FirebaseUser)
  func storyViewCellDidSelect(selectedStory: FirebaseStory, user: FirebaseUser)
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser)
  func qnaViewCellDidSelect(selectedQna: FirebaseQna, user:FirebaseUser)
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser)
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func presentImageBrowser(index: Int, imageUrls: [String])
  func twitterOpenReject()
  func instagramOpenReject()
  func openUrl(url: URL)
}

class ANIOtherProfileBasicView: UIView {
  
  enum SectionType:Int { case top = 0; case content = 1 }
  
  private var contentType: ContentType = .profile {
    didSet {
      if contentType == .story {
        playVideo()
      } else {
        stopVideo()
      }
      self.basicTableView?.reloadData()
      self.layoutIfNeeded()
      
      isMenuChange = false
    }
  }
  
  private weak var basicTableView: UITableView?
    
  private weak var activityIndicatorView: ANIActivityIndicator?

  private var lastRecruit: QueryDocumentSnapshot?
  private var recruits = [FirebaseRecruit]()
  private var recruitUsers = [FirebaseUser]()
  private var lastStory: QueryDocumentSnapshot?
  private var stories = [FirebaseStory]()
  private var storyVideoAssets = [String: AVAsset]()
  private var storyUsers = [FirebaseUser]()
  private var lastQna: QueryDocumentSnapshot?
  private var qnas = [FirebaseQna]()
  private var qnaUsers = [FirebaseUser]()
  private var supportRecruits = [String: FirebaseRecruit?]()

  private let COUNT_LAST_CELL: Int = 4
  
  private var beforeVideoViewCell: ANIVideoStoryViewCell?

  private var isFollowed: Bool?
  
  private var user: FirebaseUser? {
    didSet {
      checkFollowed()
      loadRecruit()
      loadStory()
      loadQna()
    }
  }
  
  var userId: String? {
    didSet {
      loadUser(sender: nil)
    }
  }
  
  private var isMenuChange: Bool = false
  
  private var isLoading: Bool = false
  private var isLastRecruitPage: Bool = false
  private var isLastStoryPage: Bool = false
  private var isLastQnaPage: Bool = false
  private var recruitCellHeight = [IndexPath: CGFloat]()
  private var storyCellHeight = [IndexPath: CGFloat]()
  private var qnaCellHeight = [IndexPath: CGFloat]()
  
  private var scollViewContentOffsetY: CGFloat = 0.0
  
  var delegate: ANIOtherProfileBasicViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    let basicTableView = UITableView()
    basicTableView.backgroundColor = ANIColor.bg
    basicTableView.separatorStyle = .none
    basicTableView.dataSource = self
    basicTableView.delegate = self
    let topCellId = NSStringFromClass(ANIOtherProfileTopCell.self)
    basicTableView.register(ANIOtherProfileTopCell.self, forCellReuseIdentifier: topCellId)
    let profileCellid = NSStringFromClass(ANIOtherProfileCell.self)
    basicTableView.register(ANIOtherProfileCell.self, forCellReuseIdentifier: profileCellid)
    let recruitCellid = NSStringFromClass(ANIRecruitViewCell.self)
    basicTableView.register(ANIRecruitViewCell.self, forCellReuseIdentifier: recruitCellid)
    let storyCellid = NSStringFromClass(ANIStoryViewCell.self)
    basicTableView.register(ANIStoryViewCell.self, forCellReuseIdentifier: storyCellid)
    let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
    basicTableView.register(ANIVideoStoryViewCell.self, forCellReuseIdentifier: videoStoryCellId)
    let supportCellId = NSStringFromClass(ANISupportViewCell.self)
    basicTableView.register(ANISupportViewCell.self, forCellReuseIdentifier: supportCellId)
    let qnaCellid = NSStringFromClass(ANIQnaViewCell.self)
    basicTableView.register(ANIQnaViewCell.self, forCellReuseIdentifier: qnaCellid)
    basicTableView.alpha = 0.0
    basicTableView.rowHeight = UITableView.automaticDimension
    let refreshControl = UIRefreshControl()
    refreshControl.backgroundColor = .clear
    refreshControl.tintColor = ANIColor.moreDarkGray
    refreshControl.addTarget(self, action: #selector(reloadData(sender:)), for: .valueChanged)
    basicTableView.addSubview(refreshControl)
    addSubview(basicTableView)
    basicTableView.edgesToSuperview()
    self.basicTableView = basicTableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  func playVideo() {
    guard let basicTableView = self.basicTableView else { return }
    
    let centerX = basicTableView.center.x
    let centerY = basicTableView.center.y + scollViewContentOffsetY + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = basicTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = basicTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        storyVideoView.play()
      }
    }
  }
  
  func stopVideo() {
    guard let basicTableView = self.basicTableView else { return }
    
    let centerX = basicTableView.center.x
    let centerY = basicTableView.center.y + scollViewContentOffsetY + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = basicTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = basicTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        storyVideoView.stop()
      }
    }
  }
  
  private func checkFollowed() {
    guard let user = self.user,
          let userId = user.uid,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    if let currentUserId = ANISessionManager.shared.currentUserUid {
      let database = Firestore.firestore()

      DispatchQueue.global().async {
        database.collection(KEY_USERS).document(currentUserId).collection(KEY_FOLLOWING_USER_IDS).getDocuments(completion: { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            
            return
          }
          
          guard let snapshot = snapshot else { return }
          
          for document in snapshot.documents {
            if document.documentID == userId {
              self.isFollowed = true
              
              break
            } else {
              self.isFollowed = false
            }
          }
          
          if snapshot.documents.isEmpty {
            self.isFollowed = false
          }
          
          DispatchQueue.main.async {
            guard let basicTableView = self.basicTableView else { return }
            
            basicTableView.reloadData()
            
            activityIndicatorView.stopAnimating()
            
            UIView.animate(withDuration: 0.2, animations: {
              basicTableView.alpha = 1.0
            })
          }
        })
      }
    } else {
      self.isFollowed = false
      
      guard let basicTableView = self.basicTableView else { return }
      
      basicTableView.reloadData()
      
      activityIndicatorView.stopAnimating()
      
      UIView.animate(withDuration: 0.2, animations: {
        basicTableView.alpha = 1.0
      })
    }
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(deleteRecruit: self, selector: #selector(deleteRecruit))
    ANINotificationManager.receive(deleteStory: self, selector: #selector(deleteStory))
    ANINotificationManager.receive(deleteQna: self, selector: #selector(deleteQna))
  }
  
  @objc private func reloadData(sender: UIRefreshControl?) {
    loadUser(sender: sender)
  }
  
  private func unobserveBeforeMenu() {
    guard let basicTableView = self.basicTableView else { return }
    
    if contentType == .recruit {
      for i in 0 ..< recruits.count {
        if let recruitCell = basicTableView.cellForRow(at: [1, i]) as? ANIRecruitViewCell {
          recruitCell.unobserveLove()
          recruitCell.unobserveSupport()
        }
      }
    } else if contentType == .story {
      for i in 0 ..< stories.count {
        if let storyCell = basicTableView.cellForRow(at: [1, i]) as? ANIStoryViewCell {
          storyCell.unobserveLove()
          storyCell.unobserveComment()
        } else if let supportCell = basicTableView.cellForRow(at: [1, i]) as? ANISupportViewCell {
          supportCell.unobserveLove()
          supportCell.unobserveComment()
        }
      }
    } else if contentType == .qna {
      for i in 0 ..< qnas.count {
        if let qnaCell = basicTableView.cellForRow(at: [1, i]) as? ANIQnaViewCell {
          qnaCell.unobserveLove()
          qnaCell.unobserveComment()
        }
      }
    }
  }
  
  @objc private func deleteRecruit(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let basicTableView = self.basicTableView else { return }
    
    var indexPath: IndexPath = [0, 0]
    
    for (index, recruit) in recruits.enumerated() {
      if recruit.id == id {
        recruits.remove(at: index)
        
        if !recruits.isEmpty {
          basicTableView.beginUpdates()
          let indexPath: IndexPath = [1, index]
          basicTableView.deleteRows(at: [indexPath], with: .automatic)
          basicTableView.endUpdates()
        } else {
          basicTableView.reloadData()
        }
      }
    }
  }
  
  @objc private func deleteStory(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let basicTableView = self.basicTableView else { return }
    
    var indexPath: IndexPath = [0, 0]
    
    for (index, story) in stories.enumerated() {
      if story.id == id {
        stories.remove(at: index)
        
        if !stories.isEmpty {
          basicTableView.beginUpdates()
          let indexPath: IndexPath = [1, index]
          basicTableView.deleteRows(at: [indexPath], with: .automatic)
          basicTableView.endUpdates()
        } else {
          basicTableView.reloadData()
        }
      }
    }
  }
  
  @objc private func deleteQna(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let basicTableView = self.basicTableView else { return }
    
    var indexPath: IndexPath = [0, 0]
    
    for (index, qna) in qnas.enumerated() {
      if qna.id == id {
        qnas.remove(at: index)
        
        if !qnas.isEmpty {
          basicTableView.beginUpdates()
          let indexPath: IndexPath = [1, index]
          basicTableView.deleteRows(at: [indexPath], with: .automatic)
          basicTableView.endUpdates()
        } else {
          basicTableView.reloadData()
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
extension ANIOtherProfileBasicView: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 2
  }
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else {
      if contentType == .profile {
        tableView.backgroundColor = .white
        return 1
      } else if contentType == .recruit {
        tableView.backgroundColor = ANIColor.bg
        return recruits.count
      } else if contentType == .story {
        tableView.backgroundColor = ANIColor.bg
        return stories.count
      } else {
        tableView.backgroundColor = ANIColor.bg
        return qnas.count
      }
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let section = indexPath.section
    
    if section == 0 {
      let topCellId = NSStringFromClass(ANIOtherProfileTopCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: topCellId, for: indexPath) as! ANIOtherProfileTopCell
      cell.delegate = self

      cell.selectedIndex = contentType.rawValue
      cell.user = user
      
      if let bottomSpace = cell.bottomSpace {
        if contentType == .recruit {
          bottomSpace.isHidden = false
        } else {
          bottomSpace.isHidden = true
        }
      }
      
      return cell
    } else {
      if contentType == .profile {
        let profileCellid = NSStringFromClass(ANIOtherProfileCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: profileCellid, for: indexPath) as! ANIOtherProfileCell
        cell.delegate = self

        cell.user = user
        if let isFollowed = self.isFollowed {
          cell.isFollowed = isFollowed
        }
        
        return cell
      } else if contentType == .recruit {
        let recruitCellid = NSStringFromClass(ANIRecruitViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: recruitCellid, for: indexPath) as! ANIRecruitViewCell
        cell.delegate = self

        if recruitUsers.contains(where: { $0.uid == recruits[indexPath.row].userId }) {
          for user in recruitUsers {
            if recruits[indexPath.row].userId == user.uid {
              cell.user = user
              break
            }
          }
        } else {
          cell.user = nil
        }
        cell.indexPath = indexPath.row
        cell.recruit = recruits[indexPath.row]
        
        return cell
      } else if contentType == .story {
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
            
            if storyUsers.contains(where: { $0.uid == stories[indexPath.row].userId }) {
              for user in storyUsers {
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
            
            if storyUsers.contains(where: { $0.uid == stories[indexPath.row].userId }) {
              for user in storyUsers {
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
            cell.delegate = self

            if storyUsers.contains(where: { $0.uid == stories[indexPath.row].userId }) {
              for user in storyUsers {
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
          }
        } else {
          return UITableViewCell()
        }
      } else {
        let qnaCellid = NSStringFromClass(ANIQnaViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: qnaCellid, for: indexPath) as! ANIQnaViewCell
        cell.delegate = self

        if qnaUsers.contains(where: { $0.uid == qnas[indexPath.row].userId }) {
          for user in qnaUsers {
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
}

//MARK: UITableViewDelegate
extension ANIOtherProfileBasicView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard !isMenuChange else { return }
    
    if contentType == .recruit, let cell = cell as? ANIRecruitViewCell {
      cell.unobserveLove()
      cell.unobserveSupport()
    } else if contentType == .story {
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
    } else if contentType == .qna, let cell = cell as? ANIQnaViewCell {
      cell.unobserveLove()
      cell.unobserveComment()
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if contentType == .recruit {
      let element = self.recruits.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreRecruit()
      }
      
      self.recruitCellHeight[indexPath] = cell.frame.size.height
    } else if contentType == .story {
      let element = self.stories.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreStory()
      }
      
      self.storyCellHeight[indexPath] = cell.frame.size.height
    } else if contentType == .qna {
      let element = self.qnas.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreQna()
      }
      
      self.qnaCellHeight[indexPath] = cell.frame.size.height
    }
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    switch contentType {
    case .recruit:
      if let height = self.recruitCellHeight[indexPath] {
        return height
      } else {
        return UITableView.automaticDimension
      }
    case .story:
      if let height = self.storyCellHeight[indexPath] {
        return height
      } else {
        return UITableView.automaticDimension
      }
    case .qna:
      if let height = self.qnaCellHeight[indexPath] {
        return height
      } else {
        return UITableView.automaticDimension
      }
    default:
      return UITableView.automaticDimension
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let basicTableView = self.basicTableView else { return }
    
    scollViewContentOffsetY = scrollView.contentOffset.y
    
    //play video
    let centerX = basicTableView.center.x
    let centerY = basicTableView.center.y + scrollView.contentOffset.y + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = basicTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = basicTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
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

//MARK: ANIProfileTopCellDelegate
extension ANIOtherProfileBasicView: ANIOtherProfileTopCellDelegate {
  func didSelecteMenuItem(selectedIndex: Int) {
    guard let basicTableView = self.basicTableView else { return }
    
    isMenuChange = true
    unobserveBeforeMenu()
    
    switch selectedIndex {
    case ContentType.profile.rawValue:
      contentType = .profile
    case ContentType.story.rawValue:
      contentType = .story
    case ContentType.recruit.rawValue:
      contentType = .recruit
    case ContentType.qna.rawValue:
      contentType = .qna
    default:
      DLog("default")
    }
    
    basicTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
  }
  
  func presentImageBrowser(index: Int, imageUrls: [String]) {
    self.delegate?.presentImageBrowser(index: index, imageUrls: imageUrls)
  }
}

//MARK: ANIOtherProfileCellDelegate
extension ANIOtherProfileBasicView: ANIOtherProfileCellDelegate {
  func followingTapped() {
    self.delegate?.followingTapped()
  }
  
  func followerTapped() {
    self.delegate?.followerTapped()
  }
  
  func twitterOpenReject() {
    self.delegate?.twitterOpenReject()
  }
  
  func instagramOpenReject() {
    self.delegate?.instagramOpenReject()
  }
  
  func openUrl(url: URL) {
    self.delegate?.openUrl(url: url)
  }
}

//MARK: ANIRecruitViewCellDelegate
extension ANIOtherProfileBasicView: ANIRecruitViewCellDelegate {
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.supportButtonTapped(supportRecruit: supportRecruit, user: user)
  }
  
  func cellTapped(recruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.recruitViewCellDidSelect(selectedRecruit: recruit, user: user)
  }
  
  func reject() {
    self.delegate?.reject()
  }
  
  func loadedRecruitIsLoved(indexPath: Int, isLoved: Bool) {
    var recruit = self.recruits[indexPath]
    recruit.isLoved = isLoved
    self.recruits[indexPath] = recruit
  }
  
  func loadedRecruitIsCliped(indexPath: Int, isCliped: Bool) {
    var recruit = self.recruits[indexPath]
    recruit.isCliped = isCliped
    self.recruits[indexPath] = recruit
  }
  
  func loadedRecruitIsSupported(indexPath: Int, isSupported: Bool) {
    var recruit = self.recruits[indexPath]
    recruit.isSupported = isSupported
    self.recruits[indexPath] = recruit
  }
  
  func loadedRecruitUser(user: FirebaseUser) {
    self.recruitUsers.append(user)
  }
}

//MARK: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate
extension ANIOtherProfileBasicView: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate {
  func storyCellTapped(story: FirebaseStory, user: FirebaseUser) {
    self.delegate?.storyViewCellDidSelect(selectedStory: story, user: user)
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.delegate?.popupOptionView(isMe: isMe, contentType: contentType, id: id)
  }

  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool) {
    var story = self.stories[indexPath]
    story.isLoved = isLoved
    self.stories[indexPath] = story
  }
  
  func loadedStoryUser(user: FirebaseUser) {
    self.storyUsers.append(user)
  }
  
  func loadedVideo(urlString: String, asset: AVAsset) {
    storyVideoAssets[urlString] = asset
  }
}

//MARK: ANISupportViewCellDelegate
extension ANIOtherProfileBasicView: ANISupportViewCellDelegate {
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
extension ANIOtherProfileBasicView: ANIQnaViewCellDelegate {
  func cellTapped(qna: FirebaseQna, user: FirebaseUser) {
    self.delegate?.qnaViewCellDidSelect(selectedQna: qna, user: user)
  }
  
  func loadedQnaIsLoved(indexPath: Int, isLoved: Bool) {
    var qna = self.qnas[indexPath]
    qna.isLoved = isLoved
    self.qnas[indexPath] = qna
  }
  
  func loadedQnaUser(user: FirebaseUser) {
    self.qnaUsers.append(user)
  }
}

//MARK: data
extension ANIOtherProfileBasicView {
  private func loadUser(sender: UIRefreshControl?) {
    guard let userId = self.userId,
          let activityIndicatorView = self.activityIndicatorView else { return }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_USERS).document(userId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          if let sender = sender {
            sender.endRefreshing()
          }
          
          return
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let user = try FirebaseDecoder().decode(FirebaseUser.self, from: data)
          self.user = user
          
          DispatchQueue.main.async {
            self.delegate?.loadedUser(user: user)
            
            guard let basicTableView = self.basicTableView else { return }
            
            basicTableView.reloadData()
            
            if let sender = sender {
              sender.endRefreshing()
            }
          }
        } catch let error {
          DLog(error)
          
          if let sender = sender {
            sender.endRefreshing()
          }
        }
      })
    }
  }
  
  private func loadRecruit() {
    guard let user = self.user,
          let uid = user.uid,
          let basicTableView = self.basicTableView else { return }

    
    if !self.recruits.isEmpty {
      self.recruits.removeAll()
    }
    if !self.recruitUsers.isEmpty {
      self.recruitUsers.removeAll()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastStoryPage = false
      
      database.collection(KEY_RECRUITS).whereField(KEY_USER_ID, isEqualTo: uid).order(by: KEY_DATE, descending: true).limit(to: 15).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false

          return
        }
        
        guard let snapshot = snapshot,
              let lastRecruit = snapshot.documents.last else {
                self.isLoading = false
                return }
        
        self.lastRecruit = lastRecruit
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: document.data())
            if !self.isBlockRecruit(recruit: recruit) {
              self.recruits.append(recruit)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                basicTableView.reloadData()
                
                self.isLoading = false
                
                if self.recruits.isEmpty {
                  self.loadMoreRecruit()
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
  
  private func loadMoreRecruit() {
    guard let basicTableView = self.basicTableView,
          let lastRecruit = self.lastRecruit,
          let user = self.user,
          let uid = user.uid,
          !isLoading,
          !isLastRecruitPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_RECRUITS).whereField(KEY_USER_ID, isEqualTo: uid).order(by: KEY_DATE, descending: true).start(afterDocument: lastRecruit).limit(to: 15).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }

        guard let snapshot = snapshot else { return }
        guard let lastRecruit = snapshot.documents.last else {
          self.isLastRecruitPage = true
          self.isLoading = false
          return
        }
        
        self.lastRecruit = lastRecruit
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: document.data())
            if !self.isBlockRecruit(recruit: recruit) {
              self.recruits.append(recruit)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                basicTableView.reloadData()
                
                self.isLoading = false
                
                if self.recruits.isEmpty {
                  self.loadMoreRecruit()
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
  
  private func loadStory() {
    guard let user = self.user,
          let uid = user.uid,
          let basicTableView = self.basicTableView else { return }
    
    if !self.stories.isEmpty {
      self.stories.removeAll()
    }
    if !self.supportRecruits.isEmpty {
      self.supportRecruits.removeAll()
    }
    if !self.storyUsers.isEmpty {
      self.storyUsers.removeAll()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastStoryPage = false

      database.collection(KEY_STORIES).whereField(KEY_USER_ID, isEqualTo: uid).order(by: KEY_DATE, descending: true).limit(to: 10).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastStory = snapshot.documents.last else {
                self.isLoading = false
                return }
        
        self.lastStory = lastStory
        
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
                basicTableView.reloadData()
                
                self.isLoading = false
                
                if self.stories.isEmpty {
                  self.loadMoreStory()
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
  
  private func loadMoreStory() {
    guard let basicTableView = self.basicTableView,
          let lastStory = self.lastStory,
          let user = self.user,
          let uid = user.uid,
          !isLoading,
          !isLastStoryPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_STORIES).whereField(KEY_USER_ID, isEqualTo: uid).order(by: KEY_DATE, descending: true).start(afterDocument: lastStory).limit(to: 10).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastStory = snapshot.documents.last else {
          self.isLastStoryPage = true
          self.isLoading = false
          return
        }
        
        self.lastStory = lastStory
        
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
                basicTableView.reloadData()
                
                self.isLoading = false
                
                if self.stories.isEmpty {
                  self.loadMoreStory()
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
  
  private func loadQna() {
    guard let user = self.user,
          let uid = user.uid,
          let basicTableView = self.basicTableView else { return }
    
    if !self.qnas.isEmpty {
      self.qnas.removeAll()
    }
    if !self.qnaUsers.isEmpty {
      self.qnaUsers.removeAll()
    }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastQnaPage = false

      database.collection(KEY_QNAS).whereField(KEY_USER_ID, isEqualTo: uid).order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot,
              let lastQna = snapshot.documents.last else {
                
                self.isLoading = false
                return }
        
        self.lastQna = lastQna
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let qna = try FirestoreDecoder().decode(FirebaseQna.self.self, from: document.data())
            if !self.isBlockQna(qna: qna) {
              self.qnas.append(qna)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                basicTableView.reloadData()
                
                self.isLoading = false
                
                if self.qnas.isEmpty {
                  self.loadMoreQna()
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
  
  private func loadMoreQna() {
    guard let basicTableView = self.basicTableView,
          let lastQna = self.lastQna,
          let user = self.user,
          let uid = user.uid,
          !isLoading,
          !isLastQnaPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_QNAS).whereField(KEY_USER_ID, isEqualTo: uid).order(by: KEY_DATE, descending: true).start(afterDocument: lastQna).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastQna = snapshot.documents.last else {
          self.isLastQnaPage = true
          self.isLoading = false
          return
        }
        
        self.lastQna = lastQna
        
        for (index, document) in snapshot.documents.enumerated() {
          do {
            let qna = try FirestoreDecoder().decode(FirebaseQna.self, from: document.data())
            if !self.isBlockQna(qna: qna) {
              self.qnas.append(qna)
            }
            
            DispatchQueue.main.async {
              if index + 1 == snapshot.documents.count {
                basicTableView.reloadData()
                
                self.isLoading = false
                
                if self.qnas.isEmpty {
                  self.loadMoreQna()
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
