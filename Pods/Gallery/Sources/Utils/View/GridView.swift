import UIKit
import Photos

protocol GridViewDelegate {
  func previewImageDidScroll(offset: CGPoint)
  func previewImageDidZoom(scale: CGFloat)
  func previewVideoDidScroll(offset: CGPoint)
  func previewVideoDidZoom(scale: CGFloat)
}

class GridView: UIView {
  
  // MARK: - Initialization
  
  var topViewTopConstraint: NSLayoutConstraint?
  lazy var topView: UIView = self.makeTopView()
  lazy var bottomView: UIView = self.makeBottomView()
  lazy var arrowButton: ArrowButton = self.makeArrowButton()
  
  lazy var previewScollView: UIScrollView = self.makePreviewScrollView()
  lazy var previewImageView: UIImageView = self.makePreviewImageView()
  lazy var fitButton: UIButton = self.makeFitButton()
  
  lazy var videoPreviewView: UIView = self.makeVideoPreviewView()
  var player: AVPlayer?
  var isDefaultVideo: Bool = true
  var thumnailImage: UIImage? {
    didSet {
      self.previewImageView.image = thumnailImage
    }
  }
  var videoPlayerItem: AVPlayerItem? {
    didSet {
      let asset = self.videoPlayerItem?.asset
      let track = asset?.tracks(withMediaType: .video).first
      guard let trackUnrap = track else { return }
      let size = __CGSizeApplyAffineTransform(trackUnrap.naturalSize, trackUnrap.preferredTransform)
      let videoSize = CGSize(width: abs(size.width), height: abs(size.height))
      
      setVideoPlayer(size: videoSize)
    }
  }
  
  lazy var collectionView: UICollectionView = self.makeCollectionView()
  lazy var closeButton: UIButton = self.makeCloseButton()
  lazy var doneButton: UIButton = self.makeDoneButton()
  lazy var emptyView: UIView = self.makeEmptyView()
  lazy var loadingIndicator: UIActivityIndicatorView = self.makeLoadingIndicator()
  
  var delegate: GridViewDelegate?
  var isShown = true
  let imageCropViewMinimalVisibleHeight: CGFloat  = 50.0
  internal let panGestureHelper = PanGestureHelper()
  
  var squaredZoomScale: CGFloat = 1.0
  var offset: CGPoint = CGPoint(x: 0.0, y: 0.0)
  var isSelectedImage = false
  var image: UIImage? = nil {
    didSet {
      guard let image = self.image else { return }
      self.previewScollView.minimumZoomScale = 1.0
      self.previewScollView.setZoomScale(1.0, animated: false)
      if Config.Camera.oneImageMode {
        self.previewScollView.contentOffset = CGPoint(x: 0, y: 0)
      }
      
      let screenSize: CGFloat = UIScreen.main.bounds.width
      
      var squareZoomScale: CGFloat = 1.0
      let w = image.size.width
      let h = image.size.height
      
      if w >= h {
        squareZoomScale = (1.0 / (w / h))
        self.previewImageView.frame.size.width = screenSize
        self.previewImageView.frame.size.height = screenSize*squareZoomScale
      } else if h > w {
        squareZoomScale = (1.0 / (h / w))
        self.previewImageView.frame.size.width = screenSize*squareZoomScale
        self.previewImageView.frame.size.height = screenSize
      }
      self.previewImageView.center = self.previewScollView.center
      
      if w == h {
        self.previewImageView.frame.origin.x = 0
        self.previewImageView.frame.origin.y = 0
      }
      
      self.previewImageView.image = self.image
      previewImageView.clipsToBounds = true
      refreshZoomScale()
      
      previewScollView.setZoomScale(squaredZoomScale, animated: false)
      previewScollView.contentOffset.x = (previewImageView.frame.size.width - previewScollView.bounds.size.width) / 2.0
      previewScollView.contentOffset.y = (previewImageView.frame.size.height - previewScollView.bounds.size.height) / 2.0
      
      if Config.Camera.oneImageMode {
        self.previewScollView.minimumZoomScale = squaredZoomScale
      }
    }
  }
  var selectedImage: UIImage! = nil {
    didSet {
      previewScollView.setZoomScale(1.0, animated: false)
      
      let screenSize: CGFloat = UIScreen.main.bounds.width
      
      var squareZoomScale: CGFloat = 1.0
      let w = selectedImage.size.width
      let h = selectedImage.size.height
      
      if w >= h { // Landscape
        squareZoomScale = (1.0 / (w / h))
        self.previewImageView.frame.size.width = screenSize
        self.previewImageView.frame.size.height = screenSize*squareZoomScale
      } else if h > w { // Portrait
        squareZoomScale = (1.0 / (h / w))
        self.previewImageView.frame.size.width = screenSize*squareZoomScale
        self.previewImageView.frame.size.height = screenSize
      }
      
      if w == h {
        self.previewImageView.frame.origin.x = 0
        self.previewImageView.frame.origin.y = 0
      }
      
      if squaredZoomScale == 1 {
        let boundsSize = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        var contentsFrame = previewImageView.frame
        if contentsFrame.size.width < boundsSize.width {
          contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
          contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
          contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
          contentsFrame.origin.y = 0.0
        }
        
        previewImageView.frame = contentsFrame
      }
      
      self.previewImageView.image = selectedImage
      previewImageView.clipsToBounds = true
      
      previewScollView.setZoomScale(squaredZoomScale, animated: false)
      previewScollView.contentOffset = offset
    }
  }
  var shouldCropToSquare = false
  
