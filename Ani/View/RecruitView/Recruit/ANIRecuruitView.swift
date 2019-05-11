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

protocol ANIRecruitViewDelegate {
  func recruitCellTap(selectedRecruit: FirebaseRecruit, user: FirebaseUser)
  func recruitViewDidScroll(scrollY: CGFloat)
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser)
  func reject()
  func showNewRecruitButton()
  func hideNewRecruitButton()
}

class ANIRecuruitView: UIView {
  
  private weak var reloadView: ANIReloadView?

  private weak var recruitTableView: UITableView? {
    didSet {
      guard let recruitTableView = self.recruitTableView else { return }
      let topInset = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT + TABLE_VIEW_TOP_MARGIN
      recruitTableView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: false)
    }
  }
  
  private weak var refreshControl: UIRefreshControl?
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  private let TABLE_VIEW_TOP_MARGIN: CGFloat = 10.0
  
  private var recruits = [FirebaseRecruit]()
  private var users = [FirebaseUser]()
  
  private var isLastRecruitPage: Bool = false
  private var lastRecruit: QueryDocumentSnapshot?
  private var isLoading: Bool = false
  private let COUNT_LAST_CELL: Int = 4
  
  var pickMode: FilterPickMode?
  var pickItem: String? {
    didSet {
      guard let pickMode = self.pickMode,
            let pickItem = self.pickItem else { return }
      
      switch pickMode {
      case .home:
        if pickItem == "選択しない" || pickItem == "" {
          homeFilter = nil
        } else {
          homeFilter = pickItem
        }
      case .kind:
        if pickItem == "選択しない" || pickItem == "" {
          kindFilter = nil
        } else {
          kindFilter = pickItem
        }
      case .age:
        if pickItem == "選択しない" || pickItem == "" {
          ageFilter = nil
        } else {
          ageFilter = pickItem
        }
      case .sex:
        if pickItem == "選択しない" || pickItem == "" {
          sexFilter = nil
        } else {
          sexFilter = pickItem
        }
      }
      
      setupQuery()
    }
  }
  
  private var homeFilter: String?
  private var kindFilter: String?
  private var ageFilter: String?
  private var sexFilter: String?
  
  private var query: Query? {
    didSet {
      observeRecruit()
      
      hideNewRecruitButton()
      isNewRecruit = false
      
      loadRecruit(sender: nil)
    }
  }
  
  private var isLoadedFirstData: Bool = false
  private var isNewRecruit: Bool = false
  private var isShowNewRecruitButton: Bool = false
  
  private var scrollBeginingPoint: CGPoint?
  
  private var recruitListener: ListenerRegistration?
  
  var delegate: ANIRecruitViewDelegate?
  
  private var cellHeight = [IndexPath: CGFloat]()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    setupNotifications()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //basic
    self.backgroundColor = ANIColor.bg
    
    //reloadView
    let reloadView = ANIReloadView()
    reloadView.alpha = 0.0
    reloadView.messege = "募集がありません。"
    reloadView.delegate = self
    addSubview(reloadView)
    reloadView.dropShadow()
    reloadView.centerInSuperview()
    reloadView.leftToSuperview(offset: 50.0)
    reloadView.rightToSuperview(offset: -50.0)
    self.reloadView = reloadView
    
    //recruitTableView
    let tableView = UITableView()
    tableView.separatorStyle = .none
    let topInset = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT + TABLE_VIEW_TOP_MARGIN
    tableView.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    tableView.scrollIndicatorInsets  = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
    tableView.backgroundColor = ANIColor.bg
    let id = NSStringFromClass(ANIRecruitViewCell.self)
    tableView.register(ANIRecruitViewCell.self, forCellReuseIdentifier: id)
    tableView.dataSource = self
    tableView.delegate = self
    let refreshControl = UIRefreshControl()
    refreshControl.backgroundColor = .clear
    refreshControl.tintColor = ANIColor.moreDarkGray
    refreshControl.addTarget(self, action: #selector(reloadData(sender:)), for: .valueChanged)
    tableView.alpha = 0.0
    tableView.rowHeight = UITableView.automaticDimension
    tableView.addSubview(refreshControl)
    self.refreshControl = refreshControl
    addSubview(tableView)
    tableView.edgesToSuperview()
    self.recruitTableView = tableView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = false
    self.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
    
    let database = Firestore.firestore()
    
    query = database.collection(KEY_RECRUITS)
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    ANINotificationManager.receive(logout: self, selector: #selector(reloadRecruit))
    ANINotificationManager.receive(login: self, selector: #selector(reloadRecruit))
    ANINotificationManager.receive(recruitTabTapped: self, selector: #selector(scrollToTop))
    ANINotificationManager.receive(deleteRecruit: self, selector: #selector(deleteRecruit))
  }
  
  @objc private func reloadData(sender:  UIRefreshControl?) {
    hideNewRecruitButton()
    isNewRecruit = false
    
    loadRecruit(sender: sender)
  }
  
  @objc private func reloadRecruit() {
    guard let recruitTableView = self.recruitTableView else { return }

    hideNewRecruitButton()
    isNewRecruit = false
    
    recruitTableView.alpha = 0.0
    
    loadRecruit(sender: nil)
  }
  
  @objc private func scrollToTop() {
    guard let recruitTableView = recruitTableView,
          !recruits.isEmpty else { return }
    
    recruitTableView.scrollToRow(at: [0, 0], at: .top, animated: true)
  }
  
  private func setupQuery() {
    guard let recruitTableView = self.recruitTableView else { return }
    
    recruitTableView.alpha = 0.0
    
    let database = Firestore.firestore()

    var queryTemp: Query = database.collection(KEY_RECRUITS)
    
    if let homeFilter = homeFilter {
      queryTemp = queryTemp.whereField(KEY_RECRUIT_HOME, isEqualTo: homeFilter)
    }
    
    if let kindFilter = kindFilter {
      queryTemp = queryTemp.whereField(KEY_RECRUIT_KIND, isEqualTo: kindFilter)
    }
    
    if let ageFilter = ageFilter {
      queryTemp = queryTemp.whereField(KEY_RECRUIT_AGE, isEqualTo: ageFilter)
    }
    
    if let sexFilter = sexFilter {
      queryTemp = queryTemp.whereField(KEY_RECRUIT_SEX, isEqualTo: sexFilter)
    }
    
    query = queryTemp
  }
  
  func endRefresh() {
    guard let refreshControl = self.refreshControl,
          let recruitTableView = self.recruitTableView else { return }
    
    refreshControl.endRefreshing()
    
    let topInset = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT + TABLE_VIEW_TOP_MARGIN
    if recruitTableView.contentOffset.y + topInset < 0 {
      recruitTableView.scrollToRow(at: [0, 0], at: .top, animated: false)
    }
  }
  
  @objc private func deleteRecruit(_ notification: NSNotification) {
    guard let id = notification.object as? String,
          let recruitTableView = self.recruitTableView else { return }

    for (index, recruit) in recruits.enumerated() {
      if recruit.id == id {
        recruits.remove(at: index)
        
        if !recruits.isEmpty {
          recruitTableView.beginUpdates()
          let indexPath: IndexPath = [0, index]
          recruitTableView.deleteRows(at: [indexPath], with: .automatic)
          recruitTableView.endUpdates()
        } else {
          recruitTableView.reloadData()
          recruitTableView.alpha = 0.0
          showReloadView(sender: nil)
        }
      }
    }
  }
  
  private func showReloadView(sender: UIRefreshControl?) {
    guard let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView,
          let recruitTableView = self.recruitTableView else { return }

    activityIndicatorView.stopAnimating()
    
    recruitTableView.reloadData()
    
    if let sender = sender {
      sender.endRefreshing()
    }
    
    recruitTableView.alpha = 0.0
    
    UIView.animate(withDuration: 0.2) {
      reloadView.alpha = 1.0
    }
    
    self.isLoading = false
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
  
  private func observeRecruit() {
    guard let query = self.query else { return }
    
    if let recruitListener = self.recruitListener {
      recruitListener.remove()
      self.isLoadedFirstData = false
    }
    
    recruitListener = query.order(by: KEY_DATE, descending: true).limit(to: 1).addSnapshotListener { (snapshot, error) in
      if let error = error {
        DLog("stories observe error \(error)")
        return
      }
      
      guard let snapshot = snapshot else { return }
      
      snapshot.documentChanges.forEach({ (diff) in
        if diff.type == .added && self.isLoadedFirstData {
          self.isNewRecruit = true
          self.showNewRecruitButton()
        }
      })
    }
  }
  
  private func showNewRecruitButton() {
    guard isNewRecruit,
          !isShowNewRecruitButton else { return }
    
    isShowNewRecruitButton = true
    
    self.delegate?.showNewRecruitButton()
  }
  
  private func hideNewRecruitButton() {
    guard isNewRecruit,
          isShowNewRecruitButton else { return }
    
    isShowNewRecruitButton = false
    
    self.delegate?.hideNewRecruitButton()
  }
  
  func newRecruitButtonTapped() {
    guard let recruitTableView = self.recruitTableView,
          let refreshControl = self.refreshControl else { return }
    
    hideNewRecruitButton()
    isNewRecruit = false
    
    refreshControl.beginRefreshing()
    let offsetY = 60 + UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT
    recruitTableView.setContentOffset(CGPoint(x: 0.0, y: -offsetY), animated: true)
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.loadRecruit(sender: refreshControl)
    }
  }
}

//MARK: UITableViewDataSource
extension ANIRecuruitView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return recruits.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let id = NSStringFromClass(ANIRecruitViewCell.self)
    let cell = tableView.dequeueReusableCell(withIdentifier: id, for: indexPath) as! ANIRecruitViewCell
    cell.delegate = self

    if !recruits.isEmpty && recruits.count > indexPath.row {
      if users.contains(where: { $0.uid == recruits[indexPath.row].userId }) {
        for user in users {
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
    }
    
    return cell
  }
}

//MARK: UITableViewDelegate
extension ANIRecuruitView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let cell = cell as? ANIRecruitViewCell {
      cell.unobserveLove()
      cell.unobserveSupport()
    }
  }
  
  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    let element = self.recruits.count - COUNT_LAST_CELL
    if !isLoading, indexPath.row >= element {
      loadMoreRecruit()
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
    ANINotificationManager.postViewScrolled()
    
    //navigation bar animation
    let scrollY = scrollView.contentOffset.y
    self.delegate?.recruitViewDidScroll(scrollY: scrollY)
    
    //new story button show or hide
    if let scrollBeginingPoint = self.scrollBeginingPoint {
      if scrollBeginingPoint.y < scrollView.contentOffset.y {
        hideNewRecruitButton()
      } else {
        showNewRecruitButton()
      }
    }
  }
}

//MARK: ANIRecruitViewCellDelegate
extension ANIRecuruitView: ANIRecruitViewCellDelegate {
  func cellTapped(recruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.recruitCellTap(selectedRecruit: recruit, user: user)
  }
  
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser) {
    self.delegate?.supportButtonTapped(supportRecruit: supportRecruit, user: user)
  }
  
  func reject() {
    self.delegate?.reject()
  }
  
  func loadedRecruitIsLoved(indexPath: Int, isLoved: Bool) {
    if recruits.isEmpty && recruits.count > indexPath {
      var recruit = self.recruits[indexPath]
      recruit.isLoved = isLoved
      self.recruits[indexPath] = recruit
    }
  }
  
  func loadedRecruitIsCliped(indexPath: Int, isCliped: Bool) {
    if recruits.isEmpty && recruits.count > indexPath {
      var recruit = self.recruits[indexPath]
      recruit.isCliped = isCliped
      self.recruits[indexPath] = recruit
    }
  }
  
  func loadedRecruitIsSupported(indexPath: Int, isSupported: Bool) {
    if recruits.isEmpty && recruits.count > indexPath {
      var recruit = self.recruits[indexPath]
      recruit.isSupported = isSupported
      self.recruits[indexPath] = recruit
    }
  }
  
  func loadedRecruitUser(user: FirebaseUser) {
    self.users.append(user)
  }
}

