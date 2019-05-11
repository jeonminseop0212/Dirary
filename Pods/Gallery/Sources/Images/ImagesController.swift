import UIKit
import Photos

class ImagesController: UIViewController {
  
  lazy var dropdownController: DropdownController = self.makeDropdownController()
  lazy var gridView: GridView = self.makeGridView()
  lazy var stackView: StackView = self.makeStackView()
  
  var items: [Image] = [] {
    didSet {
      if !items.isEmpty {
        changeImage(items[0])
      }
    }
  }
  
  let library = ImagesLibrary()
  var selectedAlbum: Album?
  let once = Once()
  let cart: Cart
  
  private var selectedItemIndex: Int?
  private var selectedItem: Image?
  
  // MARK: - Init
  
  public required init(cart: Cart) {
    self.cart = cart
    super.init(nibName: nil, bundle: nil)
    cart.delegates.add(self)
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
    gridView.collectionView.reloadData()
  }

  // MARK: - Setup
  
  func setup() {
    view.backgroundColor = UIColor.white
    
    view.addSubview(gridView)
    
    addChild(dropdownController)
    gridView.insertSubview(dropdownController.view, belowSubview: gridView.topView)
    dropdownController.didMove(toParent: self)
    
    gridView.bottomView.addSubview(stackView)
    gridView.g_pinEdges()
    gridView.dropDownController = dropdownController
    
    dropdownController.view.g_pin(on: .left)
    dropdownController.view.g_pin(on: .right)
    dropdownController.view.g_pin(on: .height, constant: -40) // subtract gridView.topView height
    
    dropdownController.expandedTopConstraint = dropdownController.view.g_pin(on: .top, view: gridView.topView, on: .bottom, constant: 1)
    dropdownController.expandedTopConstraint?.isActive = false
    dropdownController.collapsedTopConstraint = dropdownController.view.g_pin(on: .top, on: .bottom)
    
    stackView.g_pin(on: .centerY, constant: -4)
    stackView.g_pin(on: .left, constant: 38)
    stackView.g_pin(size: CGSize(width: 56, height: 56))
    
    gridView.closeButton.addTarget(self, action: #selector(closeButtonTouched(_:)), for: .touchUpInside)
    gridView.doneButton.addTarget(self, action: #selector(doneButtonTouched(_:)), for: .touchUpInside)
    gridView.arrowButton.addTarget(self, action: #selector(arrowButtonTouched(_:)), for: .touchUpInside)
    stackView.addTarget(self, action: #selector(stackViewTouched(_:)), for: .touchUpInside)
    
    gridView.collectionView.dataSource = self
    gridView.collectionView.delegate = self
    gridView.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: String(describing: ImageCell.self))
    
    //修正
    gridView.videoPreviewView.isHidden = true
  }
  
  // MARK: - Action
  
  @objc func closeButtonTouched(_ button: UIButton) {
    EventHub.shared.close?()
  }
  
  @objc func doneButtonTouched(_ button: UIButton) {
    EventHub.shared.doneWithImages?()
  }
  
  @objc func arrowButtonTouched(_ button: ArrowButton) {
    dropdownController.toggle()
    button.toggle(dropdownController.expanding)
  }
  
  @objc func stackViewTouched(_ stackView: StackView) {
    EventHub.shared.stackViewTouched?()
  }
  
  // MARK: - Logic
  
  func show(album: Album) {
    gridView.arrowButton.updateText(album.collection.localizedTitle ?? "")
    items = album.items
    gridView.collectionView.reloadData()
    gridView.collectionView.g_scrollToTop()
    gridView.emptyView.isHidden = !items.isEmpty
  }
  
  func refreshSelectedAlbum() {
    if let selectedAlbum = selectedAlbum {
      selectedAlbum.reload()
      show(album: selectedAlbum)
    }
  }
  
  // MARK: - View
  
  func refreshView() {
    let hasImages = !cart.images.isEmpty
    //修正
    if hasImages {
      gridView.doneButton.isEnabled = true
    } else {
      gridView.doneButton.isEnabled = false
    }
  }
  
  //修正
  func changeImage(_ image: Image) {
    ImageManager.fetchImage(viaAsset: image.asset) { (image) -> Void in
      if let imageUnrap = image {
        self.gridView.isSelectedImage = false
        self.gridView.image = imageUnrap
      }
    }
  }
  
  //修正
  func changeSelectedImage(_ selectedImage: Image) {
    ImageManager.fetchImage(viaAsset: selectedImage.asset) { (image) -> Void in
      if let imageUnrap = image {
        self.gridView.isSelectedImage = true
        self.gridView.squaredZoomScale = selectedImage.scale
        self.gridView.offset = selectedImage.offset
        self.gridView.selectedImage = imageUnrap
      }
    }
  }
  
  // MARK: - Controls
  
  func makeDropdownController() -> DropdownController {
    let controller = DropdownController()
    controller.delegate = self
    
    return controller
  }
  
  func makeGridView() -> GridView {
    let view = GridView()
    view.bottomView.alpha = 0
    view.delegate = self
    
    return view
  }
  
  func makeStackView() -> StackView {
    let view = StackView()
    
    return view
  }
}

extension ImagesController: PageAware {
  
  func pageDidShow() {
    once.run {
      library.reload {
        self.gridView.loadingIndicator.stopAnimating()
        self.dropdownController.albums = self.library.albums
        self.dropdownController.tableView.reloadData()
        
        if let album = self.library.albums.first {
          self.selectedAlbum = album
          self.show(album: album)
        }
      }
    }
  }
}

extension ImagesController: CartDelegate {
  
  func cart(_ cart: Cart, didAdd image: Image, newlyTaken: Bool) {
    stackView.reload(cart.images, added: true)
    refreshView()
    
    if newlyTaken {
      refreshSelectedAlbum()
      selectedItem = image
      changeImage(image)
      selectedItemIndex = 0
    }
  }
  
  func cart(_ cart: Cart, didRemove image: Image) {
    stackView.reload(cart.images)
    refreshView()
  }
  
  func cartDidReload(_ cart: Cart) {
    stackView.reload(cart.images)
    refreshView()
    refreshSelectedAlbum()
  }
}

extension ImagesController: DropdownControllerDelegate {
  
  func dropdownController(_ controller: DropdownController, didSelect album: Album) {
    selectedAlbum = album
    show(album: album)
    
    dropdownController.toggle()
    gridView.arrowButton.toggle(controller.expanding)
  }
}

extension ImagesController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
  
  // MARK: - UICollectionViewDataSource
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ImageCell.self), for: indexPath)
      as! ImageCell
    let item = items[(indexPath as NSIndexPath).item]
    
