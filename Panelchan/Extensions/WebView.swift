//
//  WebView.swift
//  Panelchan
//
//  Created by shdwprince on 5/9/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import ObjectiveC

import UIKit
import WebKit

extension UIWebView {
    func embedJavascript(_ name: String) {
        let _ = try? self.stringByEvaluatingJavaScript(from: String(contentsOf: Bundle.main.url(forResource: name, withExtension: "js")!))
    }

    func loadRequest(string url: String) {
        self.loadRequest(URLRequest(url: URL(string: url)!))
    }
}

var UIWebViewDelegatesHandle: UInt8 = 0
extension UIWebView: UIWebViewDelegate {
    var delegates: [UIWebViewDelegate] {
        get {
            return objc_getAssociatedObject(self, &UIWebViewDelegatesHandle) as! [UIWebViewDelegate]
        }

        set {
            objc_setAssociatedObject(self, &UIWebViewDelegatesHandle, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public func addDelegate(_ delegate: UIWebViewDelegate) {
        if self.delegate !== self {
            self.delegates = []
            self.delegate = self
        }

        self.delegates.append(delegate)
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        for delegate in self.delegates {
            delegate.webViewDidFinishLoad?(webView)
        }
    }

    public func webViewDidStartLoad(_ webView: UIWebView) {
        for delegate in self.delegates {
            delegate.webViewDidStartLoad?(webView)
        }
    }

    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        for delegate in self.delegates {
            if (delegate.webView?(webView, shouldStartLoadWith: request, navigationType: navigationType) == false) {
                return false
            }
        }

        return true
    }
}

