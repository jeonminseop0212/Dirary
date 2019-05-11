//
//  ANIfunction.swift
//  Ani
//
//  Created by jeonminseop on 2018/06/25.
//  Copyright © 2018年 JeonMinseop. All rights reserved.
//

import UIKit
import StoreKit

class ANIFunction: NSObject {
  static let shared = ANIFunction()

  func getToday(format:String = "yyyy/MM/dd HH:mm:ss.SSS") -> String {
    let now = Date()
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = format
    return formatter.string(from: now as Date)
  }
  
  func dateFromString(string: String, format: String = "yyyy/MM/dd HH:mm:ss.SSS") -> Date {
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = format
    if let date = formatter.date(from: string) {
      return date
    } else {
      return Date()
    }
  }
  
  func getCurrentLocaleDateFromString(string: String, format: String = "yyyy/MM/dd HH:mm:ss.SSS") -> String {
    let date = dateFromString(string: string)
    let currentformatter = DateFormatter()
    currentformatter.timeZone = TimeZone.current
    currentformatter.locale = Locale.current
    currentformatter.dateFormat = format
    return currentformatter.string(from: date)
  }
  
  func webURLScheme(urlString: String) -> String {
    guard urlString.count > 0 else { return "" }
    
    let castUrlString = urlString.lowercased()
    if castUrlString.hasPrefix("http://") || castUrlString.hasPrefix("https://") {
      return castUrlString
    } else {
      return "https://" + castUrlString
    }
  }
  
