//
//  RecruitContributionViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/11.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import Gallery
import TinyConstraints
import FirebaseStorage
import FirebaseFirestore
import CodableFirebase

enum BasicInfoPickMode {
  case kind
  case age
  case sex
  case home
  case vaccine
  case castration
}

enum RecruitContributionMode {
  case new
  case edit
}

protocol ANIRecruitContributionViewControllerDelegate {
  func doneEditingRecruit(recruit: FirebaseRecruit)
  func loadThumnailImage(thumbnailImage: UIImage?)
  func updateProgress(progress: CGFloat)
}

class ANIRecruitContributionViewController: UIViewController {
  
  private var gallery: GalleryController?
  var myImages = [UIImage]()
  
  private weak var myNavigationBar: UIView?
  private weak var dismissButton: UIButton?
  
  private var recruitContributionViewOriginalBottomConstraintConstant: CGFloat?
  private var recruitContributionViewBottomConstraint: Constraint?
  private weak var recruitContributionView: ANIRecruitContributionView?
  
  static let CONTRIBUTE_BUTTON_HEIGHT: CGFloat = 45.0
  private weak var contributeButton: ANIAreaButtonView?
  private weak var contributeButtonLabel: UILabel?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: UIView?
  private weak var rejectBaseView: UIView?
  private weak var rejectLabel: UILabel?
  private var isRejectAnimating: Bool = false
  
  var pickMode: BasicInfoPickMode? {
    didSet {
      guard let recruitContributionView = self.recruitContributionView else { return }
      
      recruitContributionView.pickMode = pickMode
    }
  }
  
  private let pickUpItem = PickUpItem()
  
  private var isHaderImagePick: Bool = false
  
  private let IMAGE_SIZE: CGSize = CGSize(width: 500.0, height: 500.0)
  
  private var isBack: Bool = false
  
  var recruitContributionMode: RecruitContributionMode = .new
  var recruit: FirebaseRecruit?
  
