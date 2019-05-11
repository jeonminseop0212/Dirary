import UIKit
import Photos

class Album {
  
  let collection: PHAssetCollection
  var items: [Image] = []
  
  // MARK: - Initialization
  
  init(collection: PHAssetCollection) {
    self.collection = collection
  }
  
  func reload() {
    let itemsFetchResult = PHAsset.fetchAssets(in: collection, options: Utils.fetchOptions())
    
    if items.isEmpty {
      itemsFetchResult.enumerateObjects({ (asset, count, stop) in
        if asset.mediaType == .image {
          self.items.append(Image(asset: asset))
        }
      })
    } else {
      let asset = itemsFetchResult.object(at: 0)
      items.insert(Image(asset: asset), at: 0)
    }
  }
}
