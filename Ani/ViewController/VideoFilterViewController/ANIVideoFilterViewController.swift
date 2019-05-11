//
//  ANIVideoViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import PryntTrimmerView
import Gallery
import Photos
import TinyConstraints
import AVKit
import FirebaseStorage

protocol ANIVideoFilterViewControllerDelegate {
  func doneFilterVideo(trimmingVideo: TrimmingVideo)
}

class ANIVideoFilterViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var navigationTitleLabel: UILabel?
  private weak var backButton: UIButton?
  private weak var doneButton: UIButton?

  private weak var previewView: UIView?
  private weak var coverImageView: UIImageView?
  
  private var videoCenterXConstraint: Constraint?
  private var videoViewLeadingConstraint: Constraint?
  private var videoCenterYConstraint: Constraint?
  private var videoViewTopConstraint: Constraint?
  private var videoViewWidthConstraint: Constraint?
  private var videoViewHeightConstraint: Constraint?
  private weak var videoView: ANIVideoView?
  
  private weak var backgroundView: UIView?
  private weak var trimmerView: TrimmerView?
  private weak var coverThumbSelectorView: ThumbSelectorView?
  
  private weak var bottomStackView: UIStackView?
  private weak var trimLabel: UILabel?
  private weak var coverLabel: UILabel?
  
  private let IMAGE_SIZE: CGSize = CGSize(width: 500.0, height: 500.0)
  
  var video: Video? {
    didSet {
      guard let video = self.video else { return }
      
      video.fetchAVAsset { (myAVAsset) in
        guard let asset = myAVAsset else { return }
        
        self.avAsset = asset
      }
    }
  }
  private var avAsset: AVAsset?
  
  private var playbackTimeCheckerTimer: Timer?
  private var imageGenerator: AVAssetImageGenerator?
  
  private var isSetVideo: Bool = false
  
  var delegate: ANIVideoFilterViewControllerDelegate?
  
  override func viewDidLoad() {
    setup()
    
    trimLabelTap()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    } catch {
      DLog("AVAudioSession catgery set error \(error)")
    }
  }
  
  override func viewDidAppear(_ animated: Bool) {
    guard let videoView = self.videoView,
          let trimmerView = self.trimmerView,
          let coverThumbSelectorView = self.coverThumbSelectorView,
          let avAsset = self.avAsset else { return }
    
    if !isSetVideo {
      videoView.loadVideo(avAsset)
      trimmerView.asset = avAsset
      do {
        let assetVideoTime = floor(CGFloat(avAsset.duration.value) / CGFloat(avAsset.duration.timescale))
        if assetVideoTime > 30 {
          let trimmedAsset = try avAsset.assetByTrimming(startTime: CMTime.zero, endTime: CMTime(value: 30, timescale: 1))
          coverThumbSelectorView.asset = trimmedAsset
          
          self.imageGenerator = AVAssetImageGenerator(asset: trimmedAsset)
        } else {
          let trimmedAsset = try avAsset.assetByTrimming(startTime: CMTime.zero, endTime: CMTime(value: CMTimeValue(assetVideoTime), timescale: 1))
          coverThumbSelectorView.asset = trimmedAsset
          
          self.imageGenerator = AVAssetImageGenerator(asset: trimmedAsset)
        }

        imageGenerator?.appliesPreferredTrackTransform = true
        didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))
      } catch let error {
        DLog("assetByTrimming error \(error)")
      }
      
      isSetVideo = true
    }
  }
  
  public override func viewWillDisappear(_ animated: Bool) {
    stopPlaybackTimeChecker()
    videoView?.stop()
  }
  
  private func setup() {
    //basic
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    UIApplication.shared.isStatusBarHidden = true
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = .white
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview(usingSafeArea: true)
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //myNavigationBase
    let myNavigationBase = UIView()
    myNavigationBar.addSubview(myNavigationBase)
    myNavigationBase.edgesToSuperview()
    self.myNavigationBase = myNavigationBase
    
    //backButton
    let backButton = UIButton()
    let backButtonImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate)
    backButton.setImage(backButtonImage, for: .normal)
    backButton.tintColor = ANIColor.dark
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBase.addSubview(backButton)
    backButton.width(44.0)
    backButton.height(44.0)
    backButton.leftToSuperview()
    backButton.centerYToSuperview()
    self.backButton = backButton
    
    //navigationTitleLabel
    let navigationTitleLabel = UILabel()
    navigationTitleLabel.text = "トリミング"
    navigationTitleLabel.textColor = ANIColor.dark
    navigationTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBase.addSubview(navigationTitleLabel)
    navigationTitleLabel.centerInSuperview()
    self.navigationTitleLabel = navigationTitleLabel
    
    //donButton
    let doneButton = UIButton()
    doneButton.setTitle("完了", for: .normal)
    doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    doneButton.setTitleColor(ANIColor.emerald, for: .normal)
    doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
    myNavigationBase.addSubview(doneButton)
    doneButton.width(60.0)
    doneButton.height(44.0)
    doneButton.centerYToSuperview()
    doneButton.rightToSuperview()
    self.doneButton = doneButton
    
    //previewView
    let previewView = UIView()
    previewView.layer.masksToBounds = true
    previewView.backgroundColor = .white
    self.view.addSubview(previewView)
    previewView.topToBottom(of: myNavigationBar)
    previewView.leftToSuperview()
    previewView.rightToSuperview()
    previewView.height(UIScreen.main.bounds.width)
    self.previewView = previewView
    
    //videoView
    let videoView = ANIVideoView()
    videoView.backgroundColor = .white
    videoView.removeReachEndObserver()
    previewView.addSubview(videoView)
    videoCenterXConstraint = videoView.centerXToSuperview(isActive: false)
    videoCenterYConstraint = videoView.centerYToSuperview(isActive: false)
    videoViewLeadingConstraint = videoView.leadingToSuperview()
    videoViewTopConstraint = videoView.topToSuperview()
    videoViewWidthConstraint = videoView.width(UIScreen.main.bounds.width)
    videoViewHeightConstraint = videoView.height(UIScreen.main.bounds.width)
    self.videoView = videoView
    
    if let video = self.video {
      updateVideoViewSize(video: video)
    }
    
    //coverImageView
    let coverImageView = UIImageView()
    coverImageView.backgroundColor = .white
    coverImageView.contentMode = .scaleAspectFill
    coverImageView.layer.masksToBounds = true
    previewView.addSubview(coverImageView)
    coverImageView.edges(to: videoView)
    self.coverImageView = coverImageView
    
    //bottomStackView
    let bottomStackView = UIStackView()
    bottomStackView.axis = .horizontal
    bottomStackView.distribution = .fillEqually
    self.view.addSubview(bottomStackView)
    bottomStackView.leftToSuperview()
    bottomStackView.rightToSuperview()
    bottomStackView.bottomToSuperview(usingSafeArea: true)
    self.bottomStackView = bottomStackView
    
    //trimLabel
    let trimLabel = UILabel()
    trimLabel.text = "トリミング"
    trimLabel.textColor = ANIColor.dark
    trimLabel.textAlignment = .center
    trimLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    trimLabel.isUserInteractionEnabled = true
    trimLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(trimLabelTap)))
    bottomStackView.addArrangedSubview(trimLabel)
    trimLabel.height(40.0)
    self.trimLabel = trimLabel
    
    //coverLabel
    let coverLabel = UILabel()
    coverLabel.text = "カバー"
    coverLabel.textColor = ANIColor.darkGray
    coverLabel.textAlignment = .center
    coverLabel.font = UIFont.boldSystemFont(ofSize: 17.0)
    coverLabel.isUserInteractionEnabled = true
    coverLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(coverLabelTap)))
    bottomStackView.addArrangedSubview(coverLabel)
    coverLabel.height(40.0)
    self.coverLabel = coverLabel
    
    //backgroundView
    let backgroundView = UIView()
    self.view.addSubview(backgroundView)
    backgroundView.topToBottom(of: previewView)
    backgroundView.leftToSuperview()
    backgroundView.rightToSuperview()
    backgroundView.bottomToTop(of: bottomStackView)
    self.backgroundView = backgroundView
    
    //trimmerView
    let trimmerView = TrimmerView()
    trimmerView.mainColor = .black
    trimmerView.handleColor = .white
    trimmerView.positionBarColor = .white
    trimmerView.maxDuration = 30.0
    trimmerView.minDuration = 3.0
    trimmerView.delegate = self
    backgroundView.addSubview(trimmerView)
    trimmerView.centerYToSuperview()
    trimmerView.height(to: backgroundView, multiplier: 1/3)
    trimmerView.leftToSuperview(offset: 30.0)
    trimmerView.rightToSuperview(offset: -30.0)
    self.trimmerView = trimmerView
    
    //coverThumbSelectorView
    let coverThumbSelectorView = ThumbSelectorView()
    coverThumbSelectorView.thumbBorderColor = .white
    coverThumbSelectorView.delegate = self
    backgroundView.addSubview(coverThumbSelectorView)
    coverThumbSelectorView.edges(to: trimmerView)
    self.coverThumbSelectorView = coverThumbSelectorView
  }
  
  private func updateVideoViewSize(video: Video) {
    guard let videoCenterXConstraint = self.videoCenterXConstraint,
          let videoCenterYConstraint = self.videoCenterYConstraint,
          let videoViewWidthConstraint = self.videoViewWidthConstraint,
          let videoViewHeightConstraint = self.videoViewHeightConstraint,
          let viedeoViewLeadingConstraint = self.videoViewLeadingConstraint,
          let viedeoViewTopConstraint = self.videoViewTopConstraint,
          let videoView = self.videoView,
          let playerLayer = videoView.playerLayer else { return }
    
    let screenSize: CGFloat = UIScreen.main.bounds.width
    videoViewWidthConstraint.constant = screenSize
    videoViewHeightConstraint.constant = screenSize
    
    var squareZoomScale: CGFloat = 1.0
    
    let w = CGFloat(video.asset.pixelWidth)
    let h = CGFloat(video.asset.pixelHeight)
    
    if w >= h { // Landscape
      squareZoomScale = (1.0 / (w / h))
      videoViewWidthConstraint.constant = screenSize
      videoViewHeightConstraint.constant = screenSize*squareZoomScale
    } else if h > w { // Portrait
      squareZoomScale = (1.0 / (h / w))
      videoViewWidthConstraint.constant = screenSize*squareZoomScale
      videoViewHeightConstraint.constant = screenSize
    }
    
    videoViewWidthConstraint.constant = videoViewWidthConstraint.constant * video.scale
    videoViewHeightConstraint.constant = videoViewHeightConstraint.constant * video.scale
    
    if videoViewWidthConstraint.constant < screenSize {
      viedeoViewLeadingConstraint.isActive = false
      videoCenterXConstraint.isActive = true
    } else {
      viedeoViewLeadingConstraint.constant = -video.offset.x
    }
    if videoViewHeightConstraint.constant < screenSize {
      viedeoViewTopConstraint.isActive = false
      videoCenterYConstraint.isActive = true
    } else {
      viedeoViewTopConstraint.constant = -video.offset.y
    }
    
    playerLayer.frame = CGRect(x: 0, y: 0, width: videoViewWidthConstraint.constant, height: videoViewHeightConstraint.constant)
  }
  
  private func updateCoverPickerBounds() {
    guard let trimmerView = self.trimmerView,
          let coverThumbSelectorView = self.coverThumbSelectorView,
          let avAsset = self.avAsset else { return }
    
    if let startTime = trimmerView.startTime,
      let endTime = trimmerView.endTime {
      if let selectedCoverTime = coverThumbSelectorView.selectedTime {
        let range = CMTimeRange(start: startTime, end: endTime)
        if !range.containsTime(selectedCoverTime) {
          do {
            let trimmedAsset = try avAsset.assetByTrimming(startTime: trimmerView.startTime ?? CMTime.zero,
                                                            endTime: trimmerView.endTime ?? avAsset.duration)
            coverThumbSelectorView.asset = trimmedAsset
            
            self.imageGenerator = AVAssetImageGenerator(asset: trimmedAsset)
            imageGenerator?.appliesPreferredTrackTransform = true
            didChangeThumbPosition(CMTime(seconds: 1, preferredTimescale: 1))
          } catch let error {
            DLog("assetByTrimming error \(error)")
          }
        }
      } else {
        // If none cover time selected yet, than set the cover to the start time of the trimmed video
      }
    }
  }
  
  @objc func itemDidFinishPlaying(_ notification: Notification) {
    guard let trimmerView = self.trimmerView,
          let videoView = self.videoView else { return }
    
    if let startTime = trimmerView.startTime {
      videoView.player.seek(to: startTime)
    }
  }
  
  func startPlaybackTimeChecker() {
    stopPlaybackTimeChecker()
    playbackTimeCheckerTimer = Timer
      .scheduledTimer(timeInterval: 0.05, target: self,
                      selector: #selector(onPlaybackTimeChecker),
                      userInfo: nil,
                      repeats: true)
  }
  
  func stopPlaybackTimeChecker() {
    playbackTimeCheckerTimer?.invalidate()
    playbackTimeCheckerTimer = nil
  }
  
  @objc func onPlaybackTimeChecker() {
    guard let videoView = self.videoView,
          let trimmerView = self.trimmerView,
          let startTime = trimmerView.startTime,
          let endTime = trimmerView.endTime else { return }
    
    let playBackTime = videoView.player.currentTime()
    trimmerView.seek(to: playBackTime)
    
    if playBackTime >= endTime {
      videoView.player.seek(to: startTime,
                            toleranceBefore: CMTime.zero,
                            toleranceAfter: CMTime.zero)
      trimmerView.seek(to: startTime)
    }
  }
  
  //MARK: action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
  
  @objc private func done() {
    guard let coverImageView = self.coverImageView,
          let coverImage = coverImageView.image,
          let trimmerView = self.trimmerView,
          let video = self.video,
          let avAsset = self.avAsset else { return }
    
    let timeRange = CMTimeRangeMake(start: trimmerView.startTime ?? CMTime.zero, duration: trimmerView.endTime ?? avAsset.duration)
    let trimmingVideo = TrimmingVideo(video: video, avAsset: avAsset, coverImage: coverImage, timeRange: timeRange)
    
    self.delegate?.doneFilterVideo(trimmingVideo: trimmingVideo)
    
    self.dismiss(animated: true, completion: nil)
  }
  
  @objc private func trimLabelTap() {
    guard let trimLabel = self.trimLabel,
          let coverLabel = self.coverLabel,
          let navigationTitleLabel = self.navigationTitleLabel,
          let trimmerView = self.trimmerView,
          let videoView = self.videoView,
          let coverImageView = self.coverImageView,
          let coverThumbSelectorView = self.coverThumbSelectorView else { return }
    
    trimLabel.textColor = ANIColor.dark
    coverLabel.textColor = ANIColor.darkGray
    
    navigationTitleLabel.text = "トリミング"
    
    trimmerView.isHidden = false
    videoView.isHidden = false
    coverImageView.isHidden = true
    coverThumbSelectorView.isHidden = true
  }
  
  @objc private func coverLabelTap() {
    guard let trimLabel = self.trimLabel,
          let coverLabel = self.coverLabel,
          let navigationTitleLabel = self.navigationTitleLabel,
          let trimmerView = self.trimmerView,
          let videoView = self.videoView,
          let coverImageView = self.coverImageView,
          let coverThumbSelectorView = self.coverThumbSelectorView else { return }
    
    coverLabel.textColor = ANIColor.dark
    trimLabel.textColor = ANIColor.darkGray
    
    navigationTitleLabel.text = "カバー"
    
    trimmerView.isHidden = true
    videoView.isHidden = true
    coverImageView.isHidden = false
    coverThumbSelectorView.isHidden = false
  }
}

//MARK: UIGestureRecognizerDelegate
extension ANIVideoFilterViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

// MARK: TrimmerViewDelegate
extension ANIVideoFilterViewController: TrimmerViewDelegate {
  public func positionBarStoppedMoving(_ playerTime: CMTime) {
    guard let videoView = self.videoView else { return }
    
    videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    videoView.play()
    startPlaybackTimeChecker()
    updateCoverPickerBounds()
  }
  
  public func didChangePositionBar(_ playerTime: CMTime) {
    guard let videoView = self.videoView else { return }

    videoView.player.seek(to: playerTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
    videoView.pause()
    stopPlaybackTimeChecker()
  }
}

// MARK: ThumbSelectorViewDelegate
extension ANIVideoFilterViewController: ThumbSelectorViewDelegate {
  public func didChangeThumbPosition(_ imageTime: CMTime) {
    guard let coverImageView = self.coverImageView,
          let imageGenerator = self.imageGenerator else { return }
    
    if let imageRef = try? imageGenerator.copyCGImage(at: imageTime, actualTime: nil) {
      coverImageView.image = UIImage(cgImage: imageRef)
    }
  }
}
