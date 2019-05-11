//
//  ViewController.swift
//  Ani
//
//  Created by 전민섭 on 2018/04/02.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

enum FilterPickMode: Int {
  case home;
  case kind;
  case age;
  case sex;
}

class ANIRecruitViewController: UIViewController {
  
  private weak var myNavigationBartopArea: UIView?
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBarTopConstroint: Constraint?
  private weak var navigaitonTitleLabel: UILabel?

  private weak var filtersView: ANIRecruitFiltersView?
  static let FILTERS_VIEW_HEIGHT: CGFloat = 47.0
  
  private weak var recruitView: ANIRecuruitView?
  
  private let pickUpItem = PickUpItem()
  private var pickMode: FilterPickMode?
  
  private let CONTRIBUTION_BUTTON_HEIGHT:CGFloat = 55.0
  private weak var contributionButon: ANIImageButtonView?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: ANIRejectView?
  private var isRejectAnimating: Bool = false
  private var rejectTapView: UIView?
  
  private let NEW_RECRUIT_BUTTON_OFFSET: CGFloat = 7.0
  private let NEW_RECRUIT_BUTTON_HIDE_OFFSET: CGFloat = -60.0
  private let NEW_RECRUIT_BUTTON_HEIGHT: CGFloat = 30.0
  private var newRecruitButtonTopConstraint: Constraint?
  private weak var newRecruitButton: ANIAreaButtonView?
  private weak var arrowImageView: UIImageView?
  private weak var newRecruitLabel: UILabel?
  
  private weak var uploadProgressView: ANIUploadProgressView?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    UIApplication.shared.statusBarStyle = .default
    UIApplication.shared.isStatusBarHidden = false
    setupNotifications()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    guard let recruitView = self.recruitView else { return }
    
    removeNotifications()
    
