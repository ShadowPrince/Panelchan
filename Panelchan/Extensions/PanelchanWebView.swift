//
//  PCHWebView.swift
//  Panelchan
//
//  Created by shdwprince on 5/26/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import ObjectiveC

import UIKit
import WebKit

typealias EmbedElement = Dictionary<String, String>
typealias EmbedImage = String

var PCHWebViewDelegateHandle: UInt8 = 1
extension UIWebView {
    /*
    var pch_events: EmbedWebViewDelegate? {
        return objc_getAssociatedObject(self, &PCHWebViewDelegateHandle) as! EmbedWebViewDelegate?
    }

    func pch_init() {
        objc_setAssociatedObject(self, &PCHWebViewDelegateHandle, EmbedWebViewDelegate(), objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.addDelegate(self.pch_events!)
    }
 */

    func pch_inject() {
        if (self.stringByEvaluatingJavaScript(from: "__pch.is_injected()") != "1") {
            self.embedJavascript("zepto")
            self.embedJavascript("pch_embed")
        }
    }

    func pch_parse(_ string: String) -> Any? {
        return try? JSONSerialization.jsonObject(with: string.data(using: .utf8)!, options: [])
    }

    func pch_eval(method: String, arguments list: String) -> Any? {
        return self.pch_parse(self.stringByEvaluatingJavaScript(from: "__pch.\(method)(\(list))") ?? "")
    }
    
    
    func pch_element(at p: CGPoint) -> EmbedElement? {
        return self.pch_eval(method: "element_at", arguments: "\(p.x), \(p.y)") as! EmbedElement?
    }
    
    func pch_click(selector: String) -> Bool {
        return self.pch_eval(method: "click_selector", arguments: "\"\(selector)\"") != nil
    }

    func pch_images(bigger px: Int) -> [EmbedImage] {
        return self.pch_eval(method: "images_bigger_than", arguments: "\(px)") as! [EmbedImage]
    }
}

/*
enum EmbedEvent: String {
    case mutated = "mutated"
    case ready = "ready"
}

protocol EmbedDelegate {
    func fired(event: EmbedEvent)
}

class EmbedWebViewDelegate: NSObject, UIWebViewDelegate {
    var delegate: EmbedDelegate?

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url?.absoluteString else {
            return true
        }

        if url.hasPrefix("pch://") == true {
            if let event = EmbedEvent(rawValue: url.substring(from: url.index(url.startIndex, offsetBy: 6))) {
                self.delegate?.fired(event: event)
            } else {
                assertionFailure("Unknown event: \(url)")
            }

            return false
        }

        return true
    }
}
*/
