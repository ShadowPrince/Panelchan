//
//  SaveGuideViewController.swift
//  Panelchan
//
//  Created by shdwprince on 5/23/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class SaveGuideViewController: UIViewController, UIWebViewDelegate, UIGestureRecognizerDelegate {
    enum Stage: Int {
        case initial
        case nextSelector
        case previousSelector
        case finished
    }
    
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var helpView: UITextView!

    private var _stage = Stage.initial
    var stage: Stage {
        get {
            return self._stage
        }

        set {
            self.enteredStage(newValue)
            self._stage = newValue
        }
    }
    var chanController: ChanController?
    var nextSelector: ChanController.Selector?
    var prevSelector: ChanController.Selector?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.stage = .nextSelector
    }

    // MARK: stages
    func enteredStage(_ stage: Stage) {
        switch stage {
        case .initial:
            break
        case .nextSelector:
            self.helpView.text = "Hold on next selector"
        case .previousSelector:
            self.helpView.text = "Hold on previous selector"
        case .finished:
            self.chanController = ChanController(url: self.webView.request!.url!,
                                                 previous: self.prevSelector!,
                                                 next: self.nextSelector!)
            self.helpView.text = "Url: \(self.chanController?.url)"
        }
    }

    func holdNextSelectorStage(_ point: CGPoint) throws {
        let el = try self.webView.pch_element(at: point).tryUnwrap()
        self.nextSelector = ChanController.Selector(el)
    }

    func holdPreviousSelectorStage(_ point: CGPoint) throws {
        let el = try self.webView.pch_element(at: point).tryUnwrap()
        self.prevSelector = ChanController.Selector(el)
    }

    @IBAction func holdAction(_ sender: UIGestureRecognizer) {
        if (sender.state == .began) {
            let rawPoint = sender.location(ofTouch: 0, in: self.webView)
            let f = self.view.window!.frame.size.width / self.webView.frame.size.width
            let point = CGPoint(x: rawPoint.x * f, y: (rawPoint.y - 20.0) * f)
            // TODO: FIXME

            do {
                switch (self.stage) {
                case .nextSelector:
                    try self.holdNextSelectorStage(point)
                case .previousSelector:
                    try self.holdPreviousSelectorStage(point)
                default:
                    break
                }

                if let newStage = Stage.init(rawValue: self.stage.rawValue + 1) {
                    self.stage = newStage
                    self.enteredStage(self.stage)
                }
            } catch (let e) {
                print(e)
                // TODO: show alert
            }
        }
    }

    // MARK: delegation & simple actions
    @IBAction func goAction(_ sender: Any) {
        self.webView.loadRequest(string: self.urlField.text!)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer.require(toFail: gestureRecognizer)
        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.webView.pch_inject()
        self.urlField.text = webView.request?.url?.absoluteString
    }
}
