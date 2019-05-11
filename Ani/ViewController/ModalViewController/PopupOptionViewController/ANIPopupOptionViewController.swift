//
//  PopupOptionViewController.swift
//  Ani
//
//  Created by jeonminseop on 2018/07/26.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints

protocol ANIPopupOptionViewControllerDelegate {
  func deleteContribution()
  func reportContribution()
  func optionTapped(index: Int)
}

class ANIPopupOptionViewController: UIViewController {
  
  private weak var backgroundView: UIView?
  
  private var popupOptionViewTopConstraintConstant: CGFloat?
  private weak var popupOptionViewTopConstratint: Constraint?
  private weak var popupOptionView: ANIPopupOptionView?
  
  var isMe: Bool?
  
  var options: [String]?
  
  var delegate: ANIPopupOptionViewControllerDelegate?
  
  enum OptionKind {
    case delete;
    case report;
  }
  
  override func viewDidLoad() {
    setup()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    optionViewPop()
  }
  
  private func setup() {
    //basic
    self.view.backgroundColor = .clear
    
    //backgroundView
    let backgroundView = UIView()
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
    backgroundView.addGestureRecognizer(tapGestureRecognizer)
    self.view.addSubview(backgroundView)
    backgroundView.edgesToSuperview()
    self.backgroundView = backgroundView
    
    //popupOptionView
    let popupOptionView = ANIPopupOptionView()
    if let isMe = isMe {
      popupOptionView.isMe = isMe
    }
    if let options = options {
      popupOptionView.options = options
    }
    popupOptionView.delegate = self
    self.view.addSubview(popupOptionView)
    popupOptionViewTopConstratint = popupOptionView.topToBottom(of: self.view)
    popupOptionViewTopConstraintConstant = popupOptionViewTopConstratint?.constant
    popupOptionView.leftToSuperview(offset: 10.0)
    popupOptionView.rightToSuperview(offset: -10.0)
    self.popupOptionView = popupOptionView
  }
  
  private func optionViewPop() {
    guard let backgroundView = self.backgroundView,
          let popupOptionViewTopConstratint = self.popupOptionViewTopConstratint,
          let window = UIApplication.shared.keyWindow,
          let popupOptionView = self.popupOptionView else { return }
    
    let bottomSafeArea = window.safeAreaInsets.bottom
    let bottomMargin: CGFloat = 10.0
    popupOptionViewTopConstratint.constant = -(popupOptionView.frame.height + bottomSafeArea + bottomMargin)
    
    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
      backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
      self.view.layoutIfNeeded()
    }, completion: nil)
  }
  
  private func optionViewDismiss(optionKind: OptionKind? = nil, optionIndex: Int? = nil) {
    guard let backgroundView = self.backgroundView,
          let popupOptionViewTopConstratint = self.popupOptionViewTopConstratint,
          let popupOptionViewTopConstraintConstant = self.popupOptionViewTopConstraintConstant else { return }
    
    popupOptionViewTopConstratint.constant = popupOptionViewTopConstraintConstant
    
    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
      backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
      self.view.layoutIfNeeded()
    }, completion: { (complete) in
      self.dismiss(animated: false, completion: {
        if let optionKind = optionKind {
          if optionKind == .delete {
            self.delegate?.deleteContribution()
          } else if optionKind == .report {
            self.delegate?.reportContribution()
          }
        }
        
        if let optionIndex = optionIndex {
          self.delegate?.optionTapped(index: optionIndex)
        }
      })
    })
  }
  
  @objc private func viewTapped() {
    optionViewDismiss()
  }
}

//MARK: ANIPopupOptionViewDelegate
extension ANIPopupOptionViewController: ANIPopupOptionViewDelegate {
  func cancelButtonTapped() {
    optionViewDismiss()
  }
  
  func deleteContribution() {
    optionViewDismiss(optionKind: .delete)
  }
  
  func reportContribution() {
    optionViewDismiss(optionKind: .report)
  }
  
  func optionTapped(index: Int) {
    optionViewDismiss(optionIndex: index)
  }
}