  var dropDownController: DropdownController?
  
  // MARK: - Initialization
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
    loadingIndicator.startAnimating()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup
  
  private func setup() {
    panGestureHelper.registerForPanGesture(on: self)
    
    [previewScollView, fitButton, collectionView, bottomView, topView, emptyView, loadingIndicator].forEach {
      addSubview($0)
    }
    
    [previewImageView, videoPreviewView].forEach {
      previewScollView.addSubview($0)
    }
    
    [closeButton, arrowButton, doneButton].forEach {
      topView.addSubview($0)
    }
    
    Constraint.on(
      topView.leftAnchor.constraint(equalTo: topView.superview!.leftAnchor),
      topView.rightAnchor.constraint(equalTo: topView.superview!.rightAnchor),
      topView.heightAnchor.constraint(equalToConstant: 44),
      
      loadingIndicator.centerXAnchor.constraint(equalTo: loadingIndicator.superview!.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: loadingIndicator.superview!.centerYAnchor)
    )
    
    if #available(iOS 11, *) {
      topViewTopConstraint = topView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor)
      topViewTopConstraint?.isActive = true
    } else {
      topViewTopConstraint =  topView.topAnchor.constraint(equalTo: topView.superview!.topAnchor)
      topViewTopConstraint?.isActive = true
    }
    
    bottomView.g_pinDownward()
    bottomView.g_pin(height: 80)
    
    emptyView.g_pinEdges(view: collectionView)
    
    let previewScrollViewHeight: CGFloat = UIScreen.main.bounds.width * Config.Grid.previewRatio
    previewScollView.g_pin(height: previewScrollViewHeight)
    previewScollView.g_pin(on: .left)
    previewScollView.g_pin(on: .right)
    previewScollView.g_pin(on: .top, view: topView, on: .bottom, constant: 1)
    
    previewImageView.frame = CGRect(origin: CGPoint.zero, size: CGSize.zero)
    
    fitButton.g_pin(size: CGSize(width: 40, height: 40))
    fitButton.g_pin(on: .bottom, view: collectionView, on: .top, constant: -10)
    fitButton.g_pin(on: .left, constant: 10)
    
    collectionView.g_pinDownward()
    collectionView.g_pin(on: .top, view: previewScollView, on: .bottom, constant: 1)
    
    closeButton.g_pin(on: .top)
    closeButton.g_pin(on: .left)
    closeButton.g_pin(size: CGSize(width: 44, height: 44))
    
    arrowButton.g_pinCenter()
    arrowButton.g_pin(height: 44)
    
    doneButton.g_pin(on: .top)
    doneButton.g_pin(on: .right)
    doneButton.g_pin(size: CGSize(width: 60, height: 44))
  }
  
  // MARK: - Controls
  
  private func makeTopView() -> UIView {
    let view = UIView()
    view.backgroundColor = UIColor.white
    
    return view
  }
  
  private func makeBottomView() -> UIView {
    let view = UIView()
    
    return view
  }
  
  private func makeArrowButton() -> ArrowButton {
    let button = ArrowButton()
    button.layoutSubviews()
    
    return button
  }
  
  private func makeGridView() -> GridView {
    let view = GridView()
    
    return view
  }
  
  private func makeCloseButton() -> UIButton {
    let button = UIButton(type: .custom)
    let buttonImage = UIImage(named: "dismissButton")?.withRenderingMode(.alwaysTemplate)
    button.setImage(buttonImage, for: .normal)
    button.tintColor = UIColor(red: 48/255, green: 48/255, blue: 48/255, alpha: 1)
    
    return button
  }
  
  private func makeDoneButton() -> UIButton {
    //ANIColor.emerald
    let button = UIButton(type: .system)
    button.setTitleColor(UIColor(red: 33/255, green: 183/255, blue: 169/255, alpha: 1), for: UIControl.State())
    button.isEnabled = false
    button.setTitleColor(UIColor.lightGray, for: .disabled)
    button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    button.setTitle("Gallery.Done".g_localize(fallback: "選択"), for: UIControl.State())
    
    return button
  }
  
  private func makeCollectionView() -> UICollectionView {
    let layout = UICollectionViewFlowLayout()
    layout.minimumInteritemSpacing = 2
    layout.minimumLineSpacing = 2
    
    let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
    view.backgroundColor = UIColor.white
    
    return view
  }
  
  private func makeFitButton() -> UIButton {
    let view = UIButton()
    
    view.setImage(UIImage(named: "fitButton"), for: .normal)
    view.addTarget(self, action: #selector(squareCropButtonTapped), for: .touchUpInside)
    
    if Config.Camera.oneImageMode {
      view.alpha = 0.0
    } else {
      view.alpha = 1.0
    }
    
    return view
  }
  
  @objc func squareCropButtonTapped() {
    let z = previewScollView.zoomScale
    if z <= 1 {
      shouldCropToSquare = true
    } else {
      shouldCropToSquare = false
    }
    setFitImage(shouldCropToSquare)
  }
  
  private func setFitImage(_ fit: Bool, animated isAnimated: Bool = true) {
    let animated = isAnimated
    if fit {
      if isSelectedImage {
        var squareZoomScale: CGFloat = 1.0
        var w: CGFloat = 0.0
        var h: CGFloat = 0.0
        
        if let selectedImage = self.selectedImage {
          w = selectedImage.size.width
          h = selectedImage.size.height
        }

        if w >= h {
          squareZoomScale = (w / h)
        } else if h > w {
          squareZoomScale = (h / w)
        }
        
        self.previewScollView.setZoomScale(squareZoomScale, animated: animated)
      } else {
        self.previewScollView.setZoomScale(squaredZoomScale, animated: animated)
      }
    } else {
      self.previewScollView.setZoomScale(1, animated: animated)
    }
  }
  
  private func makePreviewScrollView() -> UIScrollView {
    let view = UIScrollView()
    view.delegate = self
    view.maximumZoomScale = 6.0
    view.minimumZoomScale = 1
    view.showsHorizontalScrollIndicator = false
    view.showsVerticalScrollIndicator   = false
    view.alwaysBounceHorizontal = false
    view.alwaysBounceVertical = false
    view.isScrollEnabled = true
    view.bouncesZoom = false
    view.bounces = false
    
    return view
  }
  
  private func makePreviewImageView() -> UIImageView {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    
    return view
  }
  
  private func makeVideoPreviewView() -> UIView {
    let view = UIView()
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoPreviewViewTapped))
    view.addGestureRecognizer(tapGesture)
    
    return view
  }
  
  private func setVideoPlayer(size: CGSize) {
    self.previewScollView.minimumZoomScale = 1.0
    self.previewScollView.setZoomScale(1.0, animated: false)
    self.previewScollView.contentOffset = CGPoint(x: 0, y: 0)
    
    videoPreviewView.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
    
    player = AVPlayer.init(playerItem: self.videoPlayerItem)
    let playerLayer = AVPlayerLayer(player: player)
    playerLayer.videoGravity = .resizeAspect
    videoPreviewView.layer.insertSublayer(playerLayer, at: 0)
    
    let screenSize: CGFloat = UIScreen.main.bounds.width
    self.videoPreviewView.frame.size.width = screenSize
    self.videoPreviewView.frame.size.height = screenSize
    
    var squareZoomScale: CGFloat = 1.0
    
    let w = size.width
    let h = size.height
    
    if w >= h { // Landscape
      squareZoomScale = (1.0 / (w / h))
      self.videoPreviewView.frame.size.width = screenSize
      self.videoPreviewView.frame.size.height = screenSize*squareZoomScale
      
    } else if h > w { // Portrait
      squareZoomScale = (1.0 / (h / w))
      self.videoPreviewView.frame.size.width = screenSize*squareZoomScale
      self.videoPreviewView.frame.size.height = screenSize
    }
    self.videoPreviewView.center = self.previewScollView.center
    self.videoPreviewView.frame.origin.y = self.videoPreviewView.frame.origin.y - self.topView.frame.height - 1

    playerLayer.frame = CGRect(x: 0, y: 0, width: videoPreviewView.frame.width, height: videoPreviewView.frame.height)
    
    self.previewImageView.center = self.previewScollView.center
    self.previewImageView.frame.size.width = self.videoPreviewView.frame.size.width
    self.previewImageView.frame.size.height = self.videoPreviewView.frame.size.height
    self.previewImageView.frame.origin.y = self.videoPreviewView.frame.origin.y
    if w == h {
      self.previewImageView.frame.origin.x = 0
      self.previewImageView.frame.origin.y = 0
      self.videoPreviewView.frame.origin.x = 0
      self.videoPreviewView.frame.origin.y = 0
    }
    self.previewImageView.clipsToBounds = true
    
    refreshZoomScale(videoSize: size)
    
    previewScollView.setZoomScale(squaredZoomScale, animated: false)
    previewScollView.contentOffset.x = (previewImageView.frame.size.width - previewScollView.bounds.size.width) / 2.0
    previewScollView.contentOffset.y = (previewImageView.frame.size.height - previewScollView.bounds.size.height) / 2.0
    
    if !isDefaultVideo {
      player?.play()
    }
  }
  
  private func makeEmptyView() -> EmptyView {
    let view = EmptyView()
    view.isHidden = true
    
    return view
  }
  
  private func makeLoadingIndicator() -> UIActivityIndicatorView {
    let view = UIActivityIndicatorView(style: .whiteLarge)
    view.color = .gray
    view.hidesWhenStopped = true
    
    return view
  }
  
  func refreshZoomScale(videoSize: CGSize? = nil) {
    var squareZoomScale: CGFloat = 1.0
    var w: CGFloat = 0.0
    var h: CGFloat = 0.0
    
    if let image = self.image {
      if !isSelectedImage {
        w = image.size.width
        h = image.size.height
      } else {
        if let selectedImage = self.selectedImage {
          w = selectedImage.size.width
          h = selectedImage.size.height
        }
      }
    }
    
    if let videoSize = videoSize {
      w = videoSize.width
      h = videoSize.height
    }
    
    if w >= h {
      squareZoomScale = (w / h)
    } else if h > w {
      squareZoomScale = (h / w)
    }
    squaredZoomScale = squareZoomScale
  }
  
  @objc private func videoPreviewViewTapped() {
    guard let player = self.player else { return }
    if player.rate != 0 {
      player.pause()
    } else {
      player.play()
    }
  }
  
  func addReachEndObserver() {
    removeReachEndObserver()
    NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
  }
  
  func removeReachEndObserver() {
    NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
  }
  
  @objc private func playerItemDidReachEnd() {
    guard let player = self.player else { return }

    player.actionAtItemEnd = .none
    player.seek(to: CMTime.zero)
    player.play()
  }
}

