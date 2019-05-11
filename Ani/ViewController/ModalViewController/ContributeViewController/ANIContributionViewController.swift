//
//  ANIContributeViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/16.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import Gallery
import TinyConstraints
import FirebaseStorage
import FirebaseFirestore
import CodableFirebase
import AVKit
import Photos
import ActiveLabel

protocol ANIContributionViewControllerDelegate {
  func loadThumnailImage(thumbnailImage: UIImage?)
  func updateProgress(progress: CGFloat)
}

enum ContributionMode {
  case story
  case qna
}

class ANIContributionViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBarBase: UIView?
  private weak var dismissButton: UIButton?
  private weak var titleLabel: UILabel?
  private weak var contributionButtonBG: UIView?
  private weak var contributionButton: UIButton?
  
  private var rejectViewBottomConstraint: Constraint?
  private var rejectViewBottomConstraintOriginalConstant: CGFloat?
  private weak var rejectView: UIView?
  private weak var rejectBaseView: UIView?
  private weak var rejectLabel: UILabel?
  private var isRejectAnimating: Bool = false
  
  private weak var activityIndicatorView: ANIActivityIndicator?
  
  private var contributionViewOriginalBottomConstraintConstant: CGFloat?
  private var contributionViewBottomConstraint: Constraint?
  private weak var contriButionView: ANIContributionView?
  
  private var imagePickGallery = GalleryController()
  
  var navigationTitle: String?
  
  var selectedContributionMode: ContributionMode?
    
  private var contentImages = [UIImage?]() {
    didSet {
      guard let contriButionView = self.contriButionView else { return }
      
      contriButionView.contentImages = contentImages
    }
  }
  
  private var contentVideo: TrimmingVideo?
  private var videoLength: Int = 0
  private var thumbnailImage: UIImage? {
    didSet {
      guard let contriButionView = self.contriButionView else { return }
      
      contriButionView.videoLength = videoLength
      contriButionView.thumbnailImage = thumbnailImage
    }
  }
  
  private var exportTimer: Timer?
  
  var delegate: ANIContributionViewControllerDelegate?
  
  private let IMAGE_SIZE: CGSize = CGSize(width: 500.0, height: 500.0)
  
  override func viewDidLoad() {
    setup()
    setupGalleryController()
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
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = .white
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview()
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //myNavigationBarBase
    let myNavigationBarBase = UIView()
    myNavigationBar.addSubview(myNavigationBarBase)
    myNavigationBarBase.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    myNavigationBarBase.bottomToSuperview()
    myNavigationBarBase.leftToSuperview()
    myNavigationBarBase.rightToSuperview()
    self.myNavigationBarBase = myNavigationBarBase
    
    //dismissButton
    let dismissButton = UIButton()
    let dismissButtonImage = UIImage(named: "dismissButton")?.withRenderingMode(.alwaysTemplate)
    dismissButton.setImage(dismissButtonImage, for: .normal)
    dismissButton.tintColor = ANIColor.dark
    dismissButton.addTarget(self, action: #selector(contributeDismiss), for: .touchUpInside)
    myNavigationBarBase.addSubview(dismissButton)
    dismissButton.width(UIViewController.NAVIGATION_BAR_HEIGHT)
    dismissButton.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    dismissButton.leftToSuperview()
    dismissButton.centerYToSuperview()
    self.dismissButton = dismissButton
    
    //titleLabel
    let titleLabel = UILabel()
    titleLabel.text = navigationTitle
    titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    titleLabel.textColor = ANIColor.dark
    myNavigationBarBase.addSubview(titleLabel)
    titleLabel.centerInSuperview()
    self.titleLabel = titleLabel
    
    //contributionButtonBG
    let contributionButtonBG = UIView()
    contributionButtonBG.layer.cornerRadius = (UIViewController.NAVIGATION_BAR_HEIGHT - 10.0) / 2
    contributionButtonBG.layer.masksToBounds = true
    contributionButtonBG.backgroundColor = ANIColor.emerald
    contributionButtonBG.alpha = 0.5
    myNavigationBarBase.addSubview(contributionButtonBG)
    contributionButtonBG.centerYToSuperview()
    contributionButtonBG.rightToSuperview(offset: -10.0)
    contributionButtonBG.width(70.0)
    contributionButtonBG.height(UIViewController.NAVIGATION_BAR_HEIGHT - 10.0)
    self.contributionButtonBG = contributionButtonBG
    
    //contributionButton
    let contributionButton = UIButton()
    contributionButton.setTitle("投稿", for: .normal)
    contributionButton.setTitleColor(.white, for: .normal)
    contributionButton.addTarget(self, action: #selector(contribute), for: .touchUpInside)
    contributionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16.0)
    contributionButton.isEnabled = false
    contributionButtonBG.addSubview(contributionButton)
    contributionButton.centerInSuperview()
    contributionButton.size(to: contributionButtonBG)
    self.contributionButton = contributionButton
    
    //contriButionView
    let contriButionView = ANIContributionView()
    contriButionView.selectedContributionMode = selectedContributionMode
    contriButionView.delegate = self
    self.view.addSubview(contriButionView)
    contriButionView.topToBottom(of: myNavigationBar)
    contriButionView.leftToSuperview()
    contriButionView.rightToSuperview()
    contributionViewBottomConstraint = contriButionView.bottomToSuperview()
    contributionViewOriginalBottomConstraintConstant = contributionViewBottomConstraint?.constant
    self.contriButionView = contriButionView
    
    //rejectView
    let rejectView = UIView()
    rejectView.backgroundColor = ANIColor.darkGray
    self.view.addSubview(rejectView)
    rejectViewBottomConstraint = rejectView.bottomToTop(of: self.view)
    rejectViewBottomConstraintOriginalConstant = rejectViewBottomConstraint?.constant
    rejectView.leftToSuperview()
    rejectView.rightToSuperview()
    rejectView.height(UIViewController.NAVIGATION_BAR_HEIGHT + UIViewController.STATUS_BAR_HEIGHT)
    self.rejectView = rejectView
    
    //rejectBaseView
    let rejectBaseView = UIView()
    rejectBaseView.backgroundColor = ANIColor.darkGray
    rejectView.addSubview(rejectBaseView)
    rejectBaseView.edgesToSuperview(excluding: .top)
    rejectBaseView.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.rejectBaseView = rejectBaseView
    
    //rejectLabel
    let rejectLabel = UILabel()
    rejectLabel.textAlignment = .center
    rejectLabel.textColor = .white
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
  
  private func setupGalleryController() {
    imagePickGallery.delegate = self
    Gallery.Config.PageIndicator.backgroundColor = .white
    Gallery.Config.Font.Main.regular = UIFont.boldSystemFont(ofSize: 17)
    Gallery.Config.Grid.ArrowButton.tintColor = ANIColor.dark
    Gallery.Config.Grid.FrameView.borderColor = ANIColor.emerald
    Gallery.Config.Grid.previewRatio = 1.0
  }
  
  private func setupNotifications() {
    removeNotifications()
    ANINotificationManager.receive(keyboardWillChangeFrame: self, selector: #selector(keyboardWillChangeFrame))
    ANINotificationManager.receive(keyboardWillHide: self, selector: #selector(keyboardWillHide))
  }
  
  private func removeNotifications() {
    ANINotificationManager.remove(self)
  }
  
  func uploadImageStory() {
    guard let contriButionView = self.contriButionView,
          let currentUser = ANISessionManager.shared.currentUser,
          let uid = currentUser.uid else { return }
    
    let storageRef = Storage.storage().reference()
    var contentImageUrls = [Int: String]()
    
    DispatchQueue.global().async {
      for (index, contentImage) in self.contentImages.enumerated() {
        if let contentImage = contentImage, let contentImageData = contentImage.jpegData(compressionQuality: 0.5) {
          let uuid = UUID().uuidString
          let uploadTask = storageRef.child(KEY_STORY_IMAGES).child(uuid).putData(contentImageData, metadata: nil) { (metaData, error) in
            if error != nil {
              DLog("storage put image error")
              return
            }
            
            storageRef.child(KEY_STORY_IMAGES).child(uuid).downloadURL(completion: { (url, error) in
              if error != nil {
                DLog("storage download url error")
                return
              }
              
              if let contentImageUrl = url {
                contentImageUrls[index] = contentImageUrl.absoluteString
                if contentImageUrls.count == self.contentImages.count {
                  let sortdUrls = contentImageUrls.sorted(by: {$0.0 < $1.0})
                  var urls = [String]()
                  for url in sortdUrls {
                    urls.append(url.value)
                  }
                  
                  DispatchQueue.main.async {
                    let id = NSUUID().uuidString
                    let date = ANIFunction.shared.getToday()
                    let day = ANIFunction.shared.getToday(format: "yyyy/MM/dd")
                    let content = contriButionView.getContent()
                    let activityLabel = ActiveLabel()
                    activityLabel.enabledTypes = [.hashtag]
                    activityLabel.text = content
                    
                    var hashtags = [String: String]()
                    for hashtagElement in activityLabel.hashtagElements {
                      hashtags[hashtagElement] = date
                    }
                    
                    let story = FirebaseStory(id: id, storyImageUrls: urls, storyVideoUrl: nil, thumbnailImageUrl: nil, story: content, userId: uid, recruitId: nil, recruitTitle: nil, recruitSubTitle: nil, date: date, day: day, isLoved: nil, hideUserIds: nil, loveCount: 0, hashtags: hashtags, comments: nil)
                    
                    self.upateStroyDatabase(story: story, id: id)
                  }
                }
              }
            })
          }
          
          if index == 0 {
            DispatchQueue.main.async {
              self.delegate?.loadThumnailImage(thumbnailImage: contentImage)
            }

            uploadTask.observe(.progress, handler: { (snpashot) in
              guard let progress = snpashot.progress else { return }
              
              let floorProgress = (floor((CGFloat(progress.completedUnitCount) / CGFloat(progress.totalUnitCount)) * 10) / 10) * 0.9
              
              self.delegate?.updateProgress(progress: floorProgress)
            })
          }
        }
      }
    }
  }
  
  private func uploadVideoStory() {
    guard let contriButionView = self.contriButionView,
          let currentUser = ANISessionManager.shared.currentUser,
          let uid = currentUser.uid,
          let contentVideo = self.contentVideo else { return }
    
    let cropRect = getVisibleRect(video: contentVideo.video)
    
    guard let thumbnailImage = self.thumbnailImage,
          let thumbnailImageData = thumbnailImage.jpegData(compressionQuality: 0.5) else { return }
    
    self.delegate?.loadThumnailImage(thumbnailImage: thumbnailImage)
    
    fetchVideoUrlAndCrop(video: contentVideo, cropRect: cropRect) { (url) in
      let storageRef = Storage.storage().reference()
      
      let group = DispatchGroup()
      
      var thumbnailImageUrl = ""
      var videoUrl = ""

      group.enter()
      DispatchQueue(label: "putData").async {
        let thumnailImageUuid = UUID().uuidString
        storageRef.child(KYE_THUMNAIL_IMAGES).child(thumnailImageUuid).putData(thumbnailImageData, metadata: nil, completion: { (thumnailImageMetaData, thumbnailImageError) in
          if thumbnailImageError != nil {
            DLog("storage put thumbnail image error")
            return
          }

          storageRef.child(KYE_THUMNAIL_IMAGES).child(thumnailImageUuid).downloadURL(completion: { (url, error) in
            if thumbnailImageError != nil {
              DLog("thumbnail image download url error")
              return
            }

            guard let url = url else { return }

            thumbnailImageUrl = url.absoluteString
            group.leave()
          })
        })
      }
      

      group.enter()
      DispatchQueue(label: "putData").async {
        let videoUuid = UUID().uuidString
        let uploadTask = storageRef.child(KEY_STORY_VIDEOS).child(videoUuid).putFile(from: url, metadata: nil, completion: { (metaData, error) in
          if error != nil {
            DLog("storage put video error")
            return
          }

          storageRef.child(KEY_STORY_VIDEOS).child(videoUuid).downloadURL(completion: { (url, error) in
            if error != nil {
              DLog("storage download video url error")
              return
            }

            guard let url = url else { return }

            videoUrl = url.absoluteString
            group.leave()
          })
        })
        
        uploadTask.observe(.progress, handler: { (snpashot) in
          guard let progress = snpashot.progress else { return }
          
          let floorProgress = (floor((CGFloat(progress.completedUnitCount) / CGFloat(progress.totalUnitCount)) * 10) / 10) * 0.7
          
          self.delegate?.updateProgress(progress: floorProgress + 0.2)
        })
      }
      
      group.notify(queue: DispatchQueue(label: "putData")) {
        DispatchQueue.main.async {
          let id = NSUUID().uuidString
          let date = ANIFunction.shared.getToday()
          let day = ANIFunction.shared.getToday(format: "yyyy/MM/dd")
          let content = contriButionView.getContent()
          let activityLabel = ActiveLabel()
          activityLabel.enabledTypes = [.hashtag]
          activityLabel.text = content
          
          var hashtags = [String: String]()
          for hashtagElement in activityLabel.hashtagElements {
            hashtags[hashtagElement] = date
          }
          
          let story = FirebaseStory(id: id, storyImageUrls: nil, storyVideoUrl: videoUrl, thumbnailImageUrl: thumbnailImageUrl, story: content, userId: uid, recruitId: nil, recruitTitle: nil, recruitSubTitle: nil, date: date, day: day, isLoved: nil, hideUserIds: nil, loveCount: 0, hashtags: hashtags, comments: nil)

          self.upateStroyDatabase(story: story, id: id)
        }
      }
    }
  }
  
  func uploadQna() {
    guard let contriButionView = self.contriButionView,
          let currentUser = ANISessionManager.shared.currentUser,
          let uid = currentUser.uid else { return }
    
    let storageRef = Storage.storage().reference()
    var contentImageUrls = [Int: String]()
    
    DispatchQueue.global().async {
      if self.contentImages.isEmpty {
        DispatchQueue.main.async {
          let id = NSUUID().uuidString
          let date = ANIFunction.shared.getToday()
          let content = contriButionView.getContent()
          let activityLabel = ActiveLabel()
          activityLabel.enabledTypes = [.hashtag]
          activityLabel.text = content
          
          var hashtags = [String: String]()
          for hashtagElement in activityLabel.hashtagElements {
            hashtags[hashtagElement] = date
          }
          
          let qna = FirebaseQna(id: id, qnaImageUrls: nil, qna: content, userId: uid, date: date, isLoved: nil, hideUserIds: nil, hashtags: hashtags, comments: nil)
          
          DispatchQueue.main.async {
            self.delegate?.loadThumnailImage(thumbnailImage: nil)
          }
          
          self.delegate?.updateProgress(progress: 0.9)
        
          self.upateQnaDatabase(qna: qna, id: id)
        }
      } else {
        for (index, contentImage) in self.contentImages.enumerated() {
          if let contentImage = contentImage, let contentImageData = contentImage.jpegData(compressionQuality: 0.5) {
            let uuid = UUID().uuidString
            let uploadTask = storageRef.child(KEY_QNA_IMAGES).child(uuid).putData(contentImageData, metadata: nil) { (metaData, error) in
              if error != nil {
                DLog("storage error")
                return
              }
              
              storageRef.child(KEY_QNA_IMAGES).child(uuid).downloadURL(completion: { (url, error) in
                if error != nil {
                  DLog("storage download url error")
                  return
                }
                
                if let contentImageUrl = url {
                  contentImageUrls[index] = contentImageUrl.absoluteString
                  if contentImageUrls.count == self.contentImages.count {
                    let sortdUrls = contentImageUrls.sorted(by: {$0.0 < $1.0})
                    var urls = [String]()
                    for url in sortdUrls {
                      urls.append(url.value)
                    }
  
                    DispatchQueue.main.async {
                      let id = NSUUID().uuidString
                      let date = ANIFunction.shared.getToday()
                      let content = contriButionView.getContent()
                      let activityLabel = ActiveLabel()
                      activityLabel.enabledTypes = [.hashtag]
                      activityLabel.text = content
                      
                      var hashtags = [String: String]()
                      for hashtagElement in activityLabel.hashtagElements {
                        hashtags[hashtagElement] = date
                      }
                      
                      let qna = FirebaseQna(id: id, qnaImageUrls: urls, qna: content, userId: uid, date: date, isLoved: nil, hideUserIds: nil, hashtags: hashtags, comments: nil)
  
                      self.upateQnaDatabase(qna: qna, id: id)
                    }
                  }
                }
              })
            }
            
            if index == 0 {
              DispatchQueue.main.async {
                self.delegate?.loadThumnailImage(thumbnailImage: contentImage)
              }
              
              uploadTask.observe(.progress, handler: { (snpashot) in
                guard let progress = snpashot.progress else { return }
                
                let floorProgress = (floor((CGFloat(progress.completedUnitCount) / CGFloat(progress.totalUnitCount)) * 10) / 10) * 0.9
                
                self.delegate?.updateProgress(progress: floorProgress)
              })
            }
          }
        }
      }
    }
  }
  
  private func upateStroyDatabase(story: FirebaseStory, id: String) {
    do {
      let database = Firestore.firestore()

      let data = try FirestoreEncoder().encode(story)
      database.collection(KEY_STORIES).document(id).setData(data) { error in
        if let error = error {
          DLog("Error set document: \(error)")
          return
        }
        
        self.delegate?.updateProgress(progress: 1.0)
      }
    } catch let error {
      DLog(error)
    }
  }
  
  private func upateQnaDatabase(qna: FirebaseQna, id: String) {
    do {
      let database = Firestore.firestore()

      let data = try FirestoreEncoder().encode(qna)
      database.collection(KEY_QNAS).document(id).setData(data) { error in
        if let error = error {
          DLog("Error set document: \(error)")
          return
        }
        
        self.delegate?.updateProgress(progress: 1.0)
      }
    } catch let error {
      DLog(error)
    }
  }
  
  private func contentImagesPick(animation: Bool) {
    if selectedContributionMode == .story {
      Gallery.Config.tabsToShow = [.imageTab, .videoTab, .cameraTab]
    } else {
      Gallery.Config.tabsToShow = [.imageTab, .cameraTab]
    }
    Gallery.Config.initialTab = .imageTab
    Gallery.Config.Camera.oneImageMode = false
    Gallery.Config.Camera.imageLimit = 10

    let imagePickgalleryNV = UINavigationController(rootViewController: imagePickGallery)
    present(imagePickgalleryNV, animated: animation, completion: nil)
  }
  
  @objc private func onTickExportTimer(sender: Timer) {
    if let exportSession = sender.userInfo as? AVAssetExportSession {
      
      if exportSession.progress > 0.19 {
        sender.invalidate()
        self.exportTimer = nil
      }
      
      self.delegate?.updateProgress(progress: CGFloat(exportSession.progress * 0.2))
    }
  }
  
  @objc private func keyboardWillChangeFrame(_ notification: Notification) {
    guard let keyboardFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let contributionViewBottomConstraint = self.contributionViewBottomConstraint else { return }
    
    let h = keyboardFrame.height
    
    contributionViewBottomConstraint.constant = -h
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  @objc private func keyboardWillHide(_ notification: Notification) {
    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
          let curve = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt,
          let contributionViewOriginalBottomConstraintConstant = self.contributionViewOriginalBottomConstraintConstant,
          let contributionViewBottomConstraint = self.contributionViewBottomConstraint else { return }
    
    contributionViewBottomConstraint.constant = contributionViewOriginalBottomConstraintConstant
    
    UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: curve), animations: {
      self.view.layoutIfNeeded()
    })
  }
  
  private func reject(notiText: String) {
    guard let rejectViewBottomConstraint = self.rejectViewBottomConstraint,
          let rejectLabel = self.rejectLabel,
          !isRejectAnimating else { return }
    
    rejectLabel.text = notiText
    
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
  
  //MARK: action
  @objc private func contributeDismiss() {
    self.view.endEditing(true)
    
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
  
  @objc private func contribute() {
    guard let selectedContributionMode = self.selectedContributionMode else { return }
    
    self.view.endEditing(true)
    
    switch selectedContributionMode {
    case .story:
      if !contentImages.isEmpty {
        uploadImageStory()
      } else {
        uploadVideoStory()
      }
    case .qna:
      uploadQna()
    }
    
    self.dismiss(animated: true) {
      ANIFunction.shared.showReviewAlertContribution()
    }
  }
}

//MARK: GalleryControllerDelegate
extension ANIContributionViewController: GalleryControllerDelegate {
  func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
    
    Image.resolve(images: images) { (myImages) in
      let imageFilteriewController = ANIImageFilterViewController()
      imageFilteriewController.images = self.getCropImages(images: myImages, items: images)
      imageFilteriewController.delegate = self
      controller.navigationController?.pushViewController(imageFilteriewController, animated: true)
    }
  }
  
  func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {    
    let videoFilterViewController = ANIVideoFilterViewController()
    videoFilterViewController.video = video
    videoFilterViewController.delegate = self
    controller.navigationController?.pushViewController(videoFilterViewController, animated: true)
  }
  
  func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
    controller.dismiss(animated: true, completion: nil)
  }
  
  func galleryControllerDidCancel(_ controller: GalleryController) {
    controller.dismiss(animated: true, completion: nil)
  }
}

//MARK: ANIImageFilterViewControllerDelegate
extension ANIContributionViewController: ANIImageFilterViewControllerDelegate {
  func doneFilterImages(filteredImages: [UIImage?]) {
    guard !filteredImages.isEmpty else { return }
    
    contentImages.removeAll()
    for filteredImage in filteredImages {
      contentImages.append(filteredImage?.resize(size: IMAGE_SIZE))
    }
  }
}

//MARK: ANIVideoFilterViewControllerDelegate
extension ANIContributionViewController: ANIVideoFilterViewControllerDelegate {
  func doneFilterVideo(trimmingVideo: TrimmingVideo) {
    let image = self.getCropThumbnailImage(image: trimmingVideo.coverImage, video: trimmingVideo.video)
    let lenght = CGFloat(trimmingVideo.timeRange.duration.value) / CGFloat(trimmingVideo.timeRange.duration.timescale)
    videoLength = Int(floor(lenght))
    thumbnailImage = image.resize(size: IMAGE_SIZE)
    
    contentVideo = trimmingVideo
  }
}

//MARK: ANIContributionViewDelegate
extension ANIContributionViewController: ANIContributionViewDelegate {
  func imagesPickCellTapped() {
    contentImagesPick(animation: true)
  }
  
  func imageDeleteButtonTapped(index: Int) {
    contentImages.remove(at: index)
    imagePickGallery.cart.images.remove(at: index)
  }
  
  func videoDeleteButtonTapped() {
    contentVideo = nil
    videoLength = 0
    thumbnailImage = nil
    imagePickGallery.cart.video = nil
  }
  
  func contributionButtonOn(on: Bool) {
    guard let contributionButton = self.contributionButton,
          let contributionButtonBG = self.contributionButtonBG else { return }
    if on {
      contributionButton.isEnabled = true
      contributionButtonBG.alpha = 1.0
    } else {
      contributionButton.isEnabled = false
      contributionButtonBG.alpha = 0.5
    }
  }
}

//MARK: image, video crop
extension ANIContributionViewController {
  private func getCropImages(images: [UIImage?], items: [Image]) -> [UIImage] {
    var croppedImages = [UIImage]()
    
    for (index, image) in images.enumerated() {
      if let image = image {
        let imageSize = image.size
        let scrollViewWidth = self.view.frame.width
        let widthScale =  scrollViewWidth / imageSize.width * items[index].scale
        let heightScale = scrollViewWidth / imageSize.height * items[index].scale
        
        let scale = 1 / min(widthScale, heightScale)
        
        let visibleRect = CGRect(x: floor(items[index].offset.x * scale), y: floor(items[index].offset.y * scale), width: scrollViewWidth * scale, height: scrollViewWidth * scale * Config.Grid.previewRatio)
        let ref: CGImage = (image.cgImage?.cropping(to: visibleRect))!
        let croppedImage: UIImage = UIImage(cgImage: ref)
        
        croppedImages.append(croppedImage)
      }
    }
    return croppedImages
  }
  
  private func fetchVideoUrlAndCrop(video: TrimmingVideo, cropRect: CGRect, callback: @escaping (URL) -> Void) {
    let videosOptions = PHVideoRequestOptions()
    videosOptions.isNetworkAccessAllowed = true
    do {
      let assetComposition = AVMutableComposition()
      let trackTimeRange = video.timeRange
      
      // 1. Inserting audio and video tracks in composition
      
      guard let videoTrack = video.avAsset.tracks(withMediaType: AVMediaType.video).first,
            let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        DLog("problems with video track")
        return
                            
      }
      if let audioTrack = video.avAsset.tracks(withMediaType: AVMediaType.audio).first,
        let audioCompositionTrack = assetComposition
          .addMutableTrack(withMediaType: AVMediaType.audio,
                           preferredTrackID: kCMPersistentTrackID_Invalid) {
        try audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: CMTime.zero)
      }
      
      try videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack, at: CMTime.zero)
      
      // 2. Create the instructions
      
      let mainInstructions = AVMutableVideoCompositionInstruction()
      mainInstructions.timeRange = trackTimeRange
      
      // 3. Adding the layer instructions. Transforming
      
      let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
      layerInstructions.setTransform(videoTrack.getTransform(cropRect: cropRect), at: CMTime.zero)
      layerInstructions.setOpacity(1.0, at: CMTime.zero)
      mainInstructions.layerInstructions = [layerInstructions]
      
      // 4. Create the main composition and add the instructions
      
      let videoComposition = AVMutableVideoComposition()
      videoComposition.renderSize = cropRect.size
      videoComposition.instructions = [mainInstructions]
      videoComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
      
      // 5. Configuring export session
      
      let exportSession = AVAssetExportSession(asset: assetComposition,
                                               presetName: AVAssetExportPresetMediumQuality)
      exportSession?.outputFileType = .mp4
      exportSession?.shouldOptimizeForNetworkUse = true
      exportSession?.videoComposition = videoComposition
      exportSession?.outputURL = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingUniquePathComponent(pathExtension: AVFileType.mp4.fileExtension)
      
      // 6. Exporting
      DispatchQueue.main.async {
        self.exportTimer = Timer.scheduledTimer(timeInterval: 0.1,
                                                target: self,
                                                selector: #selector(self.onTickExportTimer),
                                                userInfo: exportSession,
                                                repeats: true)
      }
      
      exportSession?.exportAsynchronously(completionHandler: {
        DispatchQueue.main.async {
          if let url = exportSession?.outputURL, exportSession?.status == .completed {
            callback(url)
          } else {
            let error = exportSession?.error
            DLog("error exporting video \(String(describing: error))")
          }
        }
      })
    } catch let error {
      DLog("error \(error)")
    }
  }
  
  private func getVisibleRect(video: Video) -> CGRect {
    let previewViewSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
    var assetSize = CGSize(width: CGFloat(video.asset.pixelWidth), height: CGFloat(video.asset.pixelHeight))
    let widthScale = previewViewSize.width / assetSize.width
    let heightScale = previewViewSize.height / assetSize.height
    
    let minScale = min(widthScale, heightScale)
    let screenVisibleVideoSize = CGSize(width: assetSize.width * minScale, height: assetSize.height * minScale)
    let zoomSize = CGSize(width: screenVisibleVideoSize.width * video.scale, height: screenVisibleVideoSize.height * video.scale)
    
    let scale = assetSize.width / zoomSize.width
    if zoomSize.width > previewViewSize.width {
      assetSize.width = assetSize.width - ((zoomSize.width - previewViewSize.width) * scale)
    }
    
    if zoomSize.height > previewViewSize.height {
      assetSize.height = assetSize.height - ((zoomSize.height - previewViewSize.height) * scale)
    }
    
    assetSize.width = assetSize.width.rounded(.toNearestOrEven)
    assetSize.width = (assetSize.width.truncatingRemainder(dividingBy: 2) == 0) ? assetSize.width : assetSize.width - 1
    assetSize.height = assetSize.height.rounded(.toNearestOrEven)
    assetSize.height = (assetSize.height.truncatingRemainder(dividingBy: 2) == 0) ? assetSize.height : assetSize.height - 1
    
    let visibleRect = CGRect(x: floor(video.offset.x * scale), y: floor(video.offset.y * scale), width: assetSize.width, height: assetSize.height)
    
    return visibleRect
  }
  
  private func getCropThumbnailImage(image: UIImage, video: Video) -> UIImage {
    let imageSize = image.size
    let scrollViewWidth = self.view.frame.width
    let widthScale =  scrollViewWidth / imageSize.width * video.scale
    let heightScale = scrollViewWidth / imageSize.height * video.scale
    
    let scale = 1 / min(widthScale, heightScale)
    
    let visibleRect = CGRect(x: floor(video.offset.x * scale), y: floor(video.offset.y * scale), width: scrollViewWidth * scale, height: scrollViewWidth * scale * Config.Grid.previewRatio)
    let ref: CGImage = (image.cgImage?.cropping(to: visibleRect))!
    let thumbnailImage: UIImage = UIImage(cgImage: ref)
    
    return thumbnailImage
  }
}