    cell.configure(item)
    configureFrameView(cell, indexPath: indexPath)
    
    return cell
  }
  
  // MARK: - UICollectionViewDelegateFlowLayout
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    
    let size = (collectionView.bounds.size.width - (Config.Grid.Dimension.columnCount - 1) * Config.Grid.Dimension.cellSpacing)
      / Config.Grid.Dimension.columnCount
    return CGSize(width: size, height: size)
  }
  
  //修正
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]
    selectedItem = item
    
    if cart.video == nil {
      if Config.Camera.oneImageMode {
        if !cart.images.contains(item) {
          cart.images.removeAll()
          
          cart.add(item)
          
          changeImage(item)
        }
      } else {
        if cart.images.contains(item) {
          if selectedItemIndex == indexPath.item {
            cart.remove(item)
          }
          selectedItemIndex = indexPath.item
          
          for image in cart.images {
            if image == item {
              changeSelectedImage(image)
            }
          }
        } else {
          if Config.Camera.imageLimit == 0 || Config.Camera.imageLimit > cart.images.count{
            cart.add(item)
            
            changeImage(item)
          }
          
          selectedItemIndex = indexPath.item
        }
      }
      
      //    gridView.panGestureHelper.resetToOriginalState()
      gridView.panGestureHelper.resetToOriginalStateTappedCell(index: indexPath)
      
      configureFrameViews()
    } else {
      changeImage(item)
      
      gridView.panGestureHelper.resetToOriginalStateTappedCell(index: indexPath)
    }
  }
  
  func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    let cell = cell as! ImageCell
    
    configureFrameView(cell, indexPath: indexPath)
  }
  
  func configureFrameViews() {
    for case let cell as ImageCell in gridView.collectionView.visibleCells {
      if let indexPath = gridView.collectionView.indexPath(for: cell) {
        configureFrameView(cell, indexPath: indexPath)
      }
    }
  }
  
  func configureFrameView(_ cell: ImageCell, indexPath: IndexPath) {
    let item = items[(indexPath as NSIndexPath).item]
    
    if cart.video == nil {
      if let index = cart.images.index(of: item) {
        cell.frameView.g_quickFade()
        if !Config.Camera.oneImageMode {
          cell.frameView.label.text = "\(index + 1)"
          cell.coverView.alpha = 0.0
        }
      } else {
        cell.coverView.alpha = 0.0
        cell.frameView.alpha = 0.0
      }
      
      if !Config.Camera.oneImageMode && Config.Camera.imageLimit <= cart.images.count && !cart.images.contains(item) {
        cell.coverView.alpha = 0.5
      } else {
        cell.coverView.alpha = 0.0
      }
    } else {
      cell.frameView.alpha = 0.0
      cell.coverView.alpha = 0.5
    }
  }
}

class ImageManager: NSObject {
  @discardableResult
  class func fetchImage(viaAsset asset: PHAsset?, targetSize: CGSize, imageResultHandler: @escaping (_ image: UIImage?)->Void) -> PHImageRequestID? {
    guard asset != nil else {
      return nil
    }
    let options = PHImageRequestOptions()
    options.resizeMode = PHImageRequestOptionsResizeMode.exact
    let scale = UIScreen.main.scale
    let size = CGSize(width: targetSize.width * scale, height: targetSize.height * scale)
    return PHCachingImageManager.default().requestImage(for: asset!,
                                                        targetSize: size,
                                                        contentMode: .aspectFill,
                                                        options: options) {
                                                          (result, info) -> Void in
                                                          imageResultHandler(result)
    }
  }
  @discardableResult
  class func fetchImage(viaAsset asset: PHAsset?, imageResultHandler: @escaping (_ image: UIImage?)->Void) -> PHImageRequestID? {
    guard asset != nil else {
      return nil
    }
    let options = PHImageRequestOptions()
    options.resizeMode = PHImageRequestOptionsResizeMode.exact
    return PHCachingImageManager.default().requestImage(for: asset!,
                                                        targetSize: PHImageManagerMaximumSize,
                                                        contentMode: .aspectFill,
                                                        options: options) {
                                                          (result, info) -> Void in
                                                          imageResultHandler(result)
    }
  }
}

//修正
extension ImagesController: GridViewDelegate {
  func previewImageDidScroll(offset: CGPoint) {
    for (index, item) in cart.images.enumerated() {
      if item == selectedItem {
        cart.images[index].offset = offset
      }
    }
  }
  
  func previewImageDidZoom(scale: CGFloat) {
    for (index, item) in cart.images.enumerated() {
      if item == selectedItem {
        cart.images[index].scale = scale
      }
    }
  }
  
  func previewVideoDidScroll(offset: CGPoint) {
  }
  
  func previewVideoDidZoom(scale: CGFloat) {
  }
}
