//
//  ImageBrowserViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/18.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIImageBrowserViewControllerDelegate {
  func imageBrowserDidDissmiss()
}

class ANIImageBrowserViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var myNavigationBase: UIView?
  private weak var backButton: UIButton?
  private weak var navigationTitleLabel: UILabel?
  private var myNavigationBarOriginalAlpha: CGFloat = 1.0
  
  private weak var containerCollectionView: UICollectionView?
  
  var imageUrls = [String]()
  var selectedIndex = Int()
  
  var delegate: ANIImageBrowserViewControllerDelegate?

  override func viewDidLoad() {
    setup()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    openAnimation()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    UIApplication.shared.statusBar?.alpha = 1.0
  }
  
  private func setup() {
    //basic
    self.view.alpha = 0.0
    self.view.backgroundColor = .clear
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    UIApplication.shared.statusBarStyle = .lightContent
    
    //container
    let flowLayout = UICollectionViewFlowLayout()
    flowLayout.scrollDirection = .horizontal
    flowLayout.minimumLineSpacing = 0
    flowLayout.minimumInteritemSpacing = 0
    flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    let containerCollectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: flowLayout)
    containerCollectionView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    containerCollectionView.dataSource = self
    containerCollectionView.delegate = self
    containerCollectionView.showsHorizontalScrollIndicator = false
    containerCollectionView.isPagingEnabled = true
    containerCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
    let indexPath = IndexPath(item: selectedIndex, section: 0)
    containerCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .left)
    let id = NSStringFromClass(ANIImageBrowserCell.self)
    containerCollectionView.register(ANIImageBrowserCell.self, forCellWithReuseIdentifier: id)
    self.view.addSubview(containerCollectionView)
    containerCollectionView.edgesToSuperview()
    self.containerCollectionView = containerCollectionView
    
    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview()
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.STATUS_BAR_HEIGHT + UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //myNavigationBase
    let myNavigationBase = UIView()
    myNavigationBar.addSubview(myNavigationBase)
    myNavigationBase.edgesToSuperview(excluding: .top)
    myNavigationBase.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBase = myNavigationBase
    
    //backButton
    let backButton = UIButton()
    let backButtonImage = UIImage(named: "dismissButton")?.withRenderingMode(.alwaysTemplate)
    backButton.setImage(backButtonImage, for: .normal)
    backButton.tintColor = .white
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBase.addSubview(backButton)
    backButton.width(44.0)
    backButton.height(44.0)
    backButton.leftToSuperview()
    backButton.centerYToSuperview()
    self.backButton = backButton
    
    //navigationTitleLabel
    let navigationTitleLabel = UILabel()
    navigationTitleLabel.text = "\(selectedIndex + 1)/\(imageUrls.count)"
    navigationTitleLabel.textColor = .white
    navigationTitleLabel.font = UIFont.boldSystemFont(ofSize: 17)
    myNavigationBase.addSubview(navigationTitleLabel)
    navigationTitleLabel.centerInSuperview()
    self.navigationTitleLabel = navigationTitleLabel
  }
  
  private func openAnimation() {
    UIView.animate(withDuration: 0.2, animations: {
      self.view.alpha = 1.0
    })
  }
  
  private func showNavigationBar() {
    guard let myNavigationBar = self.myNavigationBar,
          let statusBar = UIApplication.shared.statusBar else { return }
    
    UIView.animate(withDuration: 0.3, animations: {
      myNavigationBar.alpha = 1.0
      statusBar.alpha = 1.0
    })
    
    myNavigationBarOriginalAlpha = myNavigationBar.alpha
  }
  
  private func hideNavigationBar() {
    guard let myNavigationBar = self.myNavigationBar,
          let statusBar = UIApplication.shared.statusBar else { return }

    UIView.animate(withDuration: 0.3, animations: {
      myNavigationBar.alpha = 0.0
      statusBar.alpha = 0.0
    })
    
    myNavigationBarOriginalAlpha = myNavigationBar.alpha
  }
  
  //MARK: Action
  @objc private func back() {
    UIView.animate(withDuration: 0.2, animations: {
      self.view.alpha = 0.0
    }) { (complete) in
      self.dismiss(animated: false, completion: nil)
      self.delegate?.imageBrowserDidDissmiss()
    }
  }
}

//MARK: UICollectionViewDataSource
extension ANIImageBrowserViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return imageUrls.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let id = NSStringFromClass(ANIImageBrowserCell.self)
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ANIImageBrowserCell
    cell.draggableView?.imageView?.sd_setImage(with: URL(string: imageUrls[indexPath.item]), completed: nil)
    cell.delegate = self
    return cell
  }
}

//MARK: UICollectionViewDelegateFlowLayout
extension ANIImageBrowserViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let size = CGSize(width: self.view.frame.width, height: self.view.frame.height)
    return size
  }
}

//MARK: UICollectionViewDelegate
extension ANIImageBrowserViewController: UICollectionViewDelegate {
  func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    guard let navigationTitleLabel = self.navigationTitleLabel else { return }
    
    let indexPath = IndexPath(item: Int(targetContentOffset.pointee.x / view.frame.width), section: 0)
    navigationTitleLabel.text = "\(indexPath.item + 1)/\(imageUrls.count)"
  }
}

//MARK: ANIImageBrowserCellDelegate
extension ANIImageBrowserViewController: ANIImageBrowserCellDelegate {
  func viewBeginZooming() {
    hideNavigationBar()
  }
  
  func viewDidZooming(scale: CGFloat) {
    guard let containerCollectionView = self.containerCollectionView else { return }
    
    if scale == 1.0 {
      showNavigationBar()
      containerCollectionView.isScrollEnabled = true
    } else {
      containerCollectionView.isScrollEnabled = false
    }
  }
  
  func cellTapped() {
    guard let myNavigationBar = self.myNavigationBar else { return }
    
    if myNavigationBar.alpha == 1.0 {
      hideNavigationBar()
    } else {
      showNavigationBar()
    }
  }
  
  func draggableDidPan() {
    guard let containerCollectionView = self.containerCollectionView,
          let myNavigationBar = self.myNavigationBar else { return }
    
    self.dismiss(animated: false, completion: nil)
    self.delegate?.imageBrowserDidDissmiss()
    
    UIView.animate(withDuration: 0.3) {
      containerCollectionView.backgroundColor =  UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
      myNavigationBar.alpha = 0.0
    }
  }
  
  func changeAlpha(alpha: CGFloat) {
    guard let containerCollectionView = self.containerCollectionView,
          let myNavigationBar = self.myNavigationBar else { return }
    
    containerCollectionView.backgroundColor =  UIColor(red: 0, green: 0, blue: 0, alpha: 1.0 - alpha)
    
    if alpha != 0.0 {
      UIView.animate(withDuration: 0.3) {
        myNavigationBar.alpha = 0.0
      }
    } else {
      UIView.animate(withDuration: 0.3) {
        myNavigationBar.alpha = self.myNavigationBarOriginalAlpha
      }
    }
  }
}
