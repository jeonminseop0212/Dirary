//
//  UIIMage.swift
//  Ani
//
//  Created by jeonminseop on 2018/07/04.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

extension UIImage {
  func resize(size _size: CGSize) -> UIImage? {
    let widthRatio = _size.width / size.width
    let heightRatio = _size.height / size.height
    let ratio = widthRatio < heightRatio ? widthRatio : heightRatio
    
    let resizedSize = CGSize(width: size.width * ratio, height: size.height * ratio)
    
    UIGraphicsBeginImageContextWithOptions(resizedSize, false, 0.0)
    draw(in: CGRect(origin: .zero, size: resizedSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return resizedImage
  }
}
