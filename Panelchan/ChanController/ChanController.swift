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

class ChanController: NSObject {
    enum Errors: Error {
        case failedToProcess
    }

    struct Selector {
        let tag, id, klass: String

        init(tag: String, id: String, klass: String) {
            self.tag = tag
            self.id = id
            self.klass = klass
        }

        init(_ dict: EmbedElement) {
            self.tag = dict["tag"]!
            self.id = dict["id"]!
            self.klass = dict["class"]!
        }
    }

    fileprivate var content = [EmbedImage]()
    fileprivate var contentIndex = 0

    fileprivate let previousSelector, nextSelector: Selector
    fileprivate var webView: UIWebView

    weak var delegate: ChanControllerDelegate?
    let url: URL

    init(webView: UIWebView, url: URL, previous: Selector, next: Selector) {
        self.url = url
        self.previousSelector = previous
        self.nextSelector = next
        self.webView = webView

        super.init()
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
            case full
            case id
            case klass(drop: Int)
        }

        var firedSuccessfully = false
        var iter = IterStage.full

        loop: repeat {
            var selectorString = ""
            switch iter {
            case .full:
                selectorString = "#foo\(selector.id)\(classListSelector(selector.klass, drop: 0))"

                iter = .id
            case .id:
                selectorString = "#\(selector.id)"

                iter = .klass(drop: 0)
            case .klass(let drop):
                selectorString = classListSelector(selector.klass, drop: drop)

                if selectorString == "" {
                    break loop
                } else {
                    iter = .klass(drop: drop + 1)
                }
            }

            if self.webView.pch_click(selector: selectorString) {
                firedSuccessfully = true
                break loop
            }
            
        } while true

        if firedSuccessfully {
            self.fetchProcess()
        } else {
            // TODO: error
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
                    // TODO: display error
                }
            }
        }
    }
}

// MARK: content controller

protocol ChanControllerDelegate: class {
    func chanController(_ controller: ChanController, got image: String)
}

extension ChanController {
    fileprivate func contentReplace(_ new: [EmbedImage]) {
        self.content = new
        self.contentIndex = 0

        // fire new first image
        print(self.content[self.contentIndex])
    }

    fileprivate func contentRequest() {
        if self.content.count <= self.contentIndex || self.contentIndex < 0 {
            self.fetchInvocation(of: self.contentIndex < 0 ? self.previousSelector : self.nextSelector)
        } else {
            // fire this
            print(self.content[self.contentIndex])
        }
    }
}

// MARK: actions
extension ChanController {
    func requestNext() throws {
        self.contentIndex += 1
        self.contentRequest()
    }

    func requestPrev() throws {
        self.contentIndex -= 1
        self.contentRequest()
    }
}
