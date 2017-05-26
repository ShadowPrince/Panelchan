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
    enum Stage {
        case initial
        case nextSelector
        case previousSelector
        case finished(controller: ChanController)
    }

    enum Segues: String {
        case infoPanel = "infoPanel"
    }

    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var webView: UIWebView!

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

    var infoPanelController: SaveGuideInfoPanelViewController!
    
    var chanController: ChanController?
    var nextSelector: ChanController.Selector?
    var prevSelector: ChanController.Selector?
}

// MARK: views
extension SaveGuideViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.addDelegate(self)
        self.webView.scrollView.contentInset = UIEdgeInsetsMake(72, 0, 128, 0)
    }
}

// MARK: stages
extension SaveGuideViewController {
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
            let point = CGPoint(x: rawPoint.x * f, y: (rawPoint.y - self.webView.scrollView.contentInset.top) * f)

            do {
                switch (self.stage) {
                case .nextSelector:
                    try self.holdNextSelectorStage(point)

                    self.stage = .previousSelector
                case .previousSelector:
                    try self.holdPreviousSelectorStage(point)

                    self.stage = .finished(controller: ChanController(
                        webView: self.webView,
                        previous: self.prevSelector!,
                        next: self.nextSelector!))
                default:
                    break
                }
            } catch (let e) {
                print(e)
            }
        }
    }
}

// MARK: delegation & actions
extension SaveGuideViewController {
    func enteredStage(_ stage: Stage) {
        self.infoPanelController.enteredStage(stage)
    }

    @IBAction func resetAction(_ sender: Any) {
        self.chanController = nil
        self.stage = .nextSelector
    }

    @IBAction func saveAction(_ sender: Any) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.infoPanel.rawValue {
            self.infoPanelController = segue.destination as! SaveGuideInfoPanelViewController
            self.infoPanelController.webView = self.webView
            self.infoPanelController.chanController = self.chanController
        }

        super.prepare(for: segue, sender: sender)
    }
    
    @IBAction func goAction(_ sender: Any) {
        self.webView.loadRequest(string: self.urlField.text!)
        self.stage = .nextSelector
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.webView.goBack()
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
