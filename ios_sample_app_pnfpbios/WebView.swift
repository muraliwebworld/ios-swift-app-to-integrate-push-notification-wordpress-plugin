//
//  WebView.swift
//  
//
//  Created by user229065 on 1/1/23.
//

import SwiftUI
import WebKit
import Foundation
import CryptoSwift
import FirebaseMessaging


struct SwiftUIWebView: UIViewControllerRepresentable {
    let url: URL?
    struct Todopushparameters: Codable {
        var token: String?
        var userid: Int?
        var subscriptiontype: String?
        var subscriptionoptions: String?
        var groupid: String?
        
        enum CodingKeys : String, CodingKey {
            case token = "token"
            case userid = "userid"
            case subscriptiontype = "subscription-type"
            case subscriptionoptions = "subscriptionoptions"
            case groupid = "groupid"
        }
    }

    func makeUIViewController(context: Context) -> WebviewController {
        let webviewController = WebviewController()
        
        let request = URLRequest(url: self.url!)
        webviewController.webview.load(request)
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        
        let handler = MessageHandler()
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        //let dropSharedWorkersScript = WKUserScript(source: "delete window.SharedWorker;", injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        //config.userContentController.addUserScript(dropSharedWorkersScript)
        config.userContentController = WKUserContentController()
        
        // inject JS to capture console.log output and send to iOS
        //let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        //let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        //webviewController.webview.configuration.userContentController.addUserScript(script)
        
        // register the bridge script that listens for the output
        //webviewController.webview.configuration.userContentController.add(handler, name: "logHandler")
        webviewController.webview.configuration.userContentController.add(handler, name: "pnfpbuserid")
        webviewController.webview.configuration.userContentController.add(handler, name: "frontendsubscriptionOptions")
        webviewController.webview.configuration.userContentController.add(handler, name: "subscribeGroupid")
        webviewController.webview.configuration.userContentController.add(handler, name: "unsubscribeGroupid")
        
 
        return webviewController
    }

    func updateUIViewController(_ webviewController: WebviewController, context: Context) {
        //
        webviewController.webview.setPullToRefresh(type: .embed)
    }
    
    class MessageHandler: NSObject, WKScriptMessageHandler {
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            struct EventType:Codable{
                let status: Int!
                let message: String!
            }
            
