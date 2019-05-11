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
import AVKit
import UserNotifications
import TinyConstraints

protocol ANIStoryViewDelegate {
  func didSelectStoryViewCell(selectedStory: FirebaseStory, user: FirebaseUser)
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser)
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
  func didSelectRankingCell(rankingStory: FirebaseStory, ranking: Int)
  func showEvent(event: FirebaseEvent)
}

class ANIStoryView: UIView {
  
  private weak var reloadView: ANIReloadView?
  
  private weak var storyTableView: UITableView?
  
  private weak var refreshControl: UIRefreshControl?
  
  private let NEW_STORY_BUTTON_OFFSET: CGFloat = ANICommunityViewController.NAVIGATION_BAR_HEIGHT + 7.0
  private let NEW_STORY_BUTTON_HEIGHT: CGFloat = 30.0
  private var newStoryButtonTopConstraint: Constraint?
  private weak var newStoryButton: ANIAreaButtonView?
  private weak var arrowImageView: UIImageView?
  private weak var newStoryLabel: UILabel?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  private var stories = [FirebaseStory]()
  private var supportRecruits = [String: FirebaseRecruit?]()
  private var storyVideoAssets = [String: AVAsset]()
  private var rankingStories = [FirebaseStory]()
  private var users = [FirebaseUser]()
  
  private var isLastStoryPage: Bool = false
  private var lastStory: QueryDocumentSnapshot?
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  private var lastRankingStory: QueryDocumentSnapshot?
  
  private var isLoadedFirstData: Bool = false
  private var isNewStory: Bool = false
  private var isShowNewStoryButton: Bool = false
  
  private var isLoadedStoryComment: Bool = false
  private var isLoadedRankingStoryComment: Bool = false
  
  private var scrollBeginingPoint: CGPoint?
  
  var isCellSelected: Bool = false {
    didSet {
      if isCellSelected {
        playVideo()
      } else {
        stopVideo()
      }
    }
  }
  
  private var beforeVideoViewCell: ANIVideoStoryViewCell?
  
  var delegate: ANIStoryViewDelegate?
  
  static var shared: ANIStoryView?
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  private var scollViewContentOffsetY: CGFloat = 0.0
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    setupNotifications()
    observeStory()
    
    if ANISessionManager.shared.isLaunchNoti {
      loadStory(sender: nil)
    }
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
    
    //tableView
    let tableView = UITableView()
    tableView.contentInset = UIEdgeInsets(top: ANICommunityViewController.NAVIGATION_BAR_HEIGHT, left: 0, bottom: 0, right: 0)
    tableView.scrollIndicatorInsets  = UIEdgeInsets(top: UIViewController.NAVIGATION_BAR_HEIGHT, left: 0, bottom: 0, right: 0)
    let storyCellId = NSStringFromClass(ANIStoryViewCell.self)
    tableView.register(ANIStoryViewCell.self, forCellReuseIdentifier: storyCellId)
    let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
    tableView.register(ANIVideoStoryViewCell.self, forCellReuseIdentifier: videoStoryCellId)
    let supportCellId = NSStringFromClass(ANISupportViewCell.self)
    tableView.register(ANISupportViewCell.self, forCellReuseIdentifier: supportCellId)
    let rankingCellId = NSStringFromClass(ANIRankingViewCell.self)
    tableView.register(ANIRankingViewCell.self, forCellReuseIdentifier: rankingCellId)
    tableView.separatorStyle = .none
    tableView.backgroundColor = ANIColor.bg
    tableView.dataSource = self
    tableView.delegate = self
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
    self.storyTableView = tableView
    
    //newStoryButton
    let newStoryButton = ANIAreaButtonView()
    newStoryButton.base?.backgroundColor = ANIColor.emerald
    newStoryButton.baseCornerRadius = NEW_STORY_BUTTON_HEIGHT / 2
    newStoryButton.dropShadow(opacity: 0.1)
    newStoryButton.delegate = self
    addSubview(newStoryButton)
    newStoryButtonTopConstraint = newStoryButton.topToSuperview(offset: -NEW_STORY_BUTTON_HEIGHT, usingSafeArea: true)
    newStoryButton.centerXToSuperview()
    newStoryButton.width(160.0)
    newStoryButton.height(NEW_STORY_BUTTON_HEIGHT)
    self.newStoryButton = newStoryButton
    
