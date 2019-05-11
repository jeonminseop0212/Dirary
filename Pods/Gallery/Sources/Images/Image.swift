import UIKit
import Photos

/// Wrap a PHAsset
public class Image: Equatable {
  
  public let asset: PHAsset
  
  //修正
  public var offset: CGPoint
  public var scale: CGFloat
  
  // MARK: - Initialization
  
  //修正
  init(asset: PHAsset, offset: CGPoint = CGPoint(x: 0.0, y: 0.0), scale: CGFloat = 1.0) {
    self.asset = asset
    self.offset = offset
    self.scale = scale
  }
}

// MARK: - UIImage

extension Image {
  
  /// Resolve UIImage synchronously
  ///
  /// - Parameter size: The target size
  /// - Returns: The resolved UIImage, otherwise nil
  public func resolve(completion: @escaping (UIImage?) -> Void) {
    let options = PHImageRequestOptions()
    options.isNetworkAccessAllowed = true
    options.deliveryMode = .highQualityFormat
    
//    let targetSize = CGSize(
//      width: asset.pixelWidth,
//      height: asset.pixelHeight
//    )
    
    PHImageManager.default().requestImage(
      for: asset,
      targetSize: PHImageManagerMaximumSize,
      contentMode: .default,
      options: options) { (image, _) in
        completion(image)
    }
  }
  
  /// Resolve an array of Image
  ///
  /// - Parameters:
  ///   - images: The array of Image
  ///   - size: The target size for all images
  ///   - completion: Called when operations completion
  public static func resolve(images: [Image], completion: @escaping ([UIImage?]) -> Void) {
    let dispatchGroup = DispatchGroup()
    var convertedImages = [Int: UIImage]()
    
    for (index, image) in images.enumerated() {
      dispatchGroup.enter()
      
      image.resolve(completion: { resolvedImage in
        if let resolvedImage = resolvedImage {
          convertedImages[index] = resolvedImage
        }
        
        dispatchGroup.leave()
      })
    }
    
    dispatchGroup.notify(queue: .main, execute: {
      let sortedImages = convertedImages
        .sorted(by: { $0.key < $1.key })
        .map({ $0.value })
      completion(sortedImages)
    })
  }
}

// MARK: - Equatable

public func == (lhs: Image, rhs: Image) -> Bool {
  return lhs.asset == rhs.asset
}
