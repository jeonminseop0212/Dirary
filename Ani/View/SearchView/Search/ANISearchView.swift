//
//  UserSearchView.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import CodableFirebase
import InstantSearchClient
import AVKit

protocol ANISearchViewDelegate {
  func searchViewDidScroll(scrollY: CGFloat)
  func storyViewCellDidSelect(selectedStory: FirebaseStory, user: FirebaseUser)
  func supportCellRecruitTapped(recruit: FirebaseRecruit, user: FirebaseUser)
  func qnaViewCellDidSelect(selectedQna: FirebaseQna, user:FirebaseUser)
  func reject()
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String)
}

enum SearchCategory: String {
  case user = "ユーザー";
  case qna = "Q&A";
}

class ANISearchView: UIView {
  
  private weak var tableView: UITableView?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  private var searchUsers = [FirebaseUser]()
  private var searchStories = [FirebaseStory]()
  private var storyVideoAssets = [String: AVAsset]()
  private var storyUsers = [FirebaseUser]()
  private var searchQnas = [FirebaseQna]()
  private var qnaUsers = [FirebaseUser]()
  private var supportRecruits = [String: FirebaseRecruit?]()

  var selectedCategory: SearchCategory = .user {
    didSet {
      if searchText != "" {
        guard let tableView = self.tableView else { return }

        UIView.animate(withDuration: 0.2) {
          tableView.alpha = 0.0
        }
        
        search(category: selectedCategory, searchText: searchText)
      }
    }
  }
  
  var searchText: String = "" {
    didSet {
      if searchText != "" {
        guard let tableView = self.tableView else { return }
        
        UIView.animate(withDuration: 0.2) {
          tableView.alpha = 0.0
        }
        
        search(category: selectedCategory, searchText: searchText)
      }
    }
  }
  
  private var category: SearchCategory = .user
  
  private var index: Index?
  private var nbPages = UInt()
  private var page: UInt = 0
  private let query = Query()
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  private var beforeVideoViewCell: ANIVideoStoryViewCell?
  
  private var userCellHeight = [IndexPath: CGFloat]()
  private var storyCellHeight = [IndexPath: CGFloat]()
  private var qnaCellHeight = [IndexPath: CGFloat]()
  
  var delegate: ANISearchViewDelegate?

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
    