    //newStoryLabel
    let newStoryLabel = UILabel()
    newStoryLabel.text = "新しいストーリー"
    newStoryLabel.textAlignment = .center
    newStoryLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
    newStoryLabel.textColor = .white
    newStoryButton.addContent(newStoryLabel)
    newStoryLabel.centerXToSuperview(offset: 8.0)
    newStoryLabel.centerYToSuperview()
    self.newStoryLabel = newStoryLabel
    
    //arrowImageView
    let arrowImageView = UIImageView()
    arrowImageView.image = UIImage(named: "arrow")
    arrowImageView.contentMode = .scaleAspectFit
    newStoryButton.addContent(arrowImageView)
    arrowImageView.centerYToSuperview()
    arrowImageView.rightToLeft(of: newStoryLabel, offset: -5.0)
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
  
  @objc private func reloadData(sender:  UIRefreshControl?) {
    hideNewStoryButton()
    isNewStory = false
    
    loadStory(sender: sender)
  }
  
  static func endRefresh() {
    guard let shared = ANIStoryView.shared,
          let refreshControl = shared.refreshControl,
          let storyTableView = shared.storyTableView else { return }
    
    refreshControl.endRefreshing()
    
    let topInset = ANICommunityViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    if storyTableView.contentOffset.y + topInset < 0 {
      storyTableView.scrollToRow(at: [0, 0], at: .top, animated: false)
    }
  }
  
  func playVideo() {
    guard let storyTableView = self.storyTableView else { return }
    
    let centerX = storyTableView.center.x
    let centerY = storyTableView.center.y + scollViewContentOffsetY + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = storyTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = storyTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        storyVideoView.play()
      }
    }
  }

  func stopVideo() {
    guard let storyTableView = self.storyTableView else { return }
    
    let centerX = storyTableView.center.x
    let centerY = storyTableView.center.y + scollViewContentOffsetY + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    
    if let indexPath = storyTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = storyTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
        let storyVideoView = videoCell.storyVideoView {
        storyVideoView.stop()
      }
    }
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    ANINotificationManager.receive(logout: self, selector: #selector(reloadStory))
    ANINotificationManager.receive(communityTabTapped: self, selector: #selector(scrollToTop))
    ANINotificationManager.receive(deleteStory: self, selector: #selector(deleteStory))
    ANINotificationManager.receive(loadedCurrentUser: self, selector: #selector(reloadStory))
    ANINotificationManager.postDidSetupViewNotifications()
  }
  
  @objc private func reloadStory() {
    guard let storyTableView = self.storyTableView else { return }
    
    hideNewStoryButton()
    isNewStory = false

    storyTableView.alpha = 0.0
    
    loadStory(sender: nil)
  }
  
  @objc private func scrollToTop() {
    guard let storyTableView = storyTableView,
          !stories.isEmpty,
          isCellSelected else { return }
    
    storyTableView.scrollToRow(at: [0, 0], at: .top, animated: true)
  }
  
  @objc private func deleteStory(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let storyTableView = self.storyTableView else { return }
    
    for (index, story) in stories.enumerated() {
      if story.id == id {
        stories.remove(at: index)
        
        if !stories.isEmpty {
          storyTableView.beginUpdates()
          var indexPath: IndexPath = [0, 0]
          if rankingStories.isEmpty {
            indexPath = [0, index]
          } else {
            indexPath = [0, index + 1]
          }
          storyTableView.deleteRows(at: [indexPath], with: .automatic)
          storyTableView.endUpdates()
        } else {
          storyTableView.reloadData()
          storyTableView.alpha = 0.0
          showReloadView(sender: nil)
        }
      }
    }
  }
  
  private func showReloadView(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView,
          let storyTableView = self.storyTableView else { return }
    
    activityIndicatorView.stopAnimating()
    
    storyTableView.reloadData()
    storyTableView.alpha = 0.0
    
    if let sender = sender {
      sender.endRefreshing()
    }
    
    UIView.animate(withDuration: 0.2, animations: {
      reloadView.alpha = 1.0
    }) { (complete) in
      ANISessionManager.shared.isLoadedFirstData = true
      ANINotificationManager.postDismissSplash()
    }
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
  
  private func setPushNotification() {
    if ANISessionManager.shared.currentUser != nil {
      UNUserNotificationCenter.current().getNotificationSettings { (settings) in
        if settings.authorizationStatus != .authorized {
          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { _, _ in
            DLog("push permission finished")
          }
        }
      }
    }
  }
  
  private func observeStory() {
    let database = Firestore.firestore()
    
    database.collection(KEY_STORIES).order(by: KEY_DATE, descending: true).limit(to: 1).addSnapshotListener { (snapshot, error) in
      if let error = error {
        DLog("stories observe error \(error)")
        return
      }
      
      guard let snapshot = snapshot else { return }
      
      snapshot.documentChanges.forEach({ (diff) in
        if diff.type == .added && self.isLoadedFirstData {
          self.isNewStory = true
          self.showNewStoryButton()
        }
      })
    }
  }
  
  private func showNewStoryButton() {
    guard let newStoryButtonTopConstraint = self.newStoryButtonTopConstraint,
          isNewStory,
          !isShowNewStoryButton else { return }
    
    isShowNewStoryButton = true

    newStoryButtonTopConstraint.constant = self.NEW_STORY_BUTTON_OFFSET
    
    UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
      self.layoutIfNeeded()
    }, completion: nil)
  }
  
  private func hideNewStoryButton() {
    guard let newStoryButtonTopConstraint = self.newStoryButtonTopConstraint,
          isNewStory,
          isShowNewStoryButton else { return }
    
    isShowNewStoryButton = false

    newStoryButtonTopConstraint.constant = -self.NEW_STORY_BUTTON_HEIGHT
    
    UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
      self.layoutIfNeeded()
    }, completion: nil)
  }
}

