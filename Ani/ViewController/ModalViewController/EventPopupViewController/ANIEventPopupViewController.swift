//
//  ANIEventPopupViewController.swift
//  Ani
//
//  Created by jeonminseop on 2019/01/29.
//  Copyright © 2019 JeonMinseop. All rights reserved.
//

import UIKit
import TinyConstraints
import SafariServices

class ANIEventPopupViewController: UIViewController {
  
  private weak var backgroundView: UIView?
  
  private weak var eventCenterYConstratint: Constraint?
  private var originalCenterYConstant: CGFloat?
  private weak var eventPopupView: ANIEventPopupView?
  
  var event: FirebaseEvent?
  
  override func viewDidLoad() {
    setup()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    eventViewPop()
  }
  
  override func viewDidLayoutSubviews() {
    guard let eventPopupView = self.eventPopupView else { return }

    if originalCenterYConstant == nil {
      originalCenterYConstant = UIScreen.main.bounds.height / 2 + eventPopupView.frame.height / 2
      if let originalCenterY = self.originalCenterYConstant {
        eventCenterYConstratint = eventPopupView.centerYToSuperview(offset: originalCenterY)
      }
    }
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
    
    //eventPopupView
    let eventPopupView = ANIEventPopupView()
    eventPopupView.layer.cornerRadius = 10.0
    eventPopupView.layer.masksToBounds = true
    eventPopupView.delegate = self
    if let event = self.event {
      eventPopupView.event = event
    }
    self.view.addSubview(eventPopupView)
    eventPopupView.leftToSuperview(offset: 30.0)
    eventPopupView.rightToSuperview(offset: -30.0)
    self.eventPopupView = eventPopupView
  }
  
  private func eventViewPop() {
    guard let backgroundView = self.backgroundView,
          let eventCenterYConstratint = self.eventCenterYConstratint else { return }

    eventCenterYConstratint.constant = 0.0

    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
      backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
      self.view.layoutIfNeeded()
    }, completion: nil)
  }

  private func eventViewDismiss() {
    guard let backgroundView = self.backgroundView,
          let eventCenterYConstratint = self.eventCenterYConstratint,
          let originalCenterYConstant = self.originalCenterYConstant else { return }

    eventCenterYConstratint.constant = originalCenterYConstant

    UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut, animations: {
      backgroundView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.0)
      self.view.layoutIfNeeded()
    }, completion: { (complete) in
      self.dismiss(animated: false, completion: nil)
    })
  }
  
  @objc private func viewTapped() {
    eventViewDismiss()
  }
}

//MARK: ANIEventPopupViewDelegate
extension ANIEventPopupViewController: ANIEventPopupViewDelegate {
  func showDetail() {
    guard let event = self.event,
          let detailUrl = event.detailUrl else { return }
    
    guard let url = URL(string: detailUrl) else { return }
    
    let safariVC = SFSafariViewController(url: url)
    present(safariVC, animated: true, completion: nil)
  }
}
