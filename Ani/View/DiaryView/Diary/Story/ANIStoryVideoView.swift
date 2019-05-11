//
//  ANIStoryVideoView.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/24.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import AVFoundation
import Gallery

protocol ANIStoryVideoViewDelegate {
  func loadedVideo(urlString: String, asset: AVAsset)
}

class ANIStoryVideoView: UIView {
  
  private weak var playerView: UIView?
  private weak var playerLayer: AVPlayerLayer?
  private weak var previewImageView: UIImageView?
  
  private weak var speakerImageView: UIImageView?
  
  private var player: AVPlayer {
    guard let playerLayer = self.playerLayer,
          let player = playerLayer.player else { return AVPlayer() }
    
    return player
  }
  
  var videoAsset: AVAsset?
  
  var delegate: ANIStoryVideoViewDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func layoutSubviews() {
    super.layoutSubviews()

    guard let playerView = self.playerView,
          let playerLayer = self.playerLayer else { return }

    playerLayer.frame = playerView.frame
  }
  
  private func setup() {
    self.backgroundColor = ANIColor.gray
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTap))
    singleTapGesture.numberOfTapsRequired = 1
    self.addGestureRecognizer(singleTapGesture)
    
    //playerView
    let playerView = UIView()
    self.addSubview(playerView)
    playerView.edgesToSuperview()
    self.playerView = playerView
    
    //playerLayer
    let playerLayer = AVPlayerLayer()
    playerLayer.videoGravity = .resizeAspect
    playerLayer.backgroundColor = ANIColor.gray.cgColor
    playerView.layer.addSublayer(playerLayer)
    self.playerLayer = playerLayer
    
    //previewImageView
    let previewImageView = UIImageView()
    previewImageView.contentMode = .scaleAspectFit
    self.addSubview(previewImageView)
    previewImageView.edgesToSuperview()
    self.previewImageView = previewImageView
    
    //speakerImageView
    let speakerImageView = UIImageView()
    speakerImageView.contentMode = .scaleAspectFill
    speakerImageView.image = UIImage(named: "speakerOff")
    speakerImageView.alpha = 0.0
    self.addSubview(speakerImageView)
    speakerImageView.bottomToSuperview(offset: -10.0)
    speakerImageView.leftToSuperview(offset: 10.0)
    speakerImageView.width(30.0)
    speakerImageView.height(30.0)
    self.speakerImageView = speakerImageView
  }
  
  @objc func singleTap() {
    muteUnmute()
  }
  
  @objc func playerItemDidReachEnd(_ note: Notification) {
    player.actionAtItemEnd = .none
    player.seek(to: CMTime.zero)
    player.play()
  }
  
  func loadVideo(_ url: URL) {
    guard let playerLayer = self.playerLayer,
          let previewImageView = self.previewImageView else { return }
    
    var player: AVPlayer
    
    previewImageView.alpha = 1.0
    
    if let videoAsset = self.videoAsset {
      let playerItem = AVPlayerItem(asset: videoAsset)
      player = AVPlayer(playerItem: playerItem)
      player.isMuted = true
      
      playerLayer.player = player
    } else {
      let asset = AVAsset(url: url)
      self.videoAsset = asset
      self.delegate?.loadedVideo(urlString: url.absoluteString, asset: asset)
      
      let playerItem = AVPlayerItem(url: url)
      player = AVPlayer(playerItem: playerItem)
      player.isMuted = true
      
      playerLayer.player = player
    }
  }
  
  private func pauseUnpause() {
    (player.rate == 0.0) ? play() : pause()
  }
  
  func muteUnmute() {
    guard let speakerImageView = self.speakerImageView else { return }
    
    player.isMuted = !player.isMuted
    
    if player.isMuted {
      do {
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      } catch {
        DLog("AVAudioSession catgery set error \(error)")
      }
      
      speakerImageView.image = UIImage(named: "speakerOff")
    } else {
      do {
        try AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default)
      } catch {
        DLog("AVAudioSession catgery set error \(error)")
      }

      speakerImageView.image = UIImage(named: "speakerOn")
    }
    
    UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
      speakerImageView.alpha = 1.0
    }) { (complete) in
      UIView.animate(withDuration: 0.3, delay: 3, options: .curveEaseInOut, animations: {
        speakerImageView.alpha = 0.0
      }, completion: nil)
    }
  }
  
  func play() {
    guard let previewImageView = self.previewImageView,
          let speakerImageView = self.speakerImageView,
          self.videoAsset != nil else { return }
    
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
    } catch {
      DLog("AVAudioSession catgery set error \(error)")
    }
    
    player.play()
    player.isMuted = true
    addReachEndObserver()
    
    UIView.animate(withDuration: 0.3) {
      previewImageView.alpha = 0.0
    }
    
    speakerImageView.image = UIImage(named: "speakerOff")
    speakerImageView.alpha = 1.0
    UIView.animate(withDuration: 0.3, delay: 3, options: .curveEaseInOut, animations: {
      speakerImageView.alpha = 0.0
    }, completion: nil)
  }
  
  func pause() {
    player.pause()
  }
  
  func stop() {
    player.pause()
    player.seek(to: CMTime.zero)
    removeReachEndObserver()
  }
  
  func deallocate() {
    guard let playerLayer = self.playerLayer else { return }
    
    playerLayer.player = nil
  }
  
  func setPreviewImage(_ url: URL) {
    guard let previewImageView = self.previewImageView else { return }
    
    previewImageView.sd_setImage(with: url, completed: nil)
  }
  
  func addReachEndObserver() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerItemDidReachEnd(_:)),
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: nil)
  }
  
  func removeReachEndObserver() {
    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
  }
}