//MARK: UITableViewDataSource
extension ANIStoryView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if rankingStories.isEmpty {
      return stories.count
    } else {
      return stories.count + 1
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if rankingStories.isEmpty {
      if !stories.isEmpty && stories.count > indexPath.row {
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
          
          if let comments = stories[indexPath.row].comments {
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
          
          if let comments = stories[indexPath.row].comments {
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
          cell.story = stories[indexPath.row]
          
          return cell
        } else {
          let storyCellId = NSStringFromClass(ANIStoryViewCell.self)
          let cell = tableView.dequeueReusableCell(withIdentifier: storyCellId, for: indexPath) as! ANIStoryViewCell
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
          
          if let comments = stories[indexPath.row].comments {
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
          cell.story = stories[indexPath.row]
          
          return cell
        }
      } else {
        return UITableViewCell()
      }
    } else {
      if indexPath.row == 0 {
        let rankingCellId = NSStringFromClass(ANIRankingViewCell.self)
        let cell = tableView.dequeueReusableCell(withIdentifier: rankingCellId, for: indexPath) as! ANIRankingViewCell
        cell.delegate = self
        
        cell.rankingStories = rankingStories
        
        return cell
      } else {
        if !stories.isEmpty && stories.count > indexPath.row - 1 {
          if let recruitId = stories[indexPath.row - 1].recruitId {
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
            
            if users.contains(where: { $0.uid == stories[indexPath.row - 1].userId }) {
              for user in users {
                if stories[indexPath.row - 1].userId == user.uid {
                  cell.user = user
                  break
                }
              }
            } else {
              cell.user = nil
            }
            
            if let comments = stories[indexPath.row - 1].comments {
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
            
            cell.indexPath = indexPath.row - 1
            cell.story = stories[indexPath.row - 1]
            
            return cell
          } else if stories[indexPath.row - 1].thumbnailImageUrl != nil {
            let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: videoStoryCellId, for: indexPath) as! ANIVideoStoryViewCell
            cell.delegate = self
            
            if users.contains(where: { $0.uid == stories[indexPath.row - 1].userId }) {
              for user in users {
                if stories[indexPath.row - 1].userId == user.uid {
                  cell.user = user
                  break
                }
              }
            } else {
              cell.user = nil
            }
            
            if let comments = stories[indexPath.row - 1].comments {
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
            
            if let storyVideoUrl = stories[indexPath.row - 1].storyVideoUrl,
              storyVideoAssets.contains(where: { $0.0 == storyVideoUrl }) {
              cell.videoAsset = storyVideoAssets[storyVideoUrl]
            } else {
              cell.videoAsset = nil
            }
            
            cell.indexPath = indexPath.row - 1
            cell.story = stories[indexPath.row - 1]
            
            return cell
          } else {
            let storyCellId = NSStringFromClass(ANIStoryViewCell.self)
            let cell = tableView.dequeueReusableCell(withIdentifier: storyCellId, for: indexPath) as! ANIStoryViewCell
            cell.delegate = self

            if users.contains(where: { $0.uid == stories[indexPath.row - 1].userId }) {
              for user in users {
                if stories[indexPath.row - 1].userId == user.uid {
                  cell.user = user
                  break
                }
              }
            } else {
              cell.user = nil
            }
            
            if let comments = stories[indexPath.row - 1].comments {
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
            
            cell.indexPath = indexPath.row - 1
            cell.story = stories[indexPath.row - 1]
            
            return cell
          }
        } else {
          return UITableViewCell()
        }
      }
    }
  }
}

//MARK: UITableViewDelegate
extension ANIStoryView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if rankingStories.isEmpty {
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
    } else {
      if indexPath.row != 0, !stories.isEmpty && stories.count > indexPath.row - 1 {
        if stories[indexPath.row - 1].recruitId != nil, let cell = cell as? ANISupportViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
        } else if stories[indexPath.row - 1].thumbnailImageUrl != nil, let cell = cell as? ANIVideoStoryViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
          cell.storyVideoView?.removeReachEndObserver()
          cell.storyVideoView?.stop()
        } else if let cell = cell as? ANIStoryViewCell {
          cell.unobserveLove()
          cell.unobserveComment()
        }
      }
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if rankingStories.isEmpty {
      let element = self.stories.count - COUNT_LAST_CELL
      
      if !isLoading, indexPath.row >= element {
        loadMoreStory(sender: nil)
      }
    } else {
      if indexPath.row != 0 {
        let element = self.stories.count - COUNT_LAST_CELL
        
        if !isLoading, indexPath.row - 1 >= element {
          loadMoreStory(sender: nil)
        }
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
  
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    scrollBeginingPoint = scrollView.contentOffset
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let storyTableView = self.storyTableView else { return }
    
    scollViewContentOffsetY = scrollView.contentOffset.y
    
    //play video
    let centerX = storyTableView.center.x
    let centerY = storyTableView.center.y + scrollView.contentOffset.y + UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT

    if let indexPath = storyTableView.indexPathForRow(at: CGPoint(x: centerX, y: centerY)) {
      if let videoCell = storyTableView.cellForRow(at: indexPath) as? ANIVideoStoryViewCell,
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
    
    //new story button show or hide
    if let scrollBeginingPoint = self.scrollBeginingPoint {
      if scrollBeginingPoint.y < scrollView.contentOffset.y {
        hideNewStoryButton()
      } else {
        showNewStoryButton()
      }
    }
  }
}

//MARK: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate
extension ANIStoryView: ANIStoryViewCellDelegate, ANIVideoStoryViewCellDelegate {
  func storyCellTapped(story: FirebaseStory, user: FirebaseUser) {
    self.delegate?.didSelectStoryViewCell(selectedStory: story, user: user)
  }
  
  func reject() {
    self.delegate?.reject()
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.delegate?.popupOptionView(isMe: isMe, contentType: contentType, id: id)
  }
  
  func loadedStoryIsLoved(indexPath: Int, isLoved: Bool) {
    if !self.stories.isEmpty && stories.count > indexPath {
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
}

//MARK: ANISupportViewCellDelegate
extension ANIStoryView: ANISupportViewCellDelegate {
  func supportCellTapped(story: FirebaseStory, user: FirebaseUser) {
    self.delegate?.didSelectStoryViewCell(selectedStory: story, user: user)
  }
  
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.supportCellRecruitTapped(recruit: recruit, user: user)
  }
  
  func loadedRecruit(recruitId: String, recruit: FirebaseRecruit?) {
    self.supportRecruits[recruitId] = recruit
  }
}

//MARK: ANIRankingViewCellDelegate
extension ANIStoryView: ANIRankingViewCellDelegate {
  func didSelectRankingCell(rankingStory: FirebaseStory, ranking: Int) {
    self.delegate?.didSelectRankingCell(rankingStory: rankingStory, ranking: ranking)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIStoryView: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    guard let storyTableView = self.storyTableView,
          let refreshControl = self.refreshControl else { return }
    
    hideNewStoryButton()
    isNewStory = false
    
    refreshControl.beginRefreshing()
    let offsetY = 60 + ANICommunityViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    storyTableView.setContentOffset(CGPoint(x: 0.0, y: -offsetY), animated: true)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.loadStory(sender: refreshControl)
    }
  }
}

//MARK: ANIReloadViewDelegate
extension ANIStoryView: ANIReloadViewDelegate {
  func reloadButtonTapped() {
    hideNewStoryButton()
    isNewStory = false
    
    loadStory(sender: nil)
  }
}

//MARK: data
extension ANIStoryView {
  private func loadStory(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView else { return }

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
    if !self.rankingStories.isEmpty {
      self.rankingStories.removeAll()
      ANINotificationManager.postReloadRankingStory()
    }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    let database = Firestore.firestore()
    
    let group = DispatchGroup()
    
    //story
    group.enter()
    DispatchQueue(label: "story").async {
      self.isLoading = true
      self.isLastStoryPage = false
      
      database.collection(KEY_STORIES).order(by: KEY_DATE, descending: true).limit(to: 15).getDocuments(completion: { (snapshot, error) in
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
    
    //ranking story
    if !self.rankingStories.isEmpty {
      self.rankingStories.removeAll()
    }
    
    let today = ANIFunction.shared.getToday(format: "yyyy/MM/dd")
    
    group.enter()
    DispatchQueue(label: "story").async {
      database.collection(KEY_STORIES).whereField(KEY_DAY, isEqualTo: today).order(by: KEY_LOVE_COUNT, descending: true).order(by: KEY_DATE, descending: true).limit(to: 3).getDocuments { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          group.leave()
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        if let lastRankingStory = snapshot.documents.last {
          self.lastRankingStory = lastRankingStory
          
          for (index, document) in snapshot.documents.enumerated() {
            do {
              let story = try FirestoreDecoder().decode(FirebaseStory.self, from: document.data())
              self.rankingStories.append(story)
              
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
        } else {
          group.leave()
        }
      }
    }
    
    group.notify(queue: DispatchQueue(label: "story")) {
      if self.lastStory != nil {
        if self.stories.isEmpty {
          self.loadMoreStory(sender: sender)
        } else {
          self.loadStoryComment(stories: self.stories, sender: sender)
        }
        
        if self.rankingStories.isEmpty {
          self.isLoadedRankingStoryComment = true
          self.loadDone(sender: sender)
        } else {
          self.loadRankingStoryComment(rankingStories: self.rankingStories, sender: sender)
        }
      } else {
        self.showReloadView(sender: sender)
      }
    }
  }
  
  private func loadMoreStory(sender: UIRefreshControl?) {
    guard let lastStory = self.lastStory,
          !isLoading,
          !isLastStoryPage else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      database.collection(KEY_STORIES).order(by: KEY_DATE, descending: true).start(afterDocument: lastStory).limit(to: 15).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        guard let lastStory = snapshot.documents.last else {
          self.isLastStoryPage = true
          self.isLoading = false
          
          if self.stories.isEmpty {
            self.showReloadView(sender: sender)
          }

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
                if self.stories.isEmpty {
                  self.loadMoreStory(sender: sender)
                } else {
                  self.loadStoryComment(stories: self.stories, sender: sender)
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
  
  private func loadStoryComment(stories: [FirebaseStory], sender: UIRefreshControl?) {
    isLoadedStoryComment = false
    
    let database = Firestore.firestore()
    
    var count = 0
    
    for (index, story) in stories.enumerated() {
      var commentsTemp = [FirebaseComment]()
      
      guard let storyId = story.id else { return }
      
      database.collection(KEY_STORIES).document(storyId).collection(KEY_COMMENTS).order(by: KEY_DATE, descending: true).limit(to: 2).getDocuments { (snapshot, error) in
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
              
              database.collection(KEY_STORIES).document(storyId).collection(KEY_COMMENTS).document(parentCommentId).getDocument(completion: { (parentCommentSnapshot, parentCommentError) in
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
                    
                    var storyTemp = story
                    storyTemp.comments = commentsTemp
                    self.stories[index] = storyTemp
                    
                    count = count + 1

                    if count == stories.count {
                      self.isLoadedStoryComment = true
                      self.loadDone(sender: sender)
                    }
                  } catch let error {
                    DLog(error)
                  }
                } else {
                  let parentComment = FirebaseComment(id: "", userId: "", comment: "", date: "", isLoved: nil, parentCommentId: nil, parentCommentUserId: nil)
                  
                  commentsTemp.append(parentComment)
                  commentsTemp.append(comment)
                  
                  var storyTemp = story
                  storyTemp.comments = commentsTemp
                  self.stories[index] = storyTemp
                  
                  count = count + 1
                  
                  if count == stories.count {
                    self.isLoadedStoryComment = true
                    self.loadDone(sender: sender)
                  }
                }
              })
            } else if !isParentComment {
              commentsTemp.append(comment)
  
              if snapshot.documents.count == commentsTemp.count {
                var storyTemp = story
                storyTemp.comments = commentsTemp.reversed()
                self.stories[index] = storyTemp
  
                count = count + 1
  
                if count == stories.count {
                  self.isLoadedStoryComment = true
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
          
          if count == stories.count {
            self.isLoadedStoryComment = true
            self.loadDone(sender: sender)
          }
        }
      }
    }
  }
  
  private func loadRankingStoryComment(rankingStories: [FirebaseStory], sender: UIRefreshControl?) {
    isLoadedRankingStoryComment = false

    let database = Firestore.firestore()
    
    var count = 0
    
    for (index, story) in rankingStories.enumerated() {
      var commentsTemp = [FirebaseComment]()
      
      guard let storyId = story.id else { return }
      
      database.collection(KEY_STORIES).document(storyId).collection(KEY_COMMENTS).order(by: KEY_DATE, descending: true).limit(to: 2).getDocuments { (snapshot, error) in
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
              
              database.collection(KEY_STORIES).document(storyId).collection(KEY_COMMENTS).document(parentCommentId).getDocument(completion: { (parentCommentSnapshot, parentCommentError) in
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
                    
                    var storyTemp = story
                    storyTemp.comments = commentsTemp
                    self.rankingStories[index] = storyTemp
                    
                    count = count + 1
                    
                    if count == rankingStories.count {
                      self.isLoadedRankingStoryComment = true
                      self.loadDone(sender: sender)
                    }
                  } catch let error {
                    DLog(error)
                  }
                } else {
                  let parentComment = FirebaseComment(id: "", userId: "", comment: "", date: "", isLoved: nil, parentCommentId: nil, parentCommentUserId: nil)
                  
                  commentsTemp.append(parentComment)
                  commentsTemp.append(comment)
                  
                  var storyTemp = story
                  storyTemp.comments = commentsTemp
                  self.rankingStories[index] = storyTemp
                  
                  count = count + 1
                  
                  if count == rankingStories.count {
                    self.isLoadedRankingStoryComment = true
                    self.loadDone(sender: sender)
                  }
                }
              })
            } else if !isParentComment {
              commentsTemp.append(comment)
              
              if snapshot.documents.count == commentsTemp.count {
                var storyTemp = story
                storyTemp.comments = commentsTemp.reversed()
                self.rankingStories[index] = storyTemp
                
                count = count + 1
                
                if count == rankingStories.count {
                  self.isLoadedRankingStoryComment = true
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
          
          if count == rankingStories.count {
            self.isLoadedRankingStoryComment = true
            self.loadDone(sender: sender)
          }
        }
      }
    }
  }
  
  private func loadDone(sender: UIRefreshControl?) {
    guard let storyTableView = self.storyTableView,
          let activityIndicatorView = self.activityIndicatorView,
          isLoadedStoryComment,
          isLoadedRankingStoryComment else { return }
    
    DispatchQueue.main.async {
      self.isLoading = false

      if let sender = sender {
        sender.endRefreshing()
      }
    
      storyTableView.reloadData()

      if storyTableView.alpha == 0.0 {
        activityIndicatorView.stopAnimating()

        UIView.animate(withDuration: 0.2, animations: {
          storyTableView.alpha = 1.0
        })
        ANISessionManager.shared.isLoadedFirstData = true
        self.isLoadedFirstData = true

        ANINotificationManager.postDismissSplash()
        self.setPushNotification()
      }
    }
  }
}
