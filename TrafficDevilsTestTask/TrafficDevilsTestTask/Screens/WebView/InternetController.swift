//
//  InternetController.swift
//  TrafficDevilsTestTask
//
//  Created by Vitya Mandryk on 11.02.2024.
//

import Foundation
import UIKit
import WebKit

class InternetController: UIViewController {
    
    @IBOutlet private weak var backButton: UIBarButtonItem!
    @IBOutlet private weak var webView: WKWebView!
    
    var urlToLoad: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadURL()
    }
    
    private func loadURL() {
        if let url = urlToLoad {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    @IBAction private func backButtonTapped(_ sender: UIBarButtonItem) {
        if webView.canGoBack {
            webView.goBack()
        } else {
            self.dismiss(animated: true)
            let vc = ViewSource.mainScreen()
            vc.modalPresentationStyle = .overFullScreen
            NavigationController.shared?.pushViewController(vc, animated: false)
        }
    }
}

extension InternetController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("Web view loaded successfully.")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("Web view failed to load: \(error.localizedDescription)")
    }
}

