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
}

extension UIWebView {
    func pch_count(selector: String) -> Int {
        return (self.pch_eval(method: "count_sel", arguments: "\"\(selector)\"") as! [Int]).first!
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

    func pch_title() -> String {
        return self.stringByEvaluatingJavaScript(from: "document.title") ?? "Untitled"
    }
}