enum DragDirection {
  case scroll
  case stop
  case up
  case down
}

public class PanGestureHelper: NSObject, UIGestureRecognizerDelegate {
  
  var v: GridView!
  private let topViewOriginalConstraintTop: CGFloat = 0
  private var dragDirection = DragDirection.up
  private var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
  private var bottomY: CGFloat  = 0.0
  private var dragStartPos: CGPoint = .zero
  private let dragDiff: CGFloat = 0
  private var _isImageShown = true
  
  var isImageShown: Bool {
    get { return self._isImageShown }
    set {
      if newValue != isImageShown {
        self._isImageShown = newValue
        v.isShown = newValue
      }
    }
  }
  
  func registerForPanGesture(on view: GridView) {
    v = view
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
    panGesture.delegate = self
    view.addGestureRecognizer(panGesture)
    v.topViewTopConstraint?.constant = 0
  }
  
  func resetToOriginalState() {
    v.topViewTopConstraint?.constant = topViewOriginalConstraintTop
    UIView.animate(withDuration: 0.3,
                   delay: 0.0,
                   options: .curveEaseOut,
                   animations: v.layoutIfNeeded,
                   completion: nil)
    dragDirection = .up
  }
  
  func resetToOriginalStateTappedCell(index: IndexPath) {
    if v.topViewTopConstraint?.constant != topViewOriginalConstraintTop {
      v.topViewTopConstraint?.constant = topViewOriginalConstraintTop
      UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
        self.v.collectionView.scrollToItem(at: index, at: .top, animated: false)
        self.v.layoutIfNeeded()
      }, completion: nil)
      dragDirection = .up
    } else {
      self.v.collectionView.scrollToItem(at: index, at: .top, animated: true)
    }
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
    otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    let p = gestureRecognizer.location(ofTouch: 0, in: v)
    // Desactivate pan on image when it is shown.
    if isImageShown {
      if p.y < v.frame.width * Config.Grid.previewRatio {
        return false
      }
    }
    return true
  }
  
  @objc func panned(_ sender: UIPanGestureRecognizer) {
    guard let dropDownController = v.dropDownController,
          !dropDownController.expanding else { return }
    
    let preViewHeight = v.topView.frame.height + v.previewScollView.frame.height
    if sender.state == UIGestureRecognizer.State.began {
      let view    = sender.view
      let loc     = sender.location(in: view)
      let subview = view?.hitTest(loc, with: nil)
      
      if subview == v.previewImageView
        && v.topViewTopConstraint?.constant == topViewOriginalConstraintTop {
        return
      }
      
      dragStartPos = sender.location(in: v)
      bottomY = v.topView.frame.origin.y + preViewHeight
      
      // Move
      if dragDirection == .stop {
        dragDirection = (v.topViewTopConstraint?.constant == topViewOriginalConstraintTop)
          ? .up
          : .down
      }
      
      // Scroll event of CollectionView is preferred.
      if (dragDirection == .up && dragStartPos.y < bottomY + dragDiff) ||
        (dragDirection == .down && dragStartPos.y > bottomY) {
        dragDirection = .stop
      }
    } else if sender.state == UIGestureRecognizer.State.changed {
      let currentPos = sender.location(in: v)
      if dragDirection == .up && currentPos.y < bottomY - dragDiff {
        let moveY = max(v.imageCropViewMinimalVisibleHeight - preViewHeight,
                      currentPos.y + dragDiff - preViewHeight)
        if moveY < 0 {
          v.topViewTopConstraint?.constant = moveY
        }
      } else if dragDirection == .down && currentPos.y > bottomY {
        v.topViewTopConstraint?.constant =
          min(topViewOriginalConstraintTop, currentPos.y - preViewHeight)
      } else if dragDirection == .stop && v.collectionView.contentOffset.y < 0 {
        dragDirection = .scroll
        imaginaryCollectionViewOffsetStartPosY = currentPos.y
      } else if dragDirection == .scroll {
        v.topViewTopConstraint?.constant =
          v.imageCropViewMinimalVisibleHeight - preViewHeight
          + currentPos.y - imaginaryCollectionViewOffsetStartPosY
      }
    } else {
      imaginaryCollectionViewOffsetStartPosY = 0.0
      if sender.state == UIGestureRecognizer.State.ended && dragDirection == .stop {
        return
      }
      let currentPos = sender.location(in: v)
      if currentPos.y < bottomY - dragDiff
        && v.topViewTopConstraint?.constant != topViewOriginalConstraintTop {
        // The largest movement
        v.topViewTopConstraint?.constant =
          v.imageCropViewMinimalVisibleHeight - preViewHeight
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: v.layoutIfNeeded,
                       completion: nil)
        dragDirection = .down
      } else {
        // Get back to the original position
        resetToOriginalState()
      }
    }
    
    // Update isImageShown
    isImageShown = v.topViewTopConstraint?.constant == 0
  }
}

