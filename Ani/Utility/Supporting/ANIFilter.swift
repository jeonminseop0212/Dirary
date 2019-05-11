//
//  ANIFilter.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/12.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import CoreImage

private var filterSharedContext: CIContext!

struct ANIFilter {
  
  var name = ""
  
  init(_ name: String) {
    self.name = name
  }
  
  func filter(_ image: UIImage) -> UIImage {
    if name == "" {
      return image
    }
    let context = getFilterSharedContext()
    let ciImage = CIImage(image: image)
    if let filter = CIFilter(name: name) {
      filter.setValue(ciImage, forKey: kCIInputImageKey)
      if let outputImage = filter.outputImage,
        let cgImg = context.createCGImage(outputImage, from: outputImage.extent) {
        return UIImage(cgImage: cgImg, scale: image.scale, orientation: image.imageOrientation)
      } else {
        return UIImage()
      }
    }
    return UIImage()
  }
  
  private func getFilterSharedContext() -> CIContext {
    if filterSharedContext == nil {
      if let context = EAGLContext(api: .openGLES2) {
        filterSharedContext = CIContext(eaglContext: context)
      }
      return filterSharedContext
    } else {
      return filterSharedContext
    }
  }
}