    //tableView
    let tableView = UITableView()
    tableView.separatorStyle = .none
    let topInset = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT
    tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    tableView.scrollIndicatorInsets  = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    tableView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: false)
    tableView.backgroundColor = ANIColor.bg
    tableView.alpha = 0.0
    let userId = NSStringFromClass(ANIUserSearchViewCell.self)
    tableView.register(ANIUserSearchViewCell.self, forCellReuseIdentifier: userId)
    let storyId = NSStringFromClass(ANIStoryViewCell.self)
    tableView.register(ANIStoryViewCell.self, forCellReuseIdentifier: storyId)
    let videoStoryCellId = NSStringFromClass(ANIVideoStoryViewCell.self)
    tableView.register(ANIVideoStoryViewCell.self, forCellReuseIdentifier: videoStoryCellId)
    let supportCellId = NSStringFromClass(ANISupportViewCell.self)
    tableView.register(ANISupportViewCell.self, forCellReuseIdentifier: supportCellId)
    let qnaId = NSStringFromClass(ANIQnaViewCell.self)
    tableView.register(ANIQnaViewCell.self, forCellReuseIdentifier: qnaId)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.alpha = 0.0
    tableView.rowHeight = UITableView.automaticDimension
    addSubview(tableView)
    tableView.edgesToSuperview()
    self.tableView = tableView
  }
  
  private func setupNotifications() {
    ANINotificationManager.receive(searchTabTapped: self, selector: #selector(scrollToTop))
    ANINotificationManager.receive(deleteStory: self, selector: #selector(deleteStory))
    ANINotificationManager.receive(deleteQna: self, selector: #selector(deleteQna))
  }
  
  @objc private func scrollToTop() {
    guard let userTableView = tableView,
          !searchUsers.isEmpty else { return }
    
    userTableView.scrollToRow(at: [0, 0], at: .top, animated: true)
  }
  
  @objc private func deleteStory(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let tableView = self.tableView else { return }
    
    for (index, searchStory) in searchStories.enumerated() {
      if searchStory.id == id {
        searchStories.remove(at: index)
        
        if !searchStories.isEmpty {
          tableView.beginUpdates()
          let indexPath: IndexPath = [0, index]
          tableView.deleteRows(at: [indexPath], with: .automatic)
          tableView.endUpdates()
        } else {
          tableView.reloadData()
        }
      }
    }
  }
  
  @objc private func deleteQna(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let tableView = self.tableView else { return }
    
    for (index, searchQna) in searchQnas.enumerated() {
      if searchQna.id == id {
        searchQnas.remove(at: index)

        if !searchQnas.isEmpty {
          tableView.beginUpdates()
          let indexPath: IndexPath = [0, index]
          tableView.deleteRows(at: [indexPath], with: .automatic)
          tableView.endUpdates()
        } else {
          tableView.reloadData()
        }
      }
    }
  }
  
  private func isBlockUser(user: FirebaseUser) -> Bool {
    guard let userId = user.uid else { return false }
    
    if let blockUserIds = ANISessionManager.shared.blockUserIds, blockUserIds.contains(userId) {
      return true
    }
    if let blockingUserIds = ANISessionManager.shared.blockingUserIds, blockingUserIds.contains(userId) {
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
  
  private func activityIndicatorStartAnimating() {
    activityIndicatorStopAnimating()
    
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    activityIndicatorView.startAnimating()
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  private func activityIndicatorStopAnimating() {
    if self.activityIndicatorView != nil {
      self.activityIndicatorView?.stopAnimating()
      self.activityIndicatorView?.removeFromSuperview()
      self.activityIndicatorView = nil
    }
  }
}

//MARK: UITableViewDataSource
extension ANISearchView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch selectedCategory {
    case .user:
      return searchUsers.count
    case .qna:
      return searchQnas.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    switch selectedCategory {
    case .user:
      let userId = NSStringFromClass(ANIUserSearchViewCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: userId, for: indexPath) as! ANIUserSearchViewCell
      
      cell.user = searchUsers[indexPath.row]
      cell.delegate = self
      
      return cell
    case .qna:
      let qnaId = NSStringFromClass(ANIQnaViewCell.self)
      let cell = tableView.dequeueReusableCell(withIdentifier: qnaId, for: indexPath) as! ANIQnaViewCell
      cell.delegate = self

      if qnaUsers.contains(where: { $0.uid == searchQnas[indexPath.row].userId }) {
        for user in qnaUsers {
          if searchQnas[indexPath.row].userId == user.uid {
            cell.user = user
            break
          }
        }
      } else {
        cell.user = nil
      }
      cell.indexPath = indexPath.row
      cell.qna = searchQnas[indexPath.row]
      
      return cell
    }
  }
}

//MARK: UITableViewDelegate
extension ANISearchView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if selectedCategory == .qna, let cell = cell as? ANIQnaViewCell {
      cell.unobserveLove()
      cell.unobserveComment()
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    switch selectedCategory {
    case .user:
      let element = self.searchUsers.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreSearch()
      }
      
      self.userCellHeight[indexPath] = cell.frame.size.height
    case .qna:
      let element = self.searchQnas.count - COUNT_LAST_CELL
      if !isLoading, indexPath.row >= element {
        loadMoreSearch()
      }
      
      self.qnaCellHeight[indexPath] = cell.frame.size.height
    }
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    switch selectedCategory {
    case .user:
      if let height = self.userCellHeight[indexPath] {
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
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    ANINotificationManager.postViewScrolled()
    
    //navigation bar animation
    let scrollY = scrollView.contentOffset.y
    self.delegate?.searchViewDidScroll(scrollY: scrollY)
  }
}

//MARK: ANIUserSearchViewCellDelegate
extension ANISearchView: ANIUserSearchViewCellDelegate {
  func reject() {
    self.delegate?.reject()
  }
}

//MARK: ANIQnaViewCellDelegate
extension ANISearchView: ANIQnaViewCellDelegate {
  func cellTapped(qna: FirebaseQna, user: FirebaseUser) {
    self.delegate?.qnaViewCellDidSelect(selectedQna: qna, user: user)
  }
  
  func loadedQnaIsLoved(indexPath: Int, isLoved: Bool) {
    var searchQna = self.searchQnas[indexPath]
    searchQna.isLoved = isLoved
    self.searchQnas[indexPath] = searchQna
  }
  
  func loadedQnaUser(user: FirebaseUser) {
    self.qnaUsers.append(user)
  }
  
  func popupOptionView(isMe: Bool, contentType: ContentType, id: String) {
    self.delegate?.popupOptionView(isMe: isMe, contentType: contentType, id: id)
  }
}

//MARK: data
extension ANISearchView {
  private func search(category: SearchCategory, searchText: String) {
//    guard let activityIndicatorView = self.activityIndicatorView else { return }
    
    self.category = category
    
    switch category {
    case .user:
      index = ANISessionManager.shared.client.index(withName: KEY_USERS_INDEX)
      
      query.query = searchText
      query.hitsPerPage = 30
      page = 0
      query.page = page
      
      if !searchUsers.isEmpty {
        searchUsers.removeAll()
      }
    case .qna:
      index = ANISessionManager.shared.client.index(withName: KEY_QNAS_INDEX)
      
      query.query = searchText
      query.hitsPerPage = 30
      page = 0
      query.page = page
      
      if !searchQnas.isEmpty {
        searchQnas.removeAll()
      }
    }
    
    activityIndicatorStartAnimating()
    
    DispatchQueue.global().async {
      guard let index = self.index,
            let tableView = self.tableView else { return }
      
      self.isLoading = true
      
      index.search(self.query, completionHandler: { (content, error) -> Void in
        if let content = content, let hits = content[KEY_HITS] as? [AnyObject], !hits.isEmpty {
          for (hitIndex, hit) in hits.enumerated() {
            guard let hitDic = hit as? [String: AnyObject],
                  let nbPages = content["nbPages"] as? UInt else {
                    self.isLoading = false
                    return }
            
            self.nbPages = nbPages
            
            do {
              switch category {
              case .user:
                let user = try FirebaseDecoder().decode(FirebaseUser.self, from: hitDic)
                
                if let currenUserUid = ANISessionManager.shared.currentUserUid {
                  if user.uid != currenUserUid {
                    if !self.isBlockUser(user: user) {
                      self.searchUsers.append(user)
                    }
                  }
                } else {
                  if !self.isBlockUser(user: user) {
                    self.searchUsers.append(user)
                  }
                }
              case .qna:
                let qna = try FirebaseDecoder().decode(FirebaseQna.self, from: hitDic)
                
                if !self.isBlockQna(qna: qna) {
                  self.searchQnas.append(qna)
                }
              }
              
              DispatchQueue.main.async {
                if hitIndex + 1 == hits.count {
                  tableView.reloadData()
                  
                  self.isLoading = false
                  
                  switch category {
                  case .user:
                    if self.searchUsers.isEmpty, nbPages != 1 {
                      self.loadMoreSearch()
                    } else {
                      self.activityIndicatorStopAnimating()

                      UIView.animate(withDuration: 0.2, animations: {
                        tableView.alpha = 1.0
                      })
                    }
                  case .qna:
                    if self.searchQnas.isEmpty, nbPages != 1 {
                      self.loadMoreSearch()
                    } else {
                      self.activityIndicatorStopAnimating()

                      UIView.animate(withDuration: 0.2, animations: {
                        tableView.alpha = 1.0
                      })
                    }
                  }
                }
              }
            } catch let error {
              tableView.reloadData()

              DLog(error)
              
              self.activityIndicatorStopAnimating()

              self.isLoading = false
            }
          }
        } else if let error = error {
          tableView.reloadData()
          
          DLog("error: \(error)")
          
          self.activityIndicatorStopAnimating()

          self.isLoading = false
        } else {
          tableView.reloadData()
          
          self.activityIndicatorStopAnimating()

          self.isLoading = false
        }
      })
    }
  }
  
  private func loadMoreSearch() {
    guard page + 1 < nbPages,
          let index = self.index,
          !isLoading,
          let tableView = self.tableView else { return }
    
    page = page + 1
    query.page = page
    isLoading = true
    
    DispatchQueue.global().async {
      index.search(self.query, completionHandler: { (content, error) -> Void in
        if let content = content, let hits = content[KEY_HITS] as? [AnyObject], !hits.isEmpty {
          for (hitIndex, hit) in hits.enumerated() {
            guard let hitDic = hit as? [String: AnyObject] else {
              self.isLoading = false
              return }
            
            do {
              switch self.selectedCategory {
              case .user:
                let user = try FirebaseDecoder().decode(FirebaseUser.self, from: hitDic)
                
                if !self.searchUsers.contains(where: { $0.uid == user.uid }) {
                  if let currenUserUid = ANISessionManager.shared.currentUserUid {
                    if user.uid != currenUserUid {
                      if !self.isBlockUser(user: user) {
                        self.searchUsers.append(user)
                      }
                    }
                  } else {
                    if !self.isBlockUser(user: user) {
                      self.searchUsers.append(user)
                    }
                  }
                }
              case .qna:
                let qna = try FirebaseDecoder().decode(FirebaseQna.self, from: hitDic)
                
                if !self.searchQnas.contains(where: { $0.id == qna.id }) {
                  if !self.isBlockQna(qna: qna) {
                    self.searchQnas.append(qna)
                  }
                }
              }
              
              DispatchQueue.main.async {
                if hitIndex + 1 == hits.count {
                  tableView.reloadData()
                  
                  self.isLoading = false
                  
                  switch self.category {
                  case .user:
                    if self.searchUsers.isEmpty {
                      self.loadMoreSearch()
                    } else {
                      if tableView.alpha == 0 {
                        self.activityIndicatorStopAnimating()

                        UIView.animate(withDuration: 0.2, animations: {
                          tableView.alpha = 1.0
                        })
                      }
                    }
                  case .qna:
                    if self.searchQnas.isEmpty {
                      self.loadMoreSearch()
                    } else {
                      if tableView.alpha == 0 {
                        self.activityIndicatorStopAnimating()

                        UIView.animate(withDuration: 0.2, animations: {
                          tableView.alpha = 1.0
                        })
                      }
                    }
                  }
                }
              }
            } catch let error {
              tableView.reloadData()
              
              DLog(error)
              
              self.isLoading = false
            }
          }
        } else if let error = error {
          tableView.reloadData()
          
          DLog("error: \(error)")
          
          self.isLoading = false
        } else {
          tableView.reloadData()
          
          self.isLoading = false
        }
      })
    }
  }
}
