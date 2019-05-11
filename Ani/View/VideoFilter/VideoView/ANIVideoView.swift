//
//  ANIVideoView.swift
//  Ani
//
//  Created by jeonminseop on 2018/12/17.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import AVFoundation
import Gallery

class ANIVideoView: UIView {

  private weak var playerView: UIView?
  weak var playerLayer: AVPlayerLayer?
  private weak var previewImageView: UIImageView?
  
  public var player: AVPlayer {
    guard let playerLayer = self.playerLayer,
          let player = playerLayer.player else { return AVPlayer() }
    
    return player
  }
  
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
    let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(singleTap))
    singleTapGesture.numberOfTapsRequired = 1
    self.addGestureRecognizer(singleTapGesture)
    
    //playerView
    let playerView = UIView()
    playerView.alpha = 0
    self.addSubview(playerView)
    playerView.edgesToSuperview()
    self.playerView = playerView
    
    //playerLayer
    let playerLayer = AVPlayerLayer()
    playerLayer.videoGravity = .resizeAspect
    playerView.layer.addSublayer(playerLayer)
    self.playerLayer = playerLayer

    //previewImageView
    let previewImageView = UIImageView()
    previewImageView.contentMode = .scaleAspectFit
    self.addSubview(previewImageView)
    previewImageView.edgesToSuperview()
    self.previewImageView = previewImageView
  }
  
  @objc internal func singleTap() {
    pauseUnpause()
  }
  
  @objc public func playerItemDidReachEnd(_ note: Notification) {
    player.actionAtItemEnd = .none
    player.seek(to: CMTime.zero)
    player.play()
  }
}

extension ANIVideoView {
  public func loadVideo(_ asset: AVAsset) {
    guard let playerLayer = self.playerLayer,
          let playerView = self.playerView else { return }
    
    var player: AVPlayer

    let playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem)

    playerLayer.player = player
    playerView.alpha = 1
  }
  
  public func pauseUnpause() {
    (player.rate == 0.0) ? play() : pause()
  }
  
  public func muteUnmute() {
    player.isMuted = !player.isMuted
  }
  
  public func play() {
    player.play()
    showPlayImage(show: false)
    addReachEndObserver()
  }
  
  public func pause() {
    player.pause()
    showPlayImage(show: true)
  }
  
  public func stop() {
    player.pause()
    player.seek(to: CMTime.zero)
    showPlayImage(show: true)
    removeReachEndObserver()
  }
  
  public func deallocate() {
    guard let playerLayer = self.playerLayer else { return }
    
    playerLayer.player = nil
  }
}

extension ANIVideoView {
  public func setPreviewImage(_ image: UIImage) {
    guard let previewImageView = self.previewImageView else { return }
    
    previewImageView.image = image
  }
  
  public func showPlayImage(show: Bool) {
//    guard let playImageView = self.playImageView else { return }
//
//    UIView.animate(withDuration: 0.1) {
//      self.playImageView.alpha = show ? 0.8 : 0
//    }
  }
  
  public func addReachEndObserver() {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerItemDidReachEnd(_:)),
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: nil)
  }
  
  public func removeReachEndObserver() {
    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
  }
}