    recruitView.endRefresh()
  }
  
  private func setup() {
    //basic
    ANIOrientation.lockOrientation(.portrait)
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    
    //rcruitView
    let recruitView = ANIRecuruitView()
    recruitView.delegate = self
    self.view.addSubview(recruitView)
    recruitView.topToSuperview(usingSafeArea: true)
    recruitView.edgesToSuperview(excluding: .top)
    self.recruitView = recruitView
    
    //newRecuritButton
    let newRecruitButton = ANIAreaButtonView()
    newRecruitButton.base?.backgroundColor = ANIColor.emerald
    newRecruitButton.baseCornerRadius = NEW_RECRUIT_BUTTON_HEIGHT / 2
    newRecruitButton.dropShadow(opacity: 0.1)
    newRecruitButton.delegate = self
    self.view.addSubview(newRecruitButton)
    newRecruitButton.centerXToSuperview()
    newRecruitButton.width(160.0)
    newRecruitButton.height(NEW_RECRUIT_BUTTON_HEIGHT)
    self.newRecruitButton = newRecruitButton
    
    //newRecruitLabel
    let newRecruitLabel = UILabel()
    newRecruitLabel.text = "新しい募集"
    newRecruitLabel.textAlignment = .center
    newRecruitLabel.font = UIFont.boldSystemFont(ofSize: 12.0)
    newRecruitLabel.textColor = .white
    newRecruitButton.addContent(newRecruitLabel)
    newRecruitLabel.centerXToSuperview(offset: 8.0)
    newRecruitLabel.centerYToSuperview()
    self.newRecruitLabel = newRecruitLabel
    
    //arrowImageView
    let arrowImageView = UIImageView()
    arrowImageView.image = UIImage(named: "arrow")
    arrowImageView.contentMode = .scaleAspectFit
    newRecruitButton.addContent(arrowImageView)
    arrowImageView.centerYToSuperview()
    arrowImageView.rightToLeft(of: newRecruitLabel, offset: -5.0)
    arrowImageView.width(12.0)
    arrowImageView.height(11.0)
    self.arrowImageView = arrowImageView
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = .white
    self.view.addSubview(myNavigationBar)
    myNavigationBarTopConstroint = myNavigationBar.topToSuperview(usingSafeArea: true)
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //navigaitonTitleLabel
    let navigaitonTitleLabel = UILabel()
    navigaitonTitleLabel.text = "家族さがし"
    navigaitonTitleLabel.textColor = ANIColor.dark
    navigaitonTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBar.addSubview(navigaitonTitleLabel)
    navigaitonTitleLabel.centerInSuperview()
    self.navigaitonTitleLabel = navigaitonTitleLabel
    
    //myNavigationBartopArea
    let myNavigationBartopArea = UIView()
    myNavigationBartopArea.backgroundColor = .white
    self.view.addSubview(myNavigationBartopArea)
    myNavigationBartopArea.leftToSuperview()
    myNavigationBartopArea.rightToSuperview()
    myNavigationBartopArea.bottomToTop(of: myNavigationBar)
    myNavigationBartopArea.height(UIViewController.STATUS_BAR_HEIGHT)
    self.myNavigationBartopArea = myNavigationBartopArea
    
    //filtersView
    let filtersView = ANIRecruitFiltersView()
    filtersView.delegate = self
    self.view.addSubview(filtersView)
    filtersView.topToBottom(of: myNavigationBar)
    filtersView.leftToSuperview()
    filtersView.rightToSuperview()
    filtersView.height(ANIRecruitViewController.FILTERS_VIEW_HEIGHT)
    self.filtersView = filtersView
    
    newRecruitButtonTopConstraint = newRecruitButton.topToBottom(of: filtersView, offset: NEW_RECRUIT_BUTTON_HIDE_OFFSET)
    
    //contributionButon
    let contributionButon = ANIImageButtonView()
    contributionButon.image = UIImage(named: "contributionButton")
    contributionButon.superViewCornerRadius(radius: CONTRIBUTION_BUTTON_HEIGHT / 2)
    contributionButon.superViewDropShadow(opacity: 0.13)
    contributionButon.delegate = self
    self.view.addSubview(contributionButon)
    contributionButon.width(CONTRIBUTION_BUTTON_HEIGHT)
    contributionButon.height(CONTRIBUTION_BUTTON_HEIGHT)
    contributionButon.rightToSuperview(offset: -15.0)
    var tabBarHeight: CGFloat = 0.0
    if let tabBarController = self.tabBarController {
      tabBarHeight = tabBarController.tabBar.height
    }
    contributionButon.bottomToSuperview(offset: -(15.0 + tabBarHeight))
    self.contributionButon = contributionButon
    
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
    
    //uploadProgressView
    let uploadProgressView = ANIUploadProgressView()
    uploadProgressView.alpha = 0.95
    uploadProgressView.isHidden = true
    uploadProgressView.delegate = self
    self.view.addSubview(uploadProgressView)
    uploadProgressView.topToBottom(of: filtersView)
    uploadProgressView.leftToSuperview()
    uploadProgressView.rightToSuperview()
    uploadProgressView.height(50.0)
    self.uploadProgressView = uploadProgressView
  }
  
  //MARK: Notifications
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(profileImageViewTapped: self, selector: #selector(pushOtherProfile))
    ANINotificationManager.receive(pickerViewDidSelect: self, selector: #selector(updateFilter))
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
  
  @objc private func updateFilter(_ notification: NSNotification) {
    guard let pickMode = self.pickMode,
          let pickItem = notification.object as? String,
          let filtersView = self.filtersView,
          let recruitView = self.recruitView else { return }
    
    filtersView.pickMode = pickMode
    filtersView.pickItem = pickItem
    
    recruitView.pickMode = pickMode
    recruitView.pickItem = pickItem
  }
  
  func showNewRecruitButtonAnimation() {
    guard let newRecruitButtonTopConstraint = self.newRecruitButtonTopConstraint else { return }
    
    newRecruitButtonTopConstraint.constant = self.NEW_RECRUIT_BUTTON_OFFSET
    
    UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  func hideNewRecruitButtonAnimation() {
    guard let newRecruitButtonTopConstraint = self.newRecruitButtonTopConstraint else { return }
    
    newRecruitButtonTopConstraint.constant = NEW_RECRUIT_BUTTON_HIDE_OFFSET
    
    UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveEaseInOut, animations: {
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  //MARK: Action
  @objc private func rejectViewTapped() {
    let initialViewController = ANIInitialViewController()
    initialViewController.myTabBarController = self.tabBarController as? ANITabBarController
    let navigationController = UINavigationController(rootViewController: initialViewController)
    self.present(navigationController, animated: true, completion: nil)
  }
}

//MARK: ButtonViewDelegate
extension ANIRecruitViewController:ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.contributionButon {
      if ANISessionManager.shared.isAnonymous == false {
        let recruitContribtionViewController = ANIRecruitContributionViewController()
        recruitContribtionViewController.delegate = self
        let recruitContributionNV = UINavigationController(rootViewController: recruitContribtionViewController)
        self.navigationController?.present(recruitContributionNV, animated: true, completion: nil)
      } else {
        reject()
      }
    }
    
    if view === self.newRecruitButton {
      guard let recruitView = self.recruitView else { return }
      
      recruitView.newRecruitButtonTapped()
    }
  }
}

//ANIRecruitViewDelegate
extension ANIRecruitViewController: ANIRecruitViewDelegate {
  func supportButtonTapped(supportRecruit: FirebaseRecruit, user: FirebaseUser) {
    let supportViewController = ANISupportViewController()
    supportViewController.modalPresentationStyle = .overCurrentContext
    supportViewController.recruit = supportRecruit
    supportViewController.user = user
    self.tabBarController?.present(supportViewController, animated: false, completion: nil)
  }
  
  func recruitCellTap(selectedRecruit: FirebaseRecruit, user: FirebaseUser) {
    let recruitDetailViewController = ANIRecruitDetailViewController()
    recruitDetailViewController.hidesBottomBarWhenPushed = true
    recruitDetailViewController.recruit = selectedRecruit
    recruitDetailViewController.user = user
    self.navigationController?.pushViewController(recruitDetailViewController, animated: true)
  }
  
  func recruitViewDidScroll(scrollY: CGFloat) {
    guard let myNavigationBarTopConstroint = self.myNavigationBarTopConstroint,
          let filtersView = self.filtersView,
          let filterCollectionView = filtersView.filterCollectionView,
          let navigaitonTitleLabel = self.navigaitonTitleLabel else { return }
    
    let topHeight = UIViewController.NAVIGATION_BAR_HEIGHT + ANIRecruitViewController.FILTERS_VIEW_HEIGHT
    let newScrollY = topHeight + scrollY
    
    //navigation animate
    if topHeight < newScrollY {
      if scrollY < topHeight {
        myNavigationBarTopConstroint.constant = -scrollY
        self.view.layoutIfNeeded()
        
        let alpha = 1 - (scrollY / topHeight)
        navigaitonTitleLabel.alpha = alpha * alpha
        filterCollectionView.alpha = alpha * alpha
      } else {
        myNavigationBarTopConstroint.constant = -topHeight
        navigaitonTitleLabel.alpha = 0.0
        filterCollectionView.alpha = 0.0
        self.view.layoutIfNeeded()
      }
    } else {
      myNavigationBarTopConstroint.constant = 0.0
      self.view.layoutIfNeeded()
      
      navigaitonTitleLabel.alpha = 1.0
      filterCollectionView.alpha = 1.0
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
  
  func showNewRecruitButton() {
    showNewRecruitButtonAnimation()
  }
  
  func hideNewRecruitButton() {
    hideNewRecruitButtonAnimation()
  }
}

//MARK: ANIRecruitFiltersViewDelegate
extension ANIRecruitViewController: ANIRecruitFiltersViewDelegate {
  func didSelectedItem(index: Int) {
    let popupPickerViewController = ANIPopupPickerViewController()

    switch index {
    case FilterPickMode.home.rawValue:
      var home = pickUpItem.home
      home.insert("選択しない", at: 0)
      pickMode = .home
      
      popupPickerViewController.pickerItem = home
    case FilterPickMode.kind.rawValue:
      var kind = pickUpItem.kind
      kind.insert("選択しない", at: 0)
      pickMode = .kind
      
      popupPickerViewController.pickerItem = kind
    case FilterPickMode.age.rawValue:
      var age = pickUpItem.age
      age.insert("選択しない", at: 0)
      pickMode = .age
      
      popupPickerViewController.pickerItem = age
    case FilterPickMode.sex.rawValue:
      var sex = pickUpItem.sex
      sex.insert("選択しない", at: 0)
      pickMode = .sex
      
      popupPickerViewController.pickerItem = sex
    default:
      DLog("filter default")
    }
    
    popupPickerViewController.modalPresentationStyle = .overCurrentContext
    self.tabBarController?.present(popupPickerViewController, animated: false, completion: nil)
  }
}

//MARK: UIGestureRecognizerDelegate
extension ANIRecruitViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

//MARK: ANIRecruitContributionViewDelegate
extension ANIRecruitViewController: ANIRecruitContributionViewControllerDelegate {
  func doneEditingRecruit(recruit: FirebaseRecruit) {
  }
  
  func loadThumnailImage(thumbnailImage: UIImage?) {
    guard let uploadProgressView = self.uploadProgressView,
          let thumbnailImageView = uploadProgressView.thumbnailImageView else { return }
    
    if let thumbnailImage = thumbnailImage {
      thumbnailImageView.image = thumbnailImage
      thumbnailImageView.isHidden = false
    } else {
      thumbnailImageView.image = nil
      thumbnailImageView.isHidden = true
    }
  }
  
  func updateProgress(progress: CGFloat) {
    guard let uploadProgressView = self.uploadProgressView else { return }
    
    uploadProgressView.updateProgress(progress: progress)
    
    if progress != 1.0 {
      UIView.animate(withDuration: 0.2) {
        uploadProgressView.alpha = 0.95
      }
      uploadProgressView.isHidden = false
    }
  }
}

//MARK: ANIUploadProgressViewDelegate
extension ANIRecruitViewController: ANIUploadProgressViewDelegate {
  func completeProgress() {
    guard let uploadProgressView = self.uploadProgressView else { return }
    
    UIView.animate(withDuration: 0.2, animations: {
      uploadProgressView.alpha = 0.0
    }) { (complete) in
      uploadProgressView.isHidden = true
    }
  }
}