            if let token = Messaging.messaging().fcmToken {
                if (token != "" && (message.name == "pnfpbuserid" || message.name == "frontendsubscriptionOptions" || message.name == "subscribeGroupid" || message.name == "unsubscribeGroupid")) {
                    do {
                        print(token)
                        let pass = "5c51cbed3567c3df0b9a0150ce4d29e9"
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
                        //print(token);
                        if message.name == "pnfpbuserid" {
                            let jsonDatamessagebody = try JSONSerialization.data(withJSONObject: message.body)
                            let eventTypeuserid = try JSONDecoder().decode(EventType.self, from: jsonDatamessagebody)
                            let newTodoItem = Todopushparameters(token: final_wp_post_string,userid:  Int(eventTypeuserid.message) ?? 0 ,subscriptiontype: "",subscriptionoptions: "",groupid: "")
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
                        if message.name == "frontendsubscriptionOptions" {
                            let jsonDatamessagebody = try JSONSerialization.data(withJSONObject: message.body)
                            let eventType = try JSONDecoder().decode(EventType.self, from: jsonDatamessagebody)
                            let newTodoItem = Todopushparameters(token: final_wp_post_string,userid: 0,subscriptiontype: "",subscriptionoptions: eventType.message,groupid:"")
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
                        if message.name == "subscribeGroupid" {
                            let jsonDatamessagebody = try JSONSerialization.data(withJSONObject: message.body)
                            let eventType = try JSONDecoder().decode(EventType.self, from: jsonDatamessagebody)
                            let newTodoItem = Todopushparameters(token: final_wp_post_string,userid: 0,subscriptiontype: "subscribe-group",subscriptionoptions: "",groupid:eventType.message)
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
                        if message.name == "unsubscribeGroupid" {
                            let jsonDatamessagebody = try JSONSerialization.data(withJSONObject: message.body)
                            let eventType = try JSONDecoder().decode(EventType.self, from: jsonDatamessagebody)
                            let newTodoItem = Todopushparameters(token: final_wp_post_string,userid: 0,subscriptiontype: "unsubscribe-group",subscriptionoptions: "",groupid:eventType.message)
                            
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

                    }
                    catch  {
                        print("Error info: \(error)")
                        print ("Error in encrypting token")
                    }
                }
            }
        }
    }
}

class WebviewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate {
    
    lazy var webview: WKWebView = WKWebView()
     
  
    lazy var progressbar: UIProgressView = UIProgressView()

    deinit {
        self.webview.removeObserver(self, forKeyPath: "estimatedProgress")
        self.webview.scrollView.removeObserver(self, forKeyPath: "contentOffset")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
 
        self.webview.navigationDelegate = self
        self.view.addSubview(self.webview)

        self.webview.frame = self.view.frame

        self.webview.translatesAutoresizingMaskIntoConstraints = true
        /*self.view.addConstraints([
            self.webview.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.webview.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.webview.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            self.webview.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])*/

        self.webview.addSubview(self.progressbar)
        
        self.setProgressBarPosition()
        
        NotificationCenter.default.addObserver(self,selector: #selector(reloadWebview(notification:)), name: Notification.Name("NotificationReloadWebView"), object: nil)
        
        webview.scrollView.addObserver(self, forKeyPath: "contentOffset", options: .new, context: nil)

        self.progressbar.progress = 0.1
        webview.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadWebview(notification:)), name: Notification.Name("NotificationReloadWebView"), object: nil)


    }
    
    @objc func reloadWebview(notification: Notification) {
        if let userinfo = notification.userInfo as? [String : Any] {
            // load the url to webview
            //let urlRequest = URLRequest(url: url)
            if let clickUrl = userinfo["url"] as? String {
                self.webview.load(URLRequest(url: URL(string:clickUrl)!))
            }
            else {
                self.webview.load(URLRequest(url: URL(string: "https://www.sampleiospnfpbapp.com")!))
            }
        }
        else {
            self.webview.load(URLRequest(url: URL(string: "https://www.sampleiospnfpbapp.com")!))
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      print(message.body)
    }

    func setProgressBarPosition() {
        self.progressbar.translatesAutoresizingMaskIntoConstraints = false
        self.webview.removeConstraints(self.webview.constraints)
        self.webview.addConstraints([
            self.progressbar.topAnchor.constraint(equalTo: self.webview.topAnchor, constant: self.webview.scrollView.contentOffset.y * -1),
            self.progressbar.leadingAnchor.constraint(equalTo: self.webview.leadingAnchor),
            self.progressbar.trailingAnchor.constraint(equalTo: self.webview.trailingAnchor),
        ])
    }

    // MARK: - Web view progress
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "estimatedProgress":
            if self.webview.estimatedProgress >= 1.0 {
                UIView.animate(withDuration: 0.3, animations: { () in
                    self.progressbar.alpha = 0.0
                }, completion: { finished in
                    self.progressbar.setProgress(0.0, animated: false)
                })
            } else {
                self.progressbar.isHidden = false
                self.progressbar.alpha = 1.0
                progressbar.setProgress(Float(self.webview.estimatedProgress), animated: true)
            }

        case "contentOffset":
            self.setProgressBarPosition()

        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}


extension WKWebView {
    
    var refreshControl: UIRefreshControl? { (scrollView.getAllSubviews() as [UIRefreshControl]).first }
    
    

    enum PullToRefreshType {
        case none
        case embed
    }

    func setPullToRefresh(type: PullToRefreshType) {
        (scrollView.getAllSubviews() as [UIRefreshControl]).forEach { $0.removeFromSuperview() }
        switch type {
            case .none: break
            case .embed: _setPullToRefresh(target: self, selector: #selector(webViewPullToRefreshHandler(source:)))
        }
    }

    private func _setPullToRefresh(target: Any, selector: Selector) {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(target, action: selector, for: .valueChanged)
        scrollView.addSubview(refreshControl)
    }

    @objc func webViewPullToRefreshHandler(source: UIRefreshControl) {
        guard let url = self.url else { source.endRefreshing(); return }
        load(URLRequest(url: url))
    }
}

extension UIView {

    class func getAllSubviews<T: UIView>(from parenView: UIView) -> [T] {
        return parenView.subviews.flatMap { subView -> [T] in
            var result = getAllSubviews(from: subView) as [T]
            if let view = subView as? T { result.append(view) }
            return result
        }
    }

    func getAllSubviews<T: UIView>() -> [T] { return UIView.getAllSubviews(from: self) as [T] }
}
	
