import UIKit
import Photos
import AVKit

class VideosController: UIViewController {
  
  lazy var dropdownController: DropdownController = self.makeDropdownController()
  
  lazy var gridView: GridView = self.makeGridView()
  lazy var videoBox: VideoBox = self.makeVideoBox()
  lazy var infoLabel: UILabel = self.makeInfoLabel()
  
  //修正
  var items: [Video] = [] {
    didSet {
      if !items.isEmpty {
        gridView.collectionView.reloadData()
        
        items[0].fetchThumbnail(size: CGSize(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.width / 4)) { (image) in
          self.changeVideo(video: self.items[0], thumbnailImage: image, isDefaultVideo: true)
        }
      }
    }
  }
  
  let library = VideosLibrary()
  let once = Once()
  let cart: Cart
  
  // MARK: - Init
  
  public required init(cart: Cart) {
    self.cart = cart
    super.init(nibName: nil, bundle: nil)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Life cycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setup()
  }
  override func viewWillAppear(_ animated: Bool) {
    if #available(iOS 10.0, *) {
      do {
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      } catch {
        print("AVAudioSession catgery set error \(error)")
      }
    }
    
    self.gridView.addReachEndObserver()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    self.gridView.player?.pause()
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    self.gridView.removeReachEndObserver()
  }
  
  // MARK: - Setup
  
  func setup() {
    view.backgroundColor = UIColor.white
    
    view.addSubview(gridView)
    
    addChild(dropdownController)
    gridView.insertSubview(dropdownController.view, belowSubview: gridView.topView)
    dropdownController.didMove(toParent: self)
    
    gridView.g_pinEdges()
    gridView.dropDownController = dropdownController
    
    dropdownController.view.g_pin(on: .left)
    dropdownController.view.g_pin(on: .right)
    dropdownController.view.g_pin(on: .height, constant: -40) // subtract gridView.topView height
    
    dropdownController.expandedTopConstraint = dropdownController.view.g_pin(on: .top, view: gridView.topView, on: .bottom, constant: 1)
    dropdownController.expandedTopConstraint?.isActive = false
    dropdownController.collapsedTopConstraint = dropdownController.view.g_pin(on: .top, on: .bottom)
    
    [videoBox, infoLabel].forEach {
      gridView.bottomView.addSubview($0)
    }
    
    gridView.g_pinEdges()
    
    videoBox.g_pin(size: CGSize(width: 44, height: 44))
    videoBox.g_pin(on: .centerY)
    videoBox.g_pin(on: .left, constant: 38)
    
    infoLabel.g_pin(on: .centerY)
    infoLabel.g_pin(on: .left, view: videoBox, on: .right, constant: 11)
    infoLabel.g_pin(on: .right, constant: -50)
    
    gridView.closeButton.addTarget(self, action: #selector(closeButtonTouched(_:)), for: .touchUpInside)
    gridView.doneButton.addTarget(self, action: #selector(doneButtonTouched(_:)), for: .touchUpInside)
    
    gridView.collectionView.dataSource = self
    gridView.collectionView.delegate = self
    gridView.collectionView.register(VideoCell.self, forCellWithReuseIdentifier: String(describing: VideoCell.self))
    
    gridView.arrowButton.updateText("Gallery.AllVideos".g_localize(fallback: "ビデオ"))
    gridView.arrowButton.arrow.isHidden = true
  }
  
  func makeDropdownController() -> DropdownController {
    let controller = DropdownController()
    
    return controller
  }
  
  // MARK: - Action
  
  @objc func closeButtonTouched(_ button: UIButton) {
    EventHub.shared.close?()
  }
  
  @objc func doneButtonTouched(_ button: UIButton) {
    EventHub.shared.doneWithVideos?()
  }
  
  // MARK: - View
  
  func refreshView() {
    //修正
    let hasVideo = (cart.video != nil)
    if hasVideo {
      gridView.doneButton.isEnabled = true
    } else {
      gridView.doneButton.isEnabled = false
    }
    
    if let selectedItem = cart.video {
      videoBox.imageView.g_loadImage(selectedItem.asset)
    } else {
      videoBox.imageView.image = nil
    }
    
    //    let hasVideo = (cart.video != nil)
    //    gridView.bottomView.g_fade(visible: hasVideo)
    //    gridView.collectionView.g_updateBottomInset(hasVideo ? gridView.bottomView.frame.size.height : 0)
    
    cart.video?.fetchDuration { [weak self] duration in
      self?.infoLabel.isHidden = duration <= Config.VideoEditor.maximumDuration
    }
  }
  
  // MARK: - Controls
  
  func makeGridView() -> GridView {
    let view = GridView()
    view.bottomView.alpha = 0
    view.delegate = self
    
    return view
  }
  
  func makeVideoBox() -> VideoBox {
    let videoBox = VideoBox()
    videoBox.delegate = self
    
    return videoBox
  }
  
  func makeInfoLabel() -> UILabel {
    let label = UILabel()
    label.textColor = UIColor.white
    label.font = Config.Font.Text.regular.withSize(12)
    label.text = String(format: "Gallery.Videos.MaxiumDuration".g_localize(fallback: "FIRST %d SECONDS"),
                        (Int(Config.VideoEditor.maximumDuration)))
    
    return label
  }
  
  //修正
  func changeVideo(video: Video, thumbnailImage: UIImage? = nil, isDefaultVideo: Bool) {
    video.fetchAVAsset { (myAVAsset) in
      guard let asset = myAVAsset else { return }
      
      self.gridView.isDefaultVideo = isDefaultVideo
      self.gridView.thumnailImage = thumbnailImage
      self.gridView.videoPlayerItem = AVPlayerItem(asset: asset)
    }
  }
}

extension VideosController: PageAware {
  
  func pageDidShow() {
    once.run {
      library.reload {
        self.gridView.loadingIndicator.stopAnimating()
        self.items = self.library.items
        self.gridView.collectionView.reloadData()
        self.gridView.emptyView.isHidden = !self.items.isEmpty
      }
    }
  }
}

extension VideosController: VideoBoxDelegate {
  
  func videoBoxDidTap(_ videoBox: VideoBox) {
    cart.video?.fetchPlayerItem { item in
      guard let item = item else { return }
      
      DispatchQueue.main.async {
        let controller = AVPlayerViewController()
        let player = AVPlayer(playerItem: item)
        controller.player = player
        
        self.present(controller, animated: true) {
          player.play()
        }
      }
    }
  }
}

extension VideosController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
  
  // MARK: - UICollectionViewDataSource
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: VideoCell.self), for: indexPath)
      as! VideoCell
    let item = items[(indexPath as NSIndexPath).item]
    
    cell.configure(item)
    cell.frameView.label.isHidden = true
    configureFrameView(cell, indexPath: indexPath)
    
    return cell
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let size = (collectionView.bounds.size.width - (Config.Grid.Dimension.columnCount - 1) * Config.Grid.Dimension.cellSpacing)
      / Config.Grid.Dimension.columnCount
    return CGSize(width: size, height: size)
  }
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]
    
    if cart.images.isEmpty {
      if let selectedItem = cart.video , selectedItem == item {
        cart.video = nil
      } else {
        cart.video = item
      }
      
      configureFrameViews()
      //修正
      if let videoCell = collectionView.cellForItem(at: indexPath) as? VideoCell,
        let thumbnailImage = videoCell.imageView.image {
        
        changeVideo(video: item, thumbnailImage: thumbnailImage, isDefaultVideo: false)
      }
    }
    
    refreshView()
    gridView.panGestureHelper.resetToOriginalStateTappedCell(index: indexPath)
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    let cell = cell as! VideoCell
    
    configureFrameView(cell, indexPath: indexPath)
  }
  
  func configureFrameViews() {
    for case let cell as VideoCell in gridView.collectionView.visibleCells {
      if let indexPath = gridView.collectionView.indexPath(for: cell) {
        configureFrameView(cell, indexPath: indexPath)
      }
    }
  }
  
  func configureFrameView(_ cell: VideoCell, indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]
    
    if cart.images.isEmpty {
      if let selectedItem = cart.video, selectedItem == item {
        cell.frameView.g_quickFade()
      } else {
        cell.frameView.alpha = 0.0
      }
      
      cell.coverView.alpha = 0.0
    } else {
      cell.frameView.alpha = 0.0
      cell.coverView.alpha = 0.5
    }
  }
}

//MARK: GridViewDelegate
extension VideosController: GridViewDelegate {
  func previewImageDidScroll(offset: CGPoint) {
  }
  
  func previewImageDidZoom(scale: CGFloat) {
  }
  
  func previewVideoDidScroll(offset: CGPoint) {
    cart.video?.offset = offset
  }
  
  func previewVideoDidZoom(scale: CGFloat) {
    cart.video?.scale = scale
  }
}