  //MARK: review
  func showReviewAlertOpenApp() {
    guard let showReviewConditions = ANISessionManager.shared.showReviewConditions,
          let openApp = showReviewConditions[KEY_REVIEW_OPEN_APP] else { return }
    
    let reviewOpenApp = UserDefaults.standard.double(forKey: KEY_REVIEW_OPEN_APP)
    var reviewOpenAppMultiply = UserDefaults.standard.double(forKey: KEY_REVIEW_OPEN_APP_MULTIPLY)
    if reviewOpenAppMultiply == 0 {
      reviewOpenAppMultiply = 1
      UserDefaults.standard.set(reviewOpenAppMultiply, forKey: KEY_REVIEW_OPEN_APP_MULTIPLY)
    }
    
    if reviewOpenApp >= Double(openApp) {
      SKStoreReviewController.requestReview()
      
      var newMultiply = reviewOpenAppMultiply
      if reviewOpenAppMultiply == 1 {
        newMultiply = 0.5
      } else if reviewOpenAppMultiply == 0.5 {
        newMultiply = 0.3
      }
      UserDefaults.standard.set(newMultiply, forKey: KEY_REVIEW_OPEN_APP_MULTIPLY)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_OPEN_APP)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_LOVE)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_COMMENT)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_CONTRIBUTION)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_FOLLOW)
    } else {
      UserDefaults.standard.set(reviewOpenApp + (1 * reviewOpenAppMultiply), forKey: KEY_REVIEW_OPEN_APP)
    }
  }
  
  func showReviewAlertLove() {
    guard let showReviewConditions = ANISessionManager.shared.showReviewConditions,
          let love = showReviewConditions[KEY_REVIEW_LOVE] else { return }
    
    let reviewLove = UserDefaults.standard.double(forKey: KEY_REVIEW_LOVE)
    var reviewLoveMultiply = UserDefaults.standard.double(forKey: KEY_REVIEW_LOVE_MULTIPLY)
    if reviewLoveMultiply == 0 {
      reviewLoveMultiply = 1
      UserDefaults.standard.set(reviewLoveMultiply, forKey: KEY_REVIEW_LOVE_MULTIPLY)
    }
    
    if reviewLove >= Double(love) {
      SKStoreReviewController.requestReview()
      
      var newMultiply = reviewLoveMultiply
      if reviewLoveMultiply == 1 {
        newMultiply = 0.5
      } else if reviewLoveMultiply == 0.5 {
        newMultiply = 0.3
      }
      UserDefaults.standard.set(newMultiply, forKey: KEY_REVIEW_LOVE_MULTIPLY)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_OPEN_APP)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_LOVE)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_COMMENT)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_CONTRIBUTION)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_FOLLOW)
    } else {
      UserDefaults.standard.set(reviewLove + (1 * reviewLoveMultiply), forKey: KEY_REVIEW_LOVE)
    }
  }
  
  func showReviewAlertComment() {
    guard let showReviewConditions = ANISessionManager.shared.showReviewConditions,
          let comment = showReviewConditions[KEY_REVIEW_COMMENT] else { return }
    
    let reviewComment = UserDefaults.standard.double(forKey: KEY_REVIEW_COMMENT)
    var reviewCommentMultiply = UserDefaults.standard.double(forKey: KEY_REVIEW_COMMENT_MULTIPLY)
    if reviewCommentMultiply == 0 {
      reviewCommentMultiply = 1
      UserDefaults.standard.set(reviewCommentMultiply, forKey: KEY_REVIEW_COMMENT_MULTIPLY)
    }
    
    if reviewComment >= Double(comment) {
      SKStoreReviewController.requestReview()
      
      var newMultiply = reviewCommentMultiply
      if reviewCommentMultiply == 1 {
        newMultiply = 0.5
      } else if reviewCommentMultiply == 0.5 {
        newMultiply = 0.3
      }
      UserDefaults.standard.set(newMultiply, forKey: KEY_REVIEW_COMMENT_MULTIPLY)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_OPEN_APP)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_LOVE)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_COMMENT)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_CONTRIBUTION)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_FOLLOW)
    } else {
      UserDefaults.standard.set(reviewComment + (1 * reviewCommentMultiply), forKey: KEY_REVIEW_COMMENT)
    }
  }
  
  func showReviewAlertContribution() {
    guard let showReviewConditions = ANISessionManager.shared.showReviewConditions,
          let contribution = showReviewConditions[KEY_REVIEW_CONTRIBUTION] else { return }
    
    let reviewContribution = UserDefaults.standard.double(forKey: KEY_REVIEW_CONTRIBUTION)
    var reviewContributionMultiply = UserDefaults.standard.double(forKey: KEY_REVIEW_CONTRIBUTION_MULTIPLY)
    if reviewContributionMultiply == 0 {
      reviewContributionMultiply = 1
      UserDefaults.standard.set(reviewContributionMultiply, forKey: KEY_REVIEW_CONTRIBUTION_MULTIPLY)
    }
    
    if reviewContribution >= Double(contribution) {
      SKStoreReviewController.requestReview()
      
      var newMultiply = reviewContributionMultiply
      if reviewContributionMultiply == 1 {
        newMultiply = 0.5
      } else if reviewContributionMultiply == 0.5 {
        newMultiply = 0.3
      }
      UserDefaults.standard.set(newMultiply, forKey: KEY_REVIEW_CONTRIBUTION_MULTIPLY)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_OPEN_APP)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_LOVE)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_COMMENT)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_CONTRIBUTION)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_FOLLOW)
    } else {
      UserDefaults.standard.set(reviewContribution + (1 * reviewContributionMultiply), forKey: KEY_REVIEW_CONTRIBUTION)
    }
  }
  
  func showReviewAlertFollow() {
    guard let showReviewConditions = ANISessionManager.shared.showReviewConditions,
          let follow = showReviewConditions[KEY_REVIEW_FOLLOW] else { return }
    
    let reviewFollow = UserDefaults.standard.double(forKey: KEY_REVIEW_FOLLOW)
    var reviewFollowMultiply = UserDefaults.standard.double(forKey: KEY_REVIEW_FOLLOW_MULTIPLY)
    if reviewFollowMultiply == 0 {
      reviewFollowMultiply = 1
      UserDefaults.standard.set(reviewFollowMultiply, forKey: KEY_REVIEW_FOLLOW_MULTIPLY)
    }
    
    if reviewFollow >= Double(follow) {
      SKStoreReviewController.requestReview()
      
      var newMultiply = reviewFollowMultiply
      if reviewFollowMultiply == 1 {
        newMultiply = 0.5
      } else if reviewFollowMultiply == 0.5 {
        newMultiply = 0.3
      }
      UserDefaults.standard.set(newMultiply, forKey: KEY_REVIEW_FOLLOW_MULTIPLY)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_OPEN_APP)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_LOVE)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_COMMENT)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_CONTRIBUTION)
      UserDefaults.standard.set(0, forKey: KEY_REVIEW_FOLLOW)
    } else {
      UserDefaults.standard.set(reviewFollow + (1 * reviewFollowMultiply), forKey: KEY_REVIEW_FOLLOW)
    }
  }
}
