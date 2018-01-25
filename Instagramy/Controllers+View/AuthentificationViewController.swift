//
//  AuthentificationViewController.swift
//  Instagramy
//
//  Created by Alexander Smyshlaev on 1/25/18.
//  Copyright © 2018 Alexander Smyshlaev. All rights reserved.
//

import UIKit
import WebKit

class AuthentificationViewController: UIViewController {
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.navigationDelegate = self

        webView.load(URLRequest(url: URL(string: "https://api.instagram.com/oauth/authorize/?client_id=\(InstagramStore.shared.clientId)&redirect_uri=http://localhost&response_type=token&scope=public_content")!))
    }
}

extension AuthentificationViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if (webView.url!.absoluteString.contains("access_token")) {
            let access_token = webView.url?.absoluteString.components(separatedBy: "=").last
            
            InstagramStore.shared.accessToken = access_token
            
            dismiss(animated: true, completion: nil)
        }
    }
}