  var delegate: ANIRecruitContributionViewControllerDelegate?
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setup()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    UIApplication.shared.isStatusBarHidden = false
    setupNotifications()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    removeNotifications()
  }
  
  private func setup() {
    //basic
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    
    //recruitContributionView
    let recruitContributionView = ANIRecruitContributionView()
    if recruitContributionMode == .edit, let recruit = self.recruit {
      recruitContributionView.recruit = recruit
    }
    recruitContributionView.headerMinHeight = UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT
    recruitContributionView.delegate = self
    self.view.addSubview(recruitContributionView)
    recruitContributionViewBottomConstraint = recruitContributionView.bottomToSuperview()
    recruitContributionViewOriginalBottomConstraintConstant = recruitContributionViewBottomConstraint?.constant
    recruitContributionView.edgesToSuperview(excluding: .bottom)
    self.recruitContributionView = recruitContributionView
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0)
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview()
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //dismissButton
    let dismissButton = UIButton()
    let dismissButtonImage = UIImage(named: "dismissButton")?.withRenderingMode(.alwaysTemplate)
    dismissButton.setImage(dismissButtonImage, for: .normal)
    dismissButton.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    dismissButton.addTarget(self, action: #selector(recruitContributeDismiss), for: .touchUpInside)
    myNavigationBar.addSubview(dismissButton)
    dismissButton.width(44.0)
    dismissButton.height(44.0)
    dismissButton.leftToSuperview()
    dismissButton.bottomToSuperview()
    self.dismissButton = dismissButton
    
    //contributeButton
    let contributeButton = ANIAreaButtonView()
    contributeButton.base?.backgroundColor = ANIColor.emerald
    contributeButton.baseCornerRadius = ANIRecruitContributionViewController.CONTRIBUTE_BUTTON_HEIGHT / 2
    contributeButton.dropShadow(opacity: 0.2)
    contributeButton.delegate = self
    if recruitContributionMode == .edit {
      contributeButton.alpha = 0.0
    }
    self.view.addSubview(contributeButton)
    contributeButton.bottomToSuperview(offset: -15.0)
    contributeButton.leftToSuperview(offset: 100.0)
    contributeButton.rightToSuperview(offset: -100.0)
    contributeButton.height(ANIRecruitContributionViewController.CONTRIBUTE_BUTTON_HEIGHT)
    self.contributeButton = contributeButton
    
    //contributeButtonLabel
    let contributeButtonLabel = UILabel()
    if recruitContributionMode == .new {
      contributeButtonLabel.text = "投稿する"
    } else if recruitContributionMode == .edit {
      contributeButtonLabel.text = "保存する"
    }
    contributeButtonLabel.textAlignment = .center
    contributeButtonLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    contributeButtonLabel.textColor = .white
    contributeButton.addContent(contributeButtonLabel)
    contributeButtonLabel.edgesToSuperview()
    self.contributeButtonLabel = contributeButtonLabel
    
    //rejectView
    let rejectView = UIView()
    rejectView.backgroundColor = ANIColor.emerald
    self.view.addSubview(rejectView)
    rejectViewBottomConstraint = rejectView.bottomToTop(of: self.view)
    rejectViewBottomConstraintOriginalConstant = rejectViewBottomConstraint?.constant
    rejectView.leftToSuperview()
    rejectView.rightToSuperview()
    rejectView.height(UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT)
    self.rejectView = rejectView
    
    //rejectBaseView
    let rejectBaseView = UIView()
    rejectBaseView.backgroundColor = ANIColor.emerald
    rejectView.addSubview(rejectBaseView)
    rejectBaseView.edgesToSuperview(excluding: .top)
    rejectBaseView.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.rejectBaseView = rejectBaseView
    
    //rejectLabel
    let rejectLabel = UILabel()
    rejectLabel.text = "入力していない項目があります！"
    rejectLabel.textColor = .white
    rejectLabel.textAlignment = .center
    rejectLabel.font = UIFont.boldSystemFont(ofSize: 16.0)
    rejectLabel.textAlignment = .center
    rejectBaseView.addSubview(rejectLabel)
    rejectLabel.edgesToSuperview()
    self.rejectLabel = rejectLabel
    
    //activityIndicatorView
    let activityIndicatorView = ANIActivityIndicator()
    activityIndicatorView.isFull = true
    self.view.addSubview(activityIndicatorView)
    activityIndicatorView.edgesToSuperview()
    self.activityIndicatorView = activityIndicatorView
  }
  
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
    ANINotificationManager.receive(keyboardWillHide: self, selector: #selector(keyboardWillHide))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let recruitContributeViewBottomConstraint = self.recruitContributionViewBottomConstraint else { return }
    
    let h = keyboardFrame.height
    
    recruitContributeViewBottomConstraint.constant = -h  + 10.0 + ANIRecruitContributionViewController.CONTRIBUTE_BUTTON_HEIGHT

    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
      let recruitContributionViewOriginalBottomConstraintConstant = self.recruitContributionViewOriginalBottomConstraintConstant,
      let recruitContributionViewBottomConstraint = self.recruitContributionViewBottomConstraint else { return }
    
    recruitContributionViewBottomConstraint.constant = recruitContributionViewOriginalBottomConstraintConstant
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  private func recruitHeaderImagePick(animation: Bool) {
    gallery = GalleryController()
    
    if let galleryUnrap = gallery {
      galleryUnrap.delegate = self
      Gallery.Config.initialTab = .imageTab
      Gallery.Config.PageIndicator.backgroundColor = .white
      Gallery.Config.Camera.oneImageMode = true
      Gallery.Config.Font.Main.regular = UIFont.boldSystemFont(ofSize: 17)
      Gallery.Config.Grid.ArrowButton.tintColor = ANIColor.dark
      Gallery.Config.Grid.FrameView.borderColor = ANIColor.emerald
      if Gallery.Config.Camera.oneImageMode {
        Gallery.Config.Grid.previewRatio = UIViewController.HEADER_IMAGE_VIEW_RATIO
        Gallery.Config.tabsToShow = [.imageTab, .cameraTab]
      }
      let galleryNV = UINavigationController(rootViewController: galleryUnrap)
      present(galleryNV, animated: animation, completion: nil)
      
      isHaderImagePick = true
    }
  }
  
  private func recruitIntroduceImagesPick(animation: Bool) {
    gallery = GalleryController()
    
    if let galleryUnrap = gallery {
      galleryUnrap.delegate = self
      Gallery.Config.initialTab = .imageTab
      Gallery.Config.PageIndicator.backgroundColor = .white
      Gallery.Config.Camera.oneImageMode = false
      Gallery.Config.Camera.imageLimit = 10
      Gallery.Config.Font.Main.regular = UIFont.boldSystemFont(ofSize: 17)
      Gallery.Config.Grid.ArrowButton.tintColor = ANIColor.dark
      Gallery.Config.Grid.FrameView.borderColor = ANIColor.emerald
      Gallery.Config.Grid.previewRatio = 1.0
      Config.tabsToShow = [.imageTab, .cameraTab]
      let galleryNV = UINavigationController(rootViewController: galleryUnrap)
      present(galleryNV, animated: animation, completion: nil)
      
      isHaderImagePick = false
    }
  }
  
  private func getCropImages(images: [UIImage?], items: [Image]) -> [UIImage] {
    var croppedImages = [UIImage]()
    
    for (index, image) in images.enumerated() {
      let imageSize = image?.size
      let scrollViewWidth = self.view.frame.width
      let widthScale =  scrollViewWidth / (imageSize?.width)! * items[index].scale
      let heightScale = scrollViewWidth / (imageSize?.height)! * items[index].scale
      
      let scale = 1 / min(widthScale, heightScale)
      let visibleRect = CGRect(x: floor(items[index].offset.x * scale), y: floor(items[index].offset.y * scale), width: scrollViewWidth * scale, height: scrollViewWidth * scale * Config.Grid.previewRatio)
      let ref: CGImage = (image?.cgImage?.cropping(to: visibleRect))!
      let croppedImage:UIImage = UIImage(cgImage: ref)
      
      croppedImages.append(croppedImage)
    }
    return croppedImages
  }
  
  private func updateDatabase(recruit: FirebaseRecruit, id: String) {
    if recruit.headerImageUrl != nil && recruit.introduceImageUrls != nil {
      do {
        let database = Firestore.firestore()

        let data = try FirestoreEncoder().encode(recruit) as [String: AnyObject]
        
        if recruitContributionMode == .new {
          database.collection(KEY_RECRUITS).document(id).setData(data) { (error) in
            if let error = error {
              DLog("Error set document: \(error)")
              return
            }
            
            self.delegate?.updateProgress(progress: 1.0)
          }
        } else if recruitContributionMode == .edit {
          database.collection(KEY_RECRUITS).document(id).setData(data) { (error) in
            if let error = error {
              DLog(error)
            } else {
              self.activityIndicatorView?.stopAnimating()
              
              self.delegate?.doneEditingRecruit(recruit: recruit)
              self.dismiss(animated: true, completion: nil)
            }
          }
        }
      } catch let error {
        DLog(error)
      }
    }
  }
  
  private func deleteStorage() {
    guard let recruit = self.recruit else { return }
    
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
  }
  
  //MARK: Action
  @objc private func recruitContributeDismiss() {
    self.isBack = true
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
}

//MARK: GalleryControllerDelegate
extension ANIRecruitContributionViewController: GalleryControllerDelegate {
  func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
    
    Image.resolve(images: images) { (myImages) in
      let imageFilteriewController = ANIImageFilterViewController()
      imageFilteriewController.images = self.getCropImages(images: myImages, items: images)
      imageFilteriewController.delegate = self
      controller.navigationController?.pushViewController(imageFilteriewController, animated: true)
    }
    
    gallery = nil
  }
  
  func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
    controller.dismiss(animated: true, completion: nil)
    
    gallery = nil
  }
  
  func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    controller.dismiss(animated: true, completion: nil)
    gallery = nil
  }
  
  func galleryControllerDidCancel(_ controller: GalleryController) {
    controller.dismiss(animated: true, completion: nil)
    gallery = nil
  }
}