extension GridView: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    if self.image != nil {
      return previewImageView
    } else {
      return videoPreviewView
    }
  }
  
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    if self.image != nil {
      //      let screenWidth = UIScreen.main.bounds.width
      let boundsSize = scrollView.bounds.size //CGSize(width: screenWidth, height: screenWidth)
      var contentsFrame = previewImageView.frame
      if contentsFrame.size.width < boundsSize.width {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
      } else {
        contentsFrame.origin.x = 0.0
      }
      
      if contentsFrame.size.height < boundsSize.height {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
      } else {
        contentsFrame.origin.y = 0.0
      }
      previewImageView.frame = contentsFrame
      
      self.delegate?.previewImageDidZoom(scale: scrollView.zoomScale)
    } else {
      let boundsSize = scrollView.bounds.size
      var contentsFrame = videoPreviewView.frame
      if contentsFrame.size.width < boundsSize.width {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
      } else {
        contentsFrame.origin.x = 0.0
      }
      
      if contentsFrame.size.height < boundsSize.height {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
      } else {
        contentsFrame.origin.y = 0.0
      }
      videoPreviewView.frame = contentsFrame
      previewImageView.frame = videoPreviewView.frame
      
      self.delegate?.previewVideoDidZoom(scale: scrollView.zoomScale)
    }
  }
  
  func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    if self.image != nil {
      previewScollView.contentSize = CGSize(width: previewImageView.frame.width, height: previewImageView.frame.height)
    } else {
      previewScollView.contentSize = CGSize(width: videoPreviewView.frame.width, height: videoPreviewView.frame.height)
    }
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if self.image != nil {
      self.delegate?.previewImageDidScroll(offset: scrollView.contentOffset)
    } else {
      self.delegate?.previewVideoDidScroll(offset: scrollView.contentOffset)
    }
  }
}
