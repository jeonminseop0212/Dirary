//
//  MQImageFilterViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/05/11.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit

protocol ANIImageFilterViewControllerDelegate {
  func doneFilterImages(filteredImages: [UIImage?])
}

class ANIImageFilterViewController: UIViewController {
  
  private weak var myNavigationBar: UIView?
  private weak var backButton: UIButton?
  private weak var titleLbl: UILabel?
  private weak var doneButton: UIButton?
  
  private weak var previewView: ANIImageFilterPreviewView?
  
  private weak var filterViewBG: UIView?
  private weak var filterView: ANIImageFilterView?
  
  var images = [UIImage?]()
  
  var delegate: ANIImageFilterViewControllerDelegate?
  
  override func viewDidLoad() {
    setup()
  }
  
  private func setup() {
    //basic
    self.view.backgroundColor = .white
    self.navigationController?.setNavigationBarHidden(true, animated: false)
    self.navigationController?.navigationBar.isTranslucent = false
    self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    UIApplication.shared.isStatusBarHidden = true

    //myNavigationBar
    let myNavigationBar = UIView()
    myNavigationBar.backgroundColor = .white
    self.view.addSubview(myNavigationBar)
    myNavigationBar.topToSuperview(usingSafeArea: true)
    myNavigationBar.leftToSuperview()
    myNavigationBar.rightToSuperview()
    myNavigationBar.height(UIViewController.NAVIGATION_BAR_HEIGHT)
    self.myNavigationBar = myNavigationBar
    
    //backButton
    let backButton = UIButton()
    let backButtonImage = UIImage(named: "backButton")?.withRenderingMode(.alwaysTemplate)
    backButton.setImage(backButtonImage, for: .normal)
    backButton.tintColor = ANIColor.dark
    backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
    myNavigationBar.addSubview(backButton)
    backButton.width(44.0)
    backButton.height(44.0)
    backButton.leftToSuperview()
    backButton.centerYToSuperview()
    self.backButton = backButton
    
    //titleLbl
    let titleLbl = UILabel()
    titleLbl.text = "フィルター"
    titleLbl.font = UIFont.boldSystemFont(ofSize: 17)
    titleLbl.textColor = ANIColor.dark
    myNavigationBar.addSubview(titleLbl)
    titleLbl.centerInSuperview()
    self.titleLbl = titleLbl
    
    //donButton
    let doneButton = UIButton()
    doneButton.setTitle("完了", for: .normal)
    doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    doneButton.setTitleColor(ANIColor.emerald, for: .normal)
    doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)
    myNavigationBar.addSubview(doneButton)
    doneButton.width(60.0)
    doneButton.height(44.0)
    doneButton.centerYToSuperview()
    doneButton.rightToSuperview()
    self.doneButton = doneButton
    
    //priviewView
    let previewView = ANIImageFilterPreviewView()
    previewView.images = images
    previewView.delegate = self
    self.view.addSubview(previewView)
    previewView.topToBottom(of: myNavigationBar)
    previewView.leftToSuperview()
    previewView.rightToSuperview()
    self.previewView = previewView
    
    //filterViewBG
    let filterViewBG = UIView()
    self.view.addSubview(filterViewBG)
    filterViewBG.topToBottom(of: previewView)
    filterViewBG.leftToSuperview()
    filterViewBG.rightToSuperview()
    filterViewBG.bottomToSuperview()
    self.filterViewBG = filterViewBG
    
    //filterView
    let filterView = ANIImageFilterView()
    filterView.delegate = self
    filterViewBG.addSubview(filterView)
    filterView.centerYToSuperview()
    filterView.leftToSuperview()
    filterView.rightToSuperview()
    filterView.height(180)
    self.filterView = filterView
  }
  
  //MARK: Action
  @objc private func back() {
    self.navigationController?.popViewController(animated: true)
  }
  
  @objc private func done() {
    guard let previewView = self.previewView else { return }
    self.delegate?.doneFilterImages(filteredImages: previewView.filteredImages)
    self.navigationController?.dismiss(animated: true, completion: nil)
  }
}

//MAKR: ANIImageFilterViewDelegate
extension ANIImageFilterViewController: ANIImageFilterViewDelegate {
  func selectedFilter(filter: ANIFilter, selectedFilterIndex: Int) {
    guard let previewView = self.previewView else { return }
    previewView.selectedFilterIndex = selectedFilterIndex
    previewView.filter = filter
  }
}

//MARK: ANIImageFilterPreviewViewDelegate
extension ANIImageFilterViewController: ANIImageFilterPreviewViewDelegate {
  func selectedPreviewItem(selectedFilterIndex: Int) {
    guard let filterView = self.filterView else { return }
    filterView.selectedItemFilterIndex = selectedFilterIndex
  }
}

//MARK: UIGestureRecognizerDelegate
extension ANIImageFilterViewController: UIGestureRecognizerDelegate {
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