//MARK: ANIImageFilterViewControllerDelegate
extension ANIRecruitContributionViewController: ANIImageFilterViewControllerDelegate {
  func doneFilterImages(filteredImages: [UIImage?]) {
    guard let recruitContributionView = self.recruitContributionView,
          !filteredImages.isEmpty else { return }
    
    if isHaderImagePick {
      if let filteredImage = filteredImages[0] {
        recruitContributionView.headerImage = filteredImage.resize(size: IMAGE_SIZE)
      }
    } else {
      for filteredImage in filteredImages {
        recruitContributionView.introduceImages.append(filteredImage?.resize(size: IMAGE_SIZE))
      }
    }
  }
}

//MARK: ANIRecruitContributeViewDelegate
extension ANIRecruitContributionViewController: ANIRecruitContributionViewDelegate {
  func recruitContributeViewDidScroll(offset: CGFloat) {
    guard let myNavigationBar = self.myNavigationBar,
          let dismissButton = self.dismissButton,
          !isBack else { return }
    
    if offset > 1 {
      let backGroundColorOffset: CGFloat = 1.0
      let tintColorOffset = 1.0 - offset
      dismissButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
      myNavigationBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: backGroundColorOffset)
      UIApplication.shared.statusBarStyle = .default
    } else {
      let tintColorOffset = 1.0 - offset
      let ANIColorDarkBrightness: CGFloat = 0.18
      if tintColorOffset > ANIColorDarkBrightness {
        dismissButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: tintColorOffset, alpha: 1)
      } else {
        dismissButton.tintColor = UIColor(hue: 0, saturation: 0, brightness: ANIColorDarkBrightness, alpha: 1)
      }
      
