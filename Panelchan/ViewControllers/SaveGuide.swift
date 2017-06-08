//
//  SaveGuideViewController.swift
//  Panelchan
//
//  Created by shdwprince on 5/23/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class SaveGuideViewController: UIViewController {
    enum Stage {
        case initial
        case nextSelector
        case previousSelector
        case finished(controller: ChanController)
        case editing(controller: ChanController)
    }

    enum Segues: String {
        case infoPanel = "infoPanel"
    }

    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var urlField: UITextField!
    // no release?
    @IBOutlet weak var webViewActivityView: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
    var infoPanelController: SaveGuideInfoPanelViewController!

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
    
    var nextSelector: Series.Selector?
    var prevSelector: Series.Selector?

    var series: Series?
    var chanController: ChanController?
}

// MARK: views
extension SaveGuideViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardStateChanged(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)

        self.webView.addDelegate(self)
        self.webView.scrollView.contentInset = UIEdgeInsetsMake(72, 0, 128, 0)

        if let series = self.series {
            self.webView.loadRequest(url: series.url)
            self.stage = .editing(controller: ChanController(webView: self.webView, series: series))
        }
    }

    func keyboardStateChanged(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        UIView.animate(withDuration: 0.1) {
            self.bottomConstraint.constant = keyboardFrame.origin.y >= UIScreen.main.bounds.size.height ? 0 : keyboardFrame.size.height
        }
    }
}

// MARK: stages
extension SaveGuideViewController {
    func holdNextSelectorStage(_ point: CGPoint) throws {
        let el = try self.webView.pch_element(at: point).tryUnwrap()
        self.nextSelector = Series.Selector(el)
    }

    func holdPreviousSelectorStage(_ point: CGPoint) throws {
        let el = try self.webView.pch_element(at: point).tryUnwrap()
        self.prevSelector = Series.Selector(el)
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
                    self.series = try Series(title: self.webView.pch_title(),
                                             url: self.webView.request!.url!,
                                             thumbnail: self.webView.pch_images(bigger: ChanController.MinSize).first.tryUnwrap(),
                                             previous: self.prevSelector!,
                                             next: self.nextSelector!)
                    
                    self.stage = .finished(controller: ChanController(
                        webView: self.webView,
                        series: self.series!))
                default:
                    break
                }
            } catch (let e) {
                print(e)
            }
        }
    }
}

// MARK: delegation
extension SaveGuideViewController: UITextFieldDelegate, UIGestureRecognizerDelegate, UIWebViewDelegate {
    func enteredStage(_ stage: Stage) {
        self.infoPanelController.enteredStage(stage)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.infoPanel.rawValue {
            self.infoPanelController = segue.destination as! SaveGuideInfoPanelViewController
            self.infoPanelController.webView = self.webView
            self.infoPanelController.chanController = self.chanController
        }

        super.prepare(for: segue, sender: sender)
    }

    func webViewDidStartLoad(_ webView: UIWebView) {
        self.webViewActivityView.startAnimating()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.webViewActivityView.stopAnimating()
        
        self.webView.pch_inject()
        self.urlField.text = webView.request?.url?.absoluteString
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        otherGestureRecognizer.require(toFail: gestureRecognizer)
        return true
    }
}

// MARK: actions
extension SaveGuideViewController {

    @IBAction func resetAction(_ sender: Any) {
        self.chanController = nil
        self.stage = .nextSelector
    }

    @IBAction func saveAction(_ sender: Any) {
        switch self.stage {
        case .finished(controller: _):
            Store.shared.insert(self.series!)
        default:
            break
        }

        self.dismiss(animated: true, completion: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.goAction(true)
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func goAction(_ sender: Any) {
        if var string = self.urlField.text {
            if string.contains(".") && !string.contains(" ") && !string.hasPrefix("http") {
                string = "http://".appending(string)
            } else {
                string = "http://google.com/search?q=".appending(string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
            }

            self.webView.loadRequest(string: string)
            self.stage = .nextSelector
            self.webViewActivityView.startAnimating()
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.webView.goBack()
    }
    
    @IBAction func closeAction(_ sender: Any) {
        let alert = UIAlertController(title: "Are you sure?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .destructive, handler: { (_) in
            alert.dismiss(animated: true, completion: {
                self.dismiss(animated: true, completion: nil)
            })
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (_) in
            alert.dismiss(animated: true, completion: nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }

}
