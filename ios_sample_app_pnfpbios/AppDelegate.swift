//
//  Appdelegate.swift
//  
//
//  Created by user233299 on 2/6/23.
//

import Foundation

import FirebaseCore
//import Firestore
import FirebaseMessaging
import UIKit
import UserNotifications
//import CryptoKit
import CryptoSwift

//@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    //var window: UIWindow?
    let gcmMessageIDKey = "gcm.message_id"
    //let userID: String
    override init() {
        super.init()
    }
    struct pnfpbtokenstruct {
        public var pnfpbtoken: String?
    }
    struct ToDoResponseModel: Codable {
        var token: String?
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication
                       .LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            //let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            //UNUserNotificationCenter.current().requestAuthorization(
            //    options: authOptions,
            //    completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM)
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                if granted {
                    
                    
                } else {
                    print("Permission not granted")
                }
            }
          
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            //application.registerForRemoteNotifications()
        }
                  
        application.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        updatePushTokenIfNeeded();
        return true
    }

    func updatePushTokenIfNeeded() {
        if let token = Messaging.messaging().fcmToken {
            if (token != "") {
                do {
                    let pass = "5c51cbed3343g67f0b9a0150ce4d29e9"
                    //let token_data = token.data(using: .utf8 )!
                    /* Generate random IV value. IV is public value. Either need to generate, or get it from elsewhere */
                    let iv = Data(count: 16)
                    let aes = try AES(key: pass.bytes, blockMode: CBC(iv:iv.bytes), padding: .pkcs5)
                    let aesE = try aes.encrypt(Array(token.utf8))
                    let result = Array(aesE).toBase64()
                    let hmac_signature = try CryptoSwift.HMAC(key: pass, variant: .sha256).authenticate(token.bytes)
                    let hmac_signature_string = Data(hmac_signature).map { String(format: "%02x", $0) }.joined()
                    let ivstring = iv.base64EncodedString()
                    let final_wp_post_string = result + ":" + ivstring + ":" + hmac_signature_string + ":" + hmac_signature_string
                    // Prepare URL
                    let url = URL(string: "https://www.sampleiospnfpbapp.com/wp-json/PNFPBpush/v1/subscriptiontoken")
                    guard let requestUrl = url else { fatalError() }
                    // Prepare URL Request Object
                    var request = URLRequest(url: requestUrl)
                    request.httpMethod = "POST"
                    // Set HTTP Request Header
                    request.setValue("application/json", forHTTPHeaderField: "Accept")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    let newTodoItem = ToDoResponseModel(token: final_wp_post_string)
                    let jsonData = try JSONEncoder().encode(newTodoItem)
                    request.httpBody = jsonData
                    // Perform HTTP Request
                    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                        
                        // Check for Error
                        if let error = error {
                            print("Error took place \(error)")
                            return
                        }
                        
                        // Convert HTTP Response Data to a String
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response data string:\n \(dataString)")
                            return
                        }
                    }
                    task.resume()
                }
                catch  {
                    print ("Error in encrypting token")
                }
            }
            
        }
    }

    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification
      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)
      // Print message ID.
      //if let messageID = userInfo[gcmMessageIDKey] {
       // print("Message ID: \(messageID)")
      //}
        print(userInfo)
      // Print full message.

    }

    // [START receive_message]
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
      -> UIBackgroundFetchResult {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification
      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)
      // Print message ID.
      //if let messageID = userInfo[gcmMessageIDKey] {
      //  print("Message ID: \(messageID)")
      //}

      // Print full message.

      print(userInfo)
      return UIBackgroundFetchResult.newData
    }

    // [END receive_message]
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
      print("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication,
                    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            //let new_token_data = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        //Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        Messaging.messaging().apnsToken = deviceToken
        //Messaging.messaging().setAPNSToken(deviceToken, type: .unknown);
        print("APNs token retrieved: \(deviceToken)")
        
      // With swizzling disabled you must set the APNs token here.
      // Messaging.messaging().apnsToken = deviceToken
    }
}

// [START ios_10_message_handling]
extension AppDelegate: UNUserNotificationCenterDelegate {
  // Receive displayed notifications for iOS 10 devices.
    
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
    let userInfo = notification.request.content.userInfo
      
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)
    // [START_EXCLUDE]
    // Print message ID.
    //if let messageID = userInfo[gcmMessageIDKey] {
    //  print("Message ID: \(messageID)")
    //}
    // [END_EXCLUDE]
    // Print full message.
    print(userInfo)

    // Change this to your preferred presentation option
        return [[.banner, .badge, .list, .sound]]
  }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) async {
    let userInfo = response.notification.request.content.userInfo
        print(response);
        print("userInfo")
        print(userInfo)
      if let aps = userInfo["aps"] as? [String: Any] {
          if let newUrl = aps["alert"] as? String {
              let info = ["url": newUrl]

              // post notification with info (url)
              NotificationCenter.default.post(name: NSNotification.Name(rawValue: "NotificationReloadWebView"), object: nil, userInfo: info)
          }
      }

      completionHandler()
    // [START_EXCLUDE]
    // Print message ID.
    //if let messageID = userInfo[gcmMessageIDKey] {
    //  print("Message ID: \(messageID)")
    //}
    // [END_EXCLUDE]
    // With swizzling disabled you must let Messaging know about the message, for Analytics
    // Messaging.messaging().appDidReceiveMessage(userInfo)
    // Print full message.
    
  }
}

// [END ios_10_message_handling]
extension AppDelegate: MessagingDelegate {
  // [START refresh_token]
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
   
    print("Firebase registration token: \(String(describing: fcmToken))")

    let dataDict: [String: String] = ["token": fcmToken ?? ""]
    NotificationCenter.default.post(
      name: Notification.Name("FCMToken"),
      object: nil,
      userInfo: dataDict
    )
    // TODO: If necessary send token to application server.
    // Note: This callback is fired at each app startup and whenever a new token is generated.
      //let token = Messaging.messaging().fcmToken
      updatePushTokenIfNeeded();
      
  }

  // [END refresh_token]
}

public extension Data {
    init?(hexString: String) {
      let len = hexString.count / 2
      var data = Data(capacity: len)
      var i = hexString.startIndex
      for _ in 0..<len {
        let j = hexString.index(i, offsetBy: 2)
        let bytes = hexString[i..<j]
        if var num = UInt8(bytes, radix: 16) {
          data.append(&num, count: 1)
        } else {
          return nil
        }
        i = j
      }
      self = data
    }
    /// Hexadecimal string representation of `Data` object.
    var hexadecimal: String {
        return map { String(format: "%02x", $0) }
            .joined()
    }
}
