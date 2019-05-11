//
//  myScrollView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/14.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

class ANIScrollView: UIScrollView {
  
  override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
    //srollviewの上に置いたtext viewのscrollをfalseにするとtextviewのtextを変えると自動的にこのメソッドが呼ばれておかしいスクロールをしてしまうのでここを殻にしておく
  }
}
