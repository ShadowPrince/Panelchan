//
//  ChanController.swift
//  Panelchan
//
//  Created by shdwprince on 5/24/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class ChanController: NSObject {
    struct Selector {
        let tag, id, klass: String

        init(tag: String, id: String, klass: String) {
            self.tag = tag
            self.id = id
            self.klass = klass
        }

        init(_ dict: PCHElement) {
            self.tag = dict["tag"]!
            self.id = dict["id"]!
            self.klass = dict["class"]!
        }
    }

    let url: URL
    let previousSelector, nextSelector: Selector
    var webView: UIWebView?

    init(url: URL, previous: Selector, next: Selector) {
        self.url = url
        self.previousSelector = previous
        self.nextSelector = next

        super.init()
    }
}
