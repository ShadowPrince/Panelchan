//
//  ChanController.swift
//  Panelchan
//
//  Created by shdwprince on 5/24/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit
import Dispatch

class ChanController: NSObject, NSCoding {
    enum Errors: Error {
        case failedToInvoke
        case failedToProcess
    }

    struct Selector {
        let tag, id, klass, custom: String

        init(tag: String, id: String, klass: String) {
            self.tag = tag
            self.id = id
            self.klass = klass
            self.custom = ""
        }

        init(custom selector: String) {
            self.tag = ""
            self.id = ""
            self.klass = ""
            self.custom = selector
        }

        init(_ dict: EmbedElement) {
            self.tag = dict["tag"]!
            self.id = dict["id"]!
            self.klass = dict["class"]!
            self.custom = ""
        }
    }

    fileprivate var webView: UIWebView!
    weak var delegate: ChanControllerDelegate?

    fileprivate var content = [EmbedImage]()
    fileprivate var contentIndex = 0
    var url: URL
    var previousSelector, nextSelector: Selector

    init(webView: UIWebView, url: URL, previous: Selector, next: Selector) {
        self.url = url
        self.previousSelector = previous
        self.nextSelector = next
        self.webView = webView

        super.init()

        self.webView.addDelegate(self)
    }

    required init?(coder c: NSCoder) {
        self.url = c.decode()
        self.content = c.decode()
        self.contentIndex = c.decode()
        self.nextSelector = c.decode()
        self.previousSelector = c.decode()

        super.init()
    }

    func encode(with c: NSCoder) {
        c.encode(self.url)
        c.encode(self.content)
        c.encode(self.contentIndex)
        c.encode(self.nextSelector)
        c.encode(self.previousSelector)
    }
}

// MARK: fetch
extension ChanController {
    fileprivate func fetchInvocation(of selector: Selector) {
        func classListSelector(_ list: String, drop const_drop: Int) -> String {
            var drop = const_drop

            return list.components(separatedBy: " ").reduce("") { (buf: String, part: String) -> String in
                drop -= 1
                if drop < 0 && part != "" {
                    return buf.appending(".\(part)")
                } else {
                    return buf
                }
            }
        }

        enum IterStage {
            case custom
            case full
            case id
            case klass(drop: Int)
        }

        var firedSuccessfully = false
        var iter = IterStage.custom

        loop: repeat {
            var selectorString = ""
            switch iter {
            case .custom:
                selectorString = selector.custom

                iter = .full
            case .full:
                if selector.id != "" {
                    selectorString = "#foo\(selector.id)\(classListSelector(selector.klass, drop: 0))"
                }

                iter = .id
            case .id:
                if selector.id != "" {
                    selectorString = "#\(selector.id)"
                }

                iter = .klass(drop: 0)
            case .klass(let drop):
                if selector.klass != "" {
                    selectorString = classListSelector(selector.klass, drop: drop)
                }

                if selectorString == "" {
                    break loop
                } else {
                    iter = .klass(drop: drop + 1)
                }
            }

            if selectorString != "" && self.webView.pch_click(selector: selectorString) {
                firedSuccessfully = true
                break loop
            }
            
        } while true

        if firedSuccessfully {
            self.fetchProcess()
        } else {
            self.delegate?.chanController(self, didFailWith: Errors.failedToInvoke)
        }
    }

    fileprivate func fetchProcess() {
        DispatchQueue.global(qos: .userInitiated).async {
            let until = CFAbsoluteTimeGetCurrent() + 10.0
            var run = true
            var timeout = false
            var currentContent = self.content
            
            repeat {
                DispatchQueue.main.sync {
                    let newContent = self.webView.pch_images(bigger: 700)
                    if newContent.count > 0 && currentContent != newContent {
                        currentContent = newContent
                        run = false
                    }
                }
                
                if CFAbsoluteTimeGetCurrent() > until {
                    run = false
                    timeout = true
                } else if run {
                    print("Slept in fetch")
                    Thread.sleep(forTimeInterval: 0.2)
                } 
            } while run

            DispatchQueue.main.sync {
                if !timeout {
                    self.contentReplace(currentContent)
                } else {
                    self.delegate?.chanController(self, didFailWith: Errors.failedToProcess)
                }
            }
        }
    }
}

// MARK: content controller

protocol ChanControllerDelegate: class {
    func chanController(_ controller: ChanController, gotImage url: String)
    func chanController(_ controller: ChanController, didFailWith error: Error)
}

extension ChanController {
    fileprivate func contentReplace(_ new: [EmbedImage]) {
        self.content = new
        self.contentIndex = 0

        self.delegate?.chanController(self, gotImage: self.content[self.contentIndex])
    }

    fileprivate func contentRequest() {
        if self.content.count <= self.contentIndex || self.contentIndex < 0 {
            self.fetchInvocation(of: self.contentIndex < 0 ? self.previousSelector : self.nextSelector)
        } else {
            self.delegate?.chanController(self, gotImage: self.content[self.contentIndex])
        }
    }
}

// MARK: actions
extension ChanController {
    func requestNext() {
        self.contentIndex += 1
        self.contentRequest()
    }

    func requestPrev() {
        self.contentIndex -= 1
        self.contentRequest()
    }
}

// MARK: webview
extension ChanController: UIWebViewDelegate {
    // hopefully block popups
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if navigationType != .linkClicked && navigationType != .backForward {
            return false
        }

        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.url = webView.request!.url!
    }
}