      myNavigationBar.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: offset)
      UIApplication.shared.statusBarStyle = .lightContent
    }
  }
  
  func imagePickButtonTapped() {
    recruitHeaderImagePick(animation: true)
  }
  
  func kindSelectButtonTapped() {
    var kind = pickUpItem.kind
    kind.insert("わからない", at: 0)
    
    let popupPickerViewController = ANIPopupPickerViewController()
    popupPickerViewController.pickerItem = kind
    popupPickerViewController.modalPresentationStyle = .overCurrentContext
    pickMode = BasicInfoPickMode.kind
    present(popupPickerViewController, animated: false, completion: nil)
  }
  
  func ageSelectButtonTapped() {
    var age = pickUpItem.age
    age.insert("わからない", at: 0)
    
    let popupPickerViewController = ANIPopupPickerViewController()
    popupPickerViewController.pickerItem = age
    pickMode = BasicInfoPickMode.age
    popupPickerViewController.modalPresentationStyle = .overCurrentContext
    present(popupPickerViewController, animated: false, completion: nil)
  }
  
  func sexSelectButtonTapped() {
    var sex = pickUpItem.sex
    sex.insert("わからない", at: 0)
    
    let popupPickerViewController = ANIPopupPickerViewController()
    popupPickerViewController.pickerItem = sex
    pickMode = BasicInfoPickMode.sex
    popupPickerViewController.modalPresentationStyle = .overCurrentContext
    present(popupPickerViewController, animated: false, completion: nil)
  }
  
  func homeSelectButtonTapped() {
    var home = pickUpItem.home
    home.insert("わからない", at: 0)

    let popupPickerViewController = ANIPopupPickerViewController()
    popupPickerViewController.pickerItem = home
    pickMode = BasicInfoPickMode.home
    popupPickerViewController.modalPresentationStyle = .overCurrentContext
    present(popupPickerViewController, animated: false, completion: nil)
  }
  
  func vaccineSelectButtonTapped() {
    var vaccine = pickUpItem.vaccine
    vaccine.insert("わからない", at: 0)
    
    let popupPickerViewController = ANIPopupPickerViewController()
    popupPickerViewController.pickerItem = vaccine
    pickMode = BasicInfoPickMode.vaccine
    popupPickerViewController.modalPresentationStyle = .overCurrentContext
    present(popupPickerViewController, animated: false, completion: nil)
  }
  
  func castrationSelectButtonTapped() {
    var castration = pickUpItem.castration
    castration.insert("わからない", at: 0)
    
    let popupPickerViewController = ANIPopupPickerViewController()
    popupPickerViewController.pickerItem = castration
    pickMode = BasicInfoPickMode.castration
    popupPickerViewController.modalPresentationStyle = .overCurrentContext
    present(popupPickerViewController, animated: false, completion: nil)
  }
  
  func imagesPickCellTapped() {
    recruitIntroduceImagesPick(animation: true)
  }
  
  func doneEditLayout() {
    guard let contributeButton = self.contributeButton else { return }
    
    UIView.animate(withDuration: 0.2, animations: {
      contributeButton.alpha = 1.0
    })
  }
}

