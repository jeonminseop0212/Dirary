//
//  ANIRecruitDetailViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/04/26.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import FirebaseFirestore
import TinyConstraints
import CodableFirebase
import FirebaseStorage

class ANIRecruitDetailViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var backButton: UIButton?
  private weak var optionButton: UIButton?
  private weak var clipButton: ANIImageButtonView?
  
  private weak var recruitDetailView: ANIRecruitDetailView?
  
  static let APPLY_BUTTON_HEIGHT: CGFloat = 45.0
  private let APPLY_BUTTON_WIDTH: CGFloat = 160.0
  private weak var applyButton: ANIAreaButtonView?
  private weak var applyButtonLabel: UILabel?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  private var rejectTapView: UIView?
  
  private var statusBarStyle: UIStatusBarStyle = .default
  
  var recruit: FirebaseRecruit?
  
  var user: FirebaseUser?
  
  private var isBack: Bool = false
  
  private var isClipped: Bool = false
  
  private var clipButtonColor = UIColor()
  
  private weak var activityIndicatorView: ANIActivityIndicator?

  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
    checkClipped()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    setupNotifications()
    self.setNeedsStatusBarAppearanceUpdate()
    UIApplication.shared.statusBarStyle = statusBarStyle
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
  }
  
  private func setup() {
    //basic
    self.navigationController?.navigationBar.tintColor = .white
    UIApplication.shared.statusBarStyle = .lightContent

    //recruitDetailView
    let recruitDetailView = ANIRecruitDetailView()
    recruitDetailView.headerMinHeight = UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT
    recruitDetailView.delegate = self
    recruitDetailView.recruit = recruit
    recruitDetailView.user = user
    self.view.addSubview(recruitDetailView)
    recruitDetailView.edgesToSuperview()
    self.recruitDetailView = recruitDetailView
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview()
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //backButton
    let backButton = UIButton()
    let backButtonImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate)
    backButton.setImage(backButtonImage, for: .normal)
    backButton.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBar.addSubview(backButton)
    backButton.width(44.0)
    backButton.height(44.0)
    backButton.leftToSuperview()
    backButton.bottomToSuperview()
    self.backButton = backButton
    
    //optionButton
    let optionButton = UIButton()
    let optionButtonImage = UIImage(named: "optionButton")?.withRenderingMode(.alwaysTemplate)
    optionButton.setImage(optionButtonImage, for: .normal)
    optionButton.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    optionButton.addTarget(self, action: #selector(option), for: .touchUpInside)
    myNavigationBar.addSubview(optionButton)
    optionButton.width(40.0)
    optionButton.height(44.0)
    optionButton.rightToSuperview(offset: -5.0)
    optionButton.bottomToSuperview()
    self.optionButton = optionButton
    
    //clipButton
    let clipButton = ANIImageButtonView()
    let clipButtonImage = UIImage(named: "clipButton")?.withRenderingMode(.alwaysTemplate)
    clipButton.image = clipButtonImage
    clipButton.delegate = self
    clipButton.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    myNavigationBar.addSubview(clipButton)
    clipButton.width(30.0)
    clipButton.height(44.0)
    clipButton.rightToLeft(of: optionButton)
    clipButton.bottomToSuperview()
    self.clipButton = clipButton
    
    //applyButton
    let applyButton = ANIAreaButtonView()
    applyButton.base?.backgroundColor = ANIColor.emerald
    applyButton.baseCornerRadius = ANIRecruitDetailViewController.APPLY_BUTTON_HEIGHT / 2
    applyButton.dropShadow(opacity: 0.2)
    applyButton.delegate = self
    if let currentUserId = ANISessionManager.shared.currentUserUid,
      let recruit = self.recruit,
      currentUserId == recruit.userId || recruit.recruitState != 0 {
      applyButton.isHidden = true
    }
    self.view.addSubview(applyButton)
    applyButton.bottomToSuperview(offset: -15.0)
    applyButton.centerXToSuperview()
    applyButton.width(APPLY_BUTTON_WIDTH)
    applyButton.height(ANIRecruitDetailViewController.APPLY_BUTTON_HEIGHT)
    self.applyButton = applyButton
    
    //applyButtonLabel
    let applyButtonLabel = UILabel()
    applyButtonLabel.text = "お話ししたい"
    applyButtonLabel.textAlignment = .center
    applyButtonLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    applyButtonLabel.textColor = .white
    applyButton.addContent(applyButtonLabel)
    applyButtonLabel.edgesToSuperview()
    self.applyButtonLabel = applyButtonLabel
    
    //rejectView
    let rejectView = ANIRejectView()
    rejectView.setRejectText("ログインが必要です。")
    self.view.addSubview(rejectView)
    rejectViewBottomConstraint = rejectView.bottomToTop(of: self.view)
    rejectViewBottomConstraintOriginalConstant = rejectViewBottomConstraint?.constant
    rejectView.leftToSuperview()
    rejectView.rightToSuperview()
    self.rejectView = rejectView
    
    //rejectTapView
    let rejectTapView = UIView()
    rejectTapView.isUserInteractionEnabled = true
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(rejectViewTapped))
    rejectTapView.addGestureRecognizer(tapGesture)
    rejectTapView.isHidden = true
    rejectTapView.backgroundColor = .clear
    self.view.addSubview(rejectTapView)
    rejectTapView.size(to: rejectView)
    rejectTapView.topToSuperview()
    self.rejectTapView = rejectTapView
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = true
    self.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func pushOtherProfile(_ notification: NSNotification) {
    guard let userId = notification.object as? String else { return }
    
    if let currentUserUid = ANISessionManager.shared.currentUserUid, currentUserUid == userId {
      let profileViewController = ANIProfileViewController()
      profileViewController.hidesBottomBarWhenPushed = true
      self.navigationController?.pushViewController(profileViewController, animated: true)
      profileViewController.isBackButtonHide = false
    } else {
      let otherProfileViewController = ANIOtherProfileViewController()
      otherProfileViewController.hidesBottomBarWhenPushed = true
      otherProfileViewController.userId = userId
      self.navigationController?.pushViewController(otherProfileViewController, animated: true)
    }
  }
  
  private func presentImageBrowser(index: Int, imageUrls: [String]) {
    let imageBrowserViewController = ANIImageBrowserViewController()
    imageBrowserViewController.selectedIndex = index
    imageBrowserViewController.imageUrls = imageUrls
    imageBrowserViewController.modalPresentationStyle = .overCurrentContext
    imageBrowserViewController.delegate = self
    self.present(imageBrowserViewController, animated: false, completion: nil)
  }
  
  private func clip() {
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let clipButton = self.clipButton else { return }

    if !ANISessionManager.shared.isAnonymous, let currentUserId = ANISessionManager.shared.currentUserUid {
      let database = Firestore.firestore()

      if !isClipped {
        DispatchQueue.global().async {
          database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_CLIP_IDS).document(currentUserId).setData([currentUserId: true])
          let date = ANIFunction.shared.getToday()
          database.collection(KEY_USERS).document(currentUserId).collection(KEY_CLIP_RECRUIT_IDS).document(recuritId).setData([KEY_DATE: date])

          DispatchQueue.main.async {
            UIView.animate(withDuration: 0.15) {
              clipButton.tintColor = ANIColor.emerald
              self.isClipped = true
            }
          }
        }
      } else {
        DispatchQueue.global().async {
          database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_CLIP_IDS).document(currentUserId).delete()
          database.collection(KEY_USERS).document(currentUserId).collection(KEY_CLIP_RECRUIT_IDS).document(recuritId).delete()

          DispatchQueue.main.async {
            UIView.animate(withDuration: 0.15) {
              clipButton.tintColor = self.clipButtonColor
              self.isClipped = false
            }
          }
        }
      }
    } else {
      self.reject()
    }
  }
  
  private func apply() {
    if !ANISessionManager.shared.isAnonymous {
      let chatViewController = ANIChatViewController()
      let navigationContoller = UINavigationController(rootViewController: chatViewController)
      chatViewController.user = user
      chatViewController.isPush = false
      self.present(navigationContoller, animated: true, completion: nil)
    } else {
      self.reject()
    }
  }
  
  private func checkClipped() {
    guard let recruit = self.recruit,
          let recuritId = recruit.id,
          let currentUserId = ANISessionManager.shared.currentUserUid else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_RECRUITS).document(recuritId).collection(KEY_CLIP_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Error get document: \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          if document.documentID == currentUserId {
            self.isClipped = true
            UIView.animate(withDuration: 0.15) {
              self.clipButton?.tintColor = ANIColor.emerald
            }
          }
        }
      })
    }
  }
  
  func reject() {
    guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
          !isRejectAnimating,
          let rejectTapView = self.rejectTapView else { return }
    
    rejectViewBottomConstraint.constant = UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
    rejectTapView.isHidden = false
    
    UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: {
      self.isRejectAnimating = true
      self.view.layoutIfNeeded()
    }) { (complete) in
      guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
        let rejectViewBottomConstraintOriginalConstant = self.rejectViewBottomConstraintOriginalConstant else { return }
      
      rejectViewBottomConstraint.constant = rejectViewBottomConstraintOriginalConstant
      UIView.animate(withDuration: 0.3, delay: 1.0, options: .curveEaseInOut, animations: {
        self.view.layoutIfNeeded()
      }, completion: { (complete) in
        self.isRejectAnimating = false
        rejectTapView.isHidden = true
      })
    }
  }
  
  //MARK: Action
  @objc private func back() {
    isBack = true
    self.navigationController?.popViewController(animated: true)
  }
  
  @objc private func rejectViewTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
  }
  
  @objc private func option() {
    guard let recruit = self.recruit else { return }
      
    let popupOptionViewController = ANIPopupOptionViewController()
    popupOptionViewController.modalPresentationStyle = .overCurrentContext
    if let currentUserId = ANISessionManager.shared.currentUserUid, recruit.userId == currentUserId {
      popupOptionViewController.isMe = true
      popupOptionViewController.options = ["家族決定！😻", "募集中止", "編集する"]
    } else {
      popupOptionViewController.isMe = false
      popupOptionViewController.options = ["非表示"]
    }
    popupOptionViewController.delegate = self
    self.tabBarController?.present(popupOptionViewController, animated: false, completion: nil)
  }
}

