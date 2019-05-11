//
//  ANIImageBrowserView.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/18.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIImageBrowserCellDelegate {
  func viewBeginZooming()
  func viewDidZooming(scale: CGFloat)
  func cellTapped()
  func draggableDidPan()
  func changeAlpha(alpha: CGFloat)
}

class ANIImageBrowserCell: UICollectionViewCell {
  
  private weak var scrollView: UIScrollView?
  var draggableView: ANIDraggableView?
  
  var delegate: ANIImageBrowserCellDelegate?
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setup() {
    //basic
    self.backgroundColor = .clear
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tap))
    self.addGestureRecognizer(tapGesture)
    
    //scrollView
    let scrollView = UIScrollView()
    scrollView.minimumZoomScale = 1.0
    scrollView.maximumZoomScale = 6.0
    scrollView.delegate = self
    addSubview(scrollView)
    scrollView.edgesToSuperview()
    self.scrollView = scrollView
    
    //draggableView
    let draggableView = ANIDraggableView()
    draggableView.delegate = self
    scrollView.addSubview(draggableView)
    draggableView.edgesToSuperview()
    draggableView.size(to: scrollView)
    self.draggableView = draggableView
  }
  
  @objc private func tap() {
    self.delegate?.cellTapped()
  }
}

//MARK: UIScrollViewDelegate
extension ANIImageBrowserCell: UIScrollViewDelegate {
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    guard let draggableView = self.draggableView else { return UIView() }
    return draggableView
  }
  
  func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    self.delegate?.viewBeginZooming()
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    self.delegate?.viewDidZooming(scale: scrollView.zoomScale)
  }
  
  func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    guard let draggableView = self.draggableView else { return }
    
    draggableView.scollViewZoomScale = scrollView.zoomScale
  }
}

//MARK: DraggableViewDelegate
extension ANIImageBrowserCell: ANIDraggableViewDelegate {
  func panGestureDidChange(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint) {
    guard let draggableView = self.draggableView else { return }
    
    draggableView.frame.origin.y = translation.y
    
    if draggableView.center.y == originalCenter.y {
      self.delegate?.changeAlpha(alpha: 0.0)
    } else {
      let changeAlpha = (abs(self.bounds.height/2 - draggableView.center.y) / (self.bounds.height))
      self.delegate?.changeAlpha(alpha: changeAlpha)
    }
  }
  
  func panGestureDidEnd(_ panGesture: UIPanGestureRecognizer, originalCenter: CGPoint, translation: CGPoint) {
    guard let draggableView = self.draggableView else { return }
    
    if draggableView.center.y >= draggableView.bounds.height * 0.6 {
      UIView.animate(withDuration: 0.3, animations: {
        self.delegate?.changeAlpha(alpha: 1.0)

        draggableView.frame.origin.y = self.bounds.height
      }, completion: { (finished) in
        self.delegate?.draggableDidPan()
      })
    } else if draggableView.center.y <= draggableView.bounds.height * 0.3 {
      UIView.animate(withDuration: 0.3, animations: {
        self.delegate?.changeAlpha(alpha: 1.0)

        draggableView.frame.origin.y = self.bounds.origin.y - draggableView.frame.height
      }, completion: { (finished) in
        self.delegate?.draggableDidPan()
      })
    } else {
      UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.9, options: .curveEaseInOut, animations: {
        draggableView.center = originalCenter
        self.delegate?.changeAlpha(alpha: 0.0)
      }, completion: nil)
    }
  }
}