//MARK: ANIReloadViewDelegate
extension ANIRecuruitView: ANIReloadViewDelegate {
  func reloadButtonTapped() {
    loadRecruit(sender: nil)
  }
}

//MARK: data
extension ANIRecuruitView {
  @objc private func loadRecruit(sender: UIRefreshControl?) {
    guard let query = self.query,
          let activityIndicatorView = self.activityIndicatorView,
          let reloadView = self.reloadView,
          let recruitTableView = self.recruitTableView else { return }
    
    reloadView.alpha = 0.0
    
    if !self.recruits.isEmpty {
      self.recruits.removeAll()
    }
    if !self.users.isEmpty {
      self.users.removeAll()
    }
    
    if sender == nil {
      activityIndicatorView.startAnimating()
    }
    
    DispatchQueue.global().async {
      self.isLoading = true
      self.isLastRecruitPage = false

      query.order(by: KEY_DATE, descending: true).limit(to: 20).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          self.isLoading = false

          return
        }
        
        guard let snapshot = snapshot,
              let lastRecruit = snapshot.documents.last else {
                if !self.recruits.isEmpty {
                  self.recruits.removeAll()
                }
                
                self.isLoading = false
                
                self.showReloadView(sender: sender)
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
                if let sender = sender {
                  sender.endRefreshing()
                }
                
                recruitTableView.reloadData()
                
                self.isLoading = false
                
                if self.recruits.isEmpty {
                  self.loadMoreRecruit()
                } else {
                  if recruitTableView.alpha == 0.0 {
                    activityIndicatorView.stopAnimating()

                    UIView.animate(withDuration: 0.2, animations: {
                      recruitTableView.alpha = 1.0
                    })
                  }
                  
                  self.isLoadedFirstData = true
                }
              }
            }
          } catch let error {
            DLog(error)
            
            activityIndicatorView.stopAnimating()
            
            UIView.animate(withDuration: 0.2, animations: {
              reloadView.alpha = 1.0
            })

            if let sender = sender {
              sender.endRefreshing()
            }
            
            self.isLoading = false
          }
        }
      })
    }
  }
  
  private func loadMoreRecruit() {
    guard let query = self.query,
          let recruitTableView = self.recruitTableView,
          let lastRecruit = self.lastRecruit,
          let activityIndicatorView = self.activityIndicatorView,
          !isLoading,
          !isLastRecruitPage else { return }
    
    DispatchQueue.global().async {
      self.isLoading = true
      
      query.order(by: KEY_DATE, descending: true).start(afterDocument: lastRecruit).limit(to: 20).getDocuments(completion: { (snapshot, error) in
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
                recruitTableView.reloadData()
                
                self.isLoading = false
                
                if self.recruits.isEmpty {
                  self.loadMoreRecruit()
                } else {
                  if recruitTableView.alpha == 0.0 {
                    activityIndicatorView.stopAnimating()

                    UIView.animate(withDuration: 0.2, animations: {
                      recruitTableView.alpha = 1.0
                    })
                  }
                  
                  self.isLoadedFirstData = true
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