//MARK: ANIRecruitDetailViewDelegate
extension ANIRecruitDetailViewController: ANIRecruitDetailViewDelegate {
  func recruitDetailViewDidScroll(offset: CGFloat) {
    guard let myNavigationBar = self.myNavigationBar,
          let backButton = self.backButton,
          let optionButton = self.optionButton,
          let clipButton = self.clipButton,
          !isBack else { return }
    
    if offset > 1 {
      let backGroundColorOffset: CGFloat = 1.0
      let tintColorOffset = 1.0 - offset
      backButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
      optionButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
      clipButtonColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
      if !isClipped {
        clipButton.tintColor = clipButtonColor
      }
      myNavigationBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: backGroundColorOffset)
      UIApplication.shared.statusBarStyle = .default
      statusBarStyle = .default
    } else {
      let tintColorOffset = 1.0 - offset
      let ANIColorDarkBrightness: CGFloat = 0.18
      if tintColorOffset > ANIColorDarkBrightness {
        backButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
        optionButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
        clipButtonColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
        if !isClipped {
          clipButton.tintColor = clipButtonColor
        }
      } else {
        backButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: ANIColorDarkBrightness, alpha: 1)
        optionButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: ANIColorDarkBrightness, alpha: 1)
        clipButtonColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
        if !isClipped {
          clipButton.tintColor = clipButtonColor
        }
      }
     
      myNavigationBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: offset)
      UIApplication.shared.statusBarStyle = .lightContent
      statusBarStyle = .lightContent
    }
  }
  
  func imageCellTapped(index: Int, introduceImageUrls: [String]) {
    presentImageBrowser(index: index, imageUrls: introduceImageUrls)
  }
}