//MARK: ANIButtonViewDelegate
extension ANIRecruitContributionViewController: ANIButtonViewDelegate {
  func buttonViewTapped(view: ANIButtonView) {
    if view === self.contributeButton {
      guard let currentUser = ANISessionManager.shared.currentUser,
            let userId = currentUser.uid,
            let recruitContributionView = self.recruitContributionView,
            let recruitInfo = recruitContributionView.getRecruitInfo(),
            let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
            !isRejectAnimating else { return }
      
      if recruitInfo.headerImage != UIImage(named: "headerDefault") && recruitInfo.title.count > 0 && recruitInfo.kind.count > 0 && recruitInfo.age.count > 0 && recruitInfo.age.count > 0 && recruitInfo.sex.count > 0 && recruitInfo.home.count > 0 && recruitInfo.vaccine.count > 0 && recruitInfo.castration.count > 0 && recruitInfo.reason.count > 0 && recruitInfo.introduce.count > 0 && recruitInfo.passing.count > 0 && !recruitInfo.introduceImages.isEmpty {
        
        if recruitContributionMode == .edit {
          self.activityIndicatorView?.startAnimating()
        }
        
        let storageRef = Storage.storage().reference()
        
        var id = ""
        var date = ""
        if recruitContributionMode == .new {
          id = NSUUID().uuidString
          date = ANIFunction.shared.getToday()
        } else if recruitContributionMode == .edit, let recruit = self.recruit, let recruitId = recruit.id {
          deleteStorage()
          
          id = recruitId
          date = recruit.date
        }
        
        var recruit = FirebaseRecruit(id: id, headerImageUrl: nil, title: recruitInfo.title, kind: recruitInfo.kind, age: recruitInfo.age, sex: recruitInfo.sex, home: recruitInfo.home, vaccine: recruitInfo.vaccine, castration: recruitInfo.castration, reason: recruitInfo.reason, introduce: recruitInfo.introduce, introduceImageUrls: nil, passing: recruitInfo.passing, recruitState: 0, userId: userId, date: date, isLoved: nil, isCliped: nil, isSupported: nil, hideUserIds: nil)
        
        DispatchQueue.global().async {
          DispatchQueue.main.async {
            self.delegate?.loadThumnailImage(thumbnailImage: recruitInfo.headerImage)
          }
          
          if let recruitHeaderImageData = recruitInfo.headerImage.jpegData(compressionQuality: 0.5) {
            let uuid = NSUUID().uuidString
            storageRef.child(KEY_RECRUIT_HEADER_IMAGES).child(uuid).putData(recruitHeaderImageData, metadata: nil) { (metaData, error) in
              if error != nil {
                DLog("storageError")
                return
              }
              
              storageRef.child(KEY_RECRUIT_HEADER_IMAGES).child(uuid).downloadURL(completion: { (url, error) in
                if error != nil {
                  DLog("storage download url error")
                  return
                }
                
                if let recruitHeaderImageUrl = url {
                  recruit.headerImageUrl = recruitHeaderImageUrl.absoluteString
  
                  DispatchQueue.main.async {
                    self.updateDatabase(recruit: recruit, id: id)
                  }
                }
              })
            }
          }
        }
        
        DispatchQueue.global().async {
        var introduceImageUrls = [Int: String]()
          for (index, introduceImage) in recruitInfo.introduceImages.enumerated() {
            if let introduceImage = introduceImage, let introduceImageData = introduceImage.jpegData(compressionQuality: 0.5) {
              let uuid = NSUUID().uuidString
              let uploadTask = storageRef.child(KEY_RECRUIT_INTRODUCE_IMAGES).child(uuid).putData(introduceImageData, metadata: nil) { (metaData, error) in
                if error != nil {
                  DLog("storageError")
                  return
                }
                
                storageRef.child(KEY_RECRUIT_INTRODUCE_IMAGES).child(uuid).downloadURL(completion: { (url, error) in
                  if error != nil {
                    DLog("storage download url error")
                    return
                  }
                  
                  if let introduceImageUrl = url {
                    introduceImageUrls[index] = introduceImageUrl.absoluteString
                    if introduceImageUrls.count == recruitInfo.introduceImages.count {
                      let sortdUrls = introduceImageUrls.sorted(by: {$0.0 < $1.0})
                      var urls = [String]()
                      for url in sortdUrls {
                        urls.append(url.value)
                      }
  
                      recruit.introduceImageUrls = urls
  
                      DispatchQueue.main.async {
                        self.updateDatabase(recruit: recruit, id: id)
                      }
                    }
                  }
                })
              }
              
              if index == 0 {
                uploadTask.observe(.progress, handler: { (snpashot) in
                  guard let progress = snpashot.progress else { return }
                  
                  let floorProgress = (floor((CGFloat(progress.completedUnitCount) / CGFloat(progress.totalUnitCount)) * 10) / 10) * 0.9
                  
                  self.delegate?.updateProgress(progress: floorProgress)
                })
              }
            }
          }
        }
        
        self.view.endEditing(true)
        
        if recruitContributionMode == .new {
          self.dismiss(animated: true) {
            ANIFunction.shared.showReviewAlertContribution()
          }
        }
      } else {
        rejectViewBottomConstraint.constant = UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT
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
          })
        }
      }
    }
  }
}
