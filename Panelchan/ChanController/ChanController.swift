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
    static let MinSize = 700
    
    enum Errors: Error {
        case failedToInvoke
        case failedToProcess
    }

    fileprivate var webView: UIWebView!

    fileprivate var settingUp = false
    fileprivate var content = [EmbedImage]()
    fileprivate var contentIndex = 0

    weak var delegate: ChanControllerDelegate?
    var series: Series

    init(webView: UIWebView, series: Series) {
        self.webView = webView
        self.series = series

        super.init()
        self.webView.addDelegate(self)
    }
}

// MARK: fetch
extension ChanController {
    fileprivate func fetchInvocation(of selector: Series.Selector) {
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
            print("fetch")
            let until = CFAbsoluteTimeGetCurrent() + 10.0
            var run = true
            var timeout = false
            var currentContent = self.content
            
            repeat {
                DispatchQueue.main.sync {
                    if !self.webView.pch_is_injected() {
                        return
                    }

                    let newContent = self.webView.pch_images(bigger: ChanController.MinSize)
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

    fileprivate func updateSeries() {
        self.series.thumbnail = self.content.first
        self.series.updated = Date()
        self.series.url = webView.request!.url!

        Store.shared.store()
    }
}

// MARK: content controller
protocol ChanControllerDelegate: class {
    func chanController(_ controller: ChanController, gotImage url: URL)
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
            self.fetchInvocation(of: self.contentIndex < 0 ? self.series.previous : self.series.next)
        } else {
            self.delegate?.chanController(self, gotImage: self.content[self.contentIndex])
        }
    }
}

// MARK: actions
extension ChanController {
    func setupWebView() {
        self.settingUp = true
        self.webView.loadRequest(url: self.series.url)
    }
    
    func requestCurrent() {
        self.fetchProcess()
    }

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
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.webView.pch_inject()

        if self.settingUp {
            self.requestCurrent()
            self.settingUp = false
        }
    }
}