//MARK: ANIButtonViewDelegate
extension ANIRecruitDetailViewController: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.clipButton {
      clip()
    }
    if view === self.applyButton {
      apply()
    }
  }
}

//MARK: ANIImageBrowserViewControllerDelegate
extension ANIRecruitDetailViewController: ANIImageBrowserViewControllerDelegate {
  func imageBrowserDidDissmiss() {
    UIApplication.shared.statusBarStyle = statusBarStyle
  }
}

//MARK: ANIPopupOptionViewControllerDelegate
extension ANIRecruitDetailViewController: ANIPopupOptionViewControllerDelegate {
  func deleteContribution() {
    let alertController = UIAlertController(title: nil, message: "投稿を削除しますか？", preferredStyle: .alert)
    
    let deleteAction = UIAlertAction(title: "削除", style: .default) { (action) in
      self.deleteData()
    }
    let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
    
    alertController.addAction(deleteAction)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func reportContribution() {
    let alertController = UIAlertController(title: nil, message: "投稿を通報しますか？", preferredStyle: .alert)
    
    let reportAction = UIAlertAction(title: "通報", style: .default) { (action) in
      if !ANISessionManager.shared.isAnonymous {
        self.reportData()
      } else {
        self.reject()
      }
    }
    let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
    
    alertController.addAction(reportAction)
    alertController.addAction(cancelAction)
    
    self.present(alertController, animated: true, completion: nil)
  }
  
  func optionTapped(index: Int) {
    guard let recruit = self.recruit else { return }

    if let currentUserId = ANISessionManager.shared.currentUserUid {
      if recruit.userId == currentUserId {
        if index == 0 {
          let alertController = UIAlertController(title: "家族決定おめでどうございます！", message: "決定でよろしければこの募集を中止してください", preferredStyle: .alert)
          
          let stopAction = UIAlertAction(title: "中止", style: .default) { (action) in
            if let recruit = self.recruit, let recruitId = recruit.id {
              let database = Firestore.firestore()
              
              database.collection(KEY_RECRUITS).document(recruitId).updateData([KEY_RECRUIT_STATE: 1])
            }
          }
          let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
          
          alertController.addAction(stopAction)
          alertController.addAction(cancelAction)
          
          self.present(alertController, animated: true, completion: nil)
        } else if index == 1 {
          let alertController = UIAlertController(title: nil, message: "この募集を中止しますか？", preferredStyle: .alert)
          
          let stopAction = UIAlertAction(title: "中止", style: .default) { (action) in
            if let recruit = self.recruit, let recruitId = recruit.id {
              let database = Firestore.firestore()
              
              database.collection(KEY_RECRUITS).document(recruitId).updateData([KEY_RECRUIT_STATE: 2])
            }
          }
          let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
          
          alertController.addAction(stopAction)
          alertController.addAction(cancelAction)
          
          self.present(alertController, animated: true, completion: nil)
        } else if index == 2 {
          let recruitContribtionViewController = ANIRecruitContributionViewController()
          if let recruit = self.recruit {
            recruitContribtionViewController.recruitContributionMode = .edit
            recruitContribtionViewController.recruit = recruit
            recruitContribtionViewController.delegate = self
          }
          let recruitContributionNV = UINavigationController(rootViewController: recruitContribtionViewController)
          self.navigationController?.present(recruitContributionNV, animated: true, completion: nil)
        }
      } else {
        if index == 0 {
          let alertController = UIAlertController(title: "この募集を非表示にしますか？", message: "非表示にした募集はアプリの中で見えなくなります。後から非表示を解除することは出来ません。", preferredStyle: .alert)
          
          let hideAction = UIAlertAction(title: "非表示", style: .default) { (action) in
            if let recruit = self.recruit, let recruitId = recruit.id {
              let database = Firestore.firestore()
              
              self.activityIndicatorView?.startAnimating()
              
              DispatchQueue.global().async {
                database.collection(KEY_RECRUITS).document(recruitId).getDocument(completion: { (snapshot, error) in
                  if let error = error {
                    DLog("Error get document: \(error)")
                    return
                  }
                  
                  guard let snapshot = snapshot, let data = snapshot.data() else { return }
                  
                  do {
                    let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: data)
                    
                    if let hideUserIds = recruit.hideUserIds {
                      var hideUserIdsTemp = hideUserIds
                      hideUserIdsTemp.append(currentUserId)
                      
                      database.collection(KEY_RECRUITS).document(recruitId).updateData([KEY_HIDE_USER_IDS: hideUserIdsTemp])
                    } else {
                      let hideUserIds = [currentUserId]
                      
                      database.collection(KEY_RECRUITS).document(recruitId).updateData([KEY_HIDE_USER_IDS: hideUserIds])
                    }
                    
                    DispatchQueue.main.async {
                      self.activityIndicatorView?.stopAnimating()
                      
                      self.navigationController?.popViewController(animated: true)
                      ANINotificationManager.postDeleteRecruit(id: recruitId)
                    }
                  } catch let error {
                    DLog(error)
                  }
                })
              }
            }
          }
          let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel)
          
          alertController.addAction(hideAction)
          alertController.addAction(cancelAction)
          
          self.present(alertController, animated: true, completion: nil)
        }
      }
    } else {
      if index == 0 {
        self.reject()
      }
    }
  }
}

