//
//  ANITwitter.swift
//  Ani
//
//  Created by jeonminseop on 2019/01/21.
//  Copyright © 2019年 JeonMinseop. All rights reserved.
//

import UIKit
import TwitterKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import CodableFirebase
import GoogleSignIn

class ANITwitter {
  
  private var consumerKey:String{
    return IS_DEBUG ? "xCegpToqU9e5izA21PcDinUYa" : "DxesnPxqOKgHw7cYOmo7u6l9I"
  }
  
  private var consumerSecret:String{
    return IS_DEBUG ? "4nRTG2qONJJxREvoJuLcn47TmjkBaPHAN3jFki7SVkDE13zmQU" : "Wg6WBTdo2Kt5Uhrq3CRKaB9lkFxYLXDEUh8Bt8XeOwxTOIEhjf"
  }
  
  init() {
    TWTRTwitter.sharedInstance().start(withConsumerKey: consumerKey, consumerSecret: consumerSecret)
  }
  
  static func unLink() {
    let store = TWTRTwitter.sharedInstance().sessionStore
    guard let session = store.session() else{
      DLog("no twitter session")
      return
    }
    
    let userId = session.userID
    let credential = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)
    if let user = Auth.auth().currentUser {
      user.unlink(fromProvider: credential.provider, completion: { (user, error) in
        if let error = error {
          DLog("unlink error \(error.localizedDescription)")
          return
        }
        
        store.logOutUserID(userId)
      })
    }
  }
  
  static func logOut() {
    let sessionStore = TWTRTwitter.sharedInstance().sessionStore
    if let session = sessionStore.session() {
      sessionStore.logOutUserID(session.userID)
    }
  }
  
  static func login(isLink: Bool, completion: @escaping ((Bool, String?)->())) {
    TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
      if let error = error {
        DLog("Twitterログインに失敗しました \(error.localizedDescription)")
        signOut(isLink: isLink)
        completion(false, "Twitterログインに失敗しました。")
        return
      }
      
      guard let session = session else { return }
      
      let credential = TwitterAuthProvider.credential(withToken: session.authToken, secret: session.authTokenSecret)

      //既にログインしているユーザーならtwitterとリンクさせる
      if let user = Auth.auth().currentUser {
        user.linkAndRetrieveData(with: credential, completion: { (result, error) in
          if let error = error {
            signOut(isLink: isLink)

            let nsError = error as NSError
            if nsError.code == 17025 {
              DLog("Twitterアカウントが既に使用されています。\(error.localizedDescription)")
              completion(false, "Twitterアカウントが既に使用されています。")
            } else {
              DLog("Twitterの連携に失敗しました。\(error.localizedDescription)")
              completion(false, "Twitterのリンクに失敗しました。")
            }
            
            return
          }
          
          let database = Firestore.firestore()
          
          let values = [KEY_TWITTER_ACCOUNT: "@" + session.userName, KEY_IS_TWITTER_LINK: true] as [String : AnyObject]
          updateUserData(uid: user.uid, values: values, completion: completion)
        })
      } else {
        let client = TWTRAPIClient(userID: session.userID)
        client.loadUser(withID: session.userID, completion: { (user, error) in
          if let error = error {
            DLog("Twitterユーザー取得に失敗しました \(error.localizedDescription)")
            signOut()
            completion(false, "Twitterユーザー取得に失敗しました。")
            return
          }
          
          guard let user = user else { return }
          
          Auth.auth().signInAndRetrieveData(with: credential) { (result, error) in
            if let error = error {
              DLog("入力されたTwitterアカウントは使用できません \(error.localizedDescription)")
              signOut()
              completion(false, "入力されたTwitterアカウントは使用できません。")
              return
            }
            
            let database = Firestore.firestore()
            if let crrentUserId = Auth.auth().currentUser?.uid {
              //再ログインかアカウント作成か判断
              database.collection(KEY_USERS).document(crrentUserId).getDocument(completion: { (snapshot, error) in
                if let error = error {
                  DLog("get document error \(error.localizedDescription)")
                  signOut()
                  completion(false, "データ取得に失敗しました。")
                  return
                }
                
                if let snapshot = snapshot, snapshot.data() != nil {
                  completion(true, nil)
                } else {
                  getUniqueUserName(userName: user.name, count: 0, completion: { (uniqueUserName) in
                    if uniqueUserName == "" {
                      signOut()
                      completion(false, "MYAUアカウント登録に失敗しました。")
                      let sessionStore = TWTRTwitter.sharedInstance().sessionStore
                      if let session = sessionStore.session() {
                        sessionStore.logOutUserID(session.userID)
                      }
                      return
                    }
                    
                    if let url = URL(string: user.profileImageLargeURL) {
                      DispatchQueue.global().async {
                        if let data = try? Data(contentsOf: url),
                          let image = UIImage(data: data)?.resize(size: CGSize(width: 500.0, height: 500.0)) {
                          uploadUserData(userName: uniqueUserName, twitterScreenName: user.screenName, profileImage: image, completion: completion)
                        }
                      }
                    } else {
                      if let image = UIImage(named: "profileDefaultImage") {
                        uploadUserData(userName: uniqueUserName, twitterScreenName: user.screenName, profileImage: image, completion: completion)
                      }
                    }
                  })
                }
              })
            }
          }
        })
      }
    })
    
    func uploadUserData(userName: String, twitterScreenName: String, profileImage: UIImage, completion: @escaping ((Bool, String?)->())) {
      guard let currentUser = Auth.auth().currentUser,
        let profileImageData = profileImage.jpegData(compressionQuality: 0.5) else { return }
      
      let storageRef = Storage.storage().reference()
      storageRef.child(KEY_PROFILE_IMAGES).child("\(currentUser.uid).jpeg").putData(profileImageData, metadata: nil) { (metaData, error) in
        if error != nil {
          DLog("storageError")
          signOut()
          completion(false, "データの書き込みに失敗しました。")
          return
        }
        
        storageRef.child(KEY_PROFILE_IMAGES).child("\(currentUser.uid).jpeg").downloadURL(completion: { (url, error) in
          if error != nil {
            DLog("storage download url error")
            signOut()
            completion(false, "データのロードに失敗しました。")
            return
          }
          
          if let profileImageUrl = url {
            let fcmToken = UserDefaults.standard.string(forKey: KEY_FCM_TOKEN)
            let user = FirebaseUser(uid: currentUser.uid, userName: userName, kind: "個人", introduce: "", profileImageUrl: profileImageUrl.absoluteString, familyImageUrls: nil, checkNotiDate: nil, isHaveUnreadNoti: false, unreadNotiCount: 0, unreadMessageCount: 0, fcmToken: fcmToken, twitterAccount: "@" + twitterScreenName, instagramAccount: nil, isTwitterLink: true)
            
            uploadUserIntoDatabase(uid: currentUser.uid, user: user, completion: completion)
          }
        })
      }
    }
    
    func uploadUserIntoDatabase(uid: String, user: FirebaseUser, completion: @escaping ((Bool, String?)->())) {
      let database = Firestore.firestore()
      
      do {
        let userData = try FirestoreEncoder().encode(user)
        
        database.collection(KEY_USERS).document(uid).setData(userData) { error in
          if let error = error {
            DLog("Error set document: \(error)")
            signOut()
            completion(false, "アカウント登録に失敗しました。")
            return
          }
          
          pushDataAlgolia(data: userData as [String: AnyObject])

          completion(true, nil)
        }
      } catch let error {
        DLog(error)
        completion(false, "アカウント登録に失敗しました。")
      }
    }
    
    func updateUserData(uid: String, values: [String: AnyObject], completion: @escaping ((Bool, String?)->())) {
      let database = Firestore.firestore()
      database.collection(KEY_USERS).document(uid).updateData(values) { (error) in
        if let error = error {
          DLog("update data error \(error.localizedDescription)")
          signOut(isLink: true)
          completion(false, "データアップロードに失敗しました。")
        }
        
        updateDataAlgolia(data: values)
        
        database.collection(KEY_USERS).document(uid).getDocument { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            signOut(isLink: true)
            completion(false, "データ取得に失敗しました。")
            return
          }
          
          guard let snapshot = snapshot, let data = snapshot.data() else { return }
          
          do {
            let user = try FirestoreDecoder().decode(FirebaseUser.self, from: data)
            ANISessionManager.shared.currentUser = user
            completion(true, nil)
          } catch let error {
            DLog("decoder error \(error)")
            signOut(isLink: true)
            completion(false, "ユーザー取得に失敗しました。")
          }
        }
      }
    }
    
    func pushDataAlgolia(data: [String: AnyObject]) {
      let index = ANISessionManager.shared.client.index(withName: KEY_USERS_INDEX)
      
      var newData = data
      if let objectId = data[KEY_UID] {
        newData.updateValue(objectId, forKey: KEY_OBJECT_ID)
      }
      
      DispatchQueue.global().async {
        index.addObject(newData, completionHandler: { (content, error) -> Void in
          if let error = error {
            DLog("algolia error \(error)")
          }
          
          guard let content = content else { return }
          DLog("Object IDs: \(content)")
        })
      }
    }
    
    func updateDataAlgolia(data: [String: AnyObject]) {
      guard let objectId = ANISessionManager.shared.currentUserUid else { return }
      
      let index = ANISessionManager.shared.client.index(withName: KEY_USERS_INDEX)
      
      DispatchQueue.global().async {
        index.partialUpdateObject(data, withID: objectId, completionHandler: { (content, error) -> Void in
          if error == nil {
            DLog("Object IDs: \(content!)")
          }
        })
      }
    }
    
    func getUniqueUserName(userName: String, count: Int, completion: @escaping ((String)->())) {
      let database = Firestore.firestore()
      if count > 30 {
        DLog("Error get unique user name")
        completion("")
        return
      }
      
      DispatchQueue.global().async {
        database.collection(KEY_USERS).whereField(KEY_USER_NAME, isEqualTo: userName).getDocuments(completion: { (snapshot, error) in
          if let error = error {
            DLog("Error get document: \(error)")
            completion("")
            return
          }

          guard let snapshot = snapshot else { return }

          if snapshot.documents.isEmpty {
            completion(userName)
          } else {
            let randomInt = String(Int.random(in: 1 ... 10))
            let newUserName = userName + randomInt
            getUniqueUserName(userName: newUserName, count: count + 1, completion: completion)
          }
        })
      }
    }
    
    func signOut(isLink: Bool = false) {
      if !isLink, Auth.auth().currentUser != nil {
        do {
          let sessionStore = TWTRTwitter.sharedInstance().sessionStore
          if let session = sessionStore.session() {
            sessionStore.logOutUserID(session.userID)
          }
  
          try Auth.auth().signOut()
          ANITwitter.logOut()
          GIDSignIn.sharedInstance().signOut()
          
          let userDefaults = UserDefaults.standard
          userDefaults.set(false, forKey: KEY_IS_TWITTER_SHARE)
  
          ANISessionManager.shared.currentUser = nil
          ANISessionManager.shared.currentUserUid = nil
          ANISessionManager.shared.isAnonymous = true
          ANISessionManager.shared.blockUserIds = nil
          ANISessionManager.shared.blockingUserIds = nil
  
          ANINotificationManager.postLogout()
        } catch let signOutError as NSError {
          DLog("signOutError \(signOutError)")
        }
      }
      
      let sessionStore = TWTRTwitter.sharedInstance().sessionStore
      if let session = sessionStore.session() {
        sessionStore.logOutUserID(session.userID)
      }
    }
  }
}
