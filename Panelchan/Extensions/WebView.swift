//
//  WebView.swift
//  Panelchan
//
//  Created by shdwprince on 5/9/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit
import WebKit

typealias PCHElement = Dictionary<String, String>

extension UIWebView {
    func embedJavascript(_ name: String) {
        let _ = try? self.stringByEvaluatingJavaScript(from: String(contentsOf: Bundle.main.url(forResource: name, withExtension: "js")!))
    }

    func loadRequest(string url: String) {
        self.loadRequest(URLRequest(url: URL(string: url)!))
    }
}

extension UIWebView {
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
    
    
    func pch_element(at p: CGPoint) -> PCHElement? {
        return self.pch_eval(method: "element_at", arguments: "\(p.x), \(p.y)") as! PCHElement?
    }
    
    func pch_click(selector: String) {
        let _ = self.pch_eval(method: "click_selector", arguments: "\"\(selector)\"")
    }
}