//MAKR: data
extension ANIRecruitDetailViewController {
  private func deleteData() {
    guard let recruit = self.recruit,
          let recruitId = recruit.id else { return }
    
    let database = Firestore.firestore()
    
    DispatchQueue.global().async {
      database.collection(KEY_RECRUITS).document(recruitId).getDocument(completion: { (snapshot, error) in
        if let error = error {
          DLog("get document error \(error)")
          
          return
        }
        
        database.collection(KEY_RECRUITS).document(recruitId).delete()
        
        DispatchQueue.main.async {
          ANINotificationManager.postDeleteRecruit(id: recruitId)
          self.navigationController?.popViewController(animated: true)
        }
        
        guard let snapshot = snapshot, let data = snapshot.data() else { return }
        
        do {
          let recruit = try FirestoreDecoder().decode(FirebaseRecruit.self, from: data)
          if let headerImageUrl = recruit.headerImageUrl {
            let storage = Storage.storage()
            let storageRef = storage.reference(forURL: headerImageUrl)

            storageRef.delete { error in
              if let error = error {
                DLog(error)
              }
            }
          }
          
          if let introduceImageUrls = recruit.introduceImageUrls {
            for url in introduceImageUrls {
              let storage = Storage.storage()
              let storageRef = storage.reference(forURL: url)

              storageRef.delete { error in
                if let error = error {
                  DLog(error)
                }
              }
            }
          }
        } catch let error {
          DLog(error)
        }
      })
    }
    
    DispatchQueue.global().async {
      database.collection(KEY_RECRUITS).document(recruitId).collection(KEY_LOVE_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          database.collection(KEY_USERS).document(document.documentID).collection(KEY_LOVE_RECRUIT_IDS).document(recruitId).delete()
          database.collection(KEY_RECRUITS).document(recruitId).collection(KEY_LOVE_IDS).document(document.documentID).delete()
        }
      })
    }
    
    DispatchQueue.global().async {
      database.collection(KEY_RECRUITS).document(recruitId).collection(KEY_CLIP_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          database.collection(KEY_USERS).document(document.documentID).collection(KEY_CLIP_RECRUIT_IDS).document(recruitId).delete()
          database.collection(KEY_RECRUITS).document(recruitId).collection(KEY_CLIP_IDS).document(document.documentID).delete()
        }
      })
    }
    
    DispatchQueue.global().async {
      database.collection(KEY_RECRUITS).document(recruitId).collection(KEY_SUPPORT_IDS).getDocuments(completion: { (snapshot, error) in
        if let error = error {
          DLog("Get document error \(error)")
          
          return
        }
        
        guard let snapshot = snapshot else { return }
        
        for document in snapshot.documents {
          database.collection(KEY_RECRUITS).document(recruitId).collection(KEY_SUPPORT_IDS).document(document.documentID).delete()
        }
      })
    }
  }
  
  private func reportData() {
    guard let recruit = self.recruit,
          let recruitId = recruit.id else { return }

    let database = Firestore.firestore()

    let contentTypeString = "recurit"
    let date = ANIFunction.shared.getToday()
    let values = ["contentType": contentTypeString, "date": date]
    database.collection(KEY_REPORTS).document(recruitId).collection(KEY_REPORT).addDocument(data: values)
  }
}

//MARK: ANIRecruitContributionViewControllerDelegate
extension ANIRecruitDetailViewController: ANIRecruitContributionViewControllerDelegate {
  func doneEditingRecruit(recruit: FirebaseRecruit) {
    guard let recruitDetailView = self.recruitDetailView else { return }
    
    self.recruit = recruit
    recruitDetailView.recruit = recruit
  }
  
  func loadThumnailImage(thumbnailImage: UIImage?) {
  }
  
  func updateProgress(progress: CGFloat) {
  }
}
