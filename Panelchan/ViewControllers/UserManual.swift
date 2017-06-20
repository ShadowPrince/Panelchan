//
//  UserManual.swift
//  Panelchan
//
//  Created by shdwprince on 6/20/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import UIKit

class UserManualViewController: UIViewController {
    enum UserScreen: String {
        case saved = "saved"
        case saveGuide = "saveGuide"
        case reader = "reader"
    }

    static let identifier = "userManual"
    static func showIfNeeded(at ctrl: UIViewController, of screen: UserScreen) {
        if Settings.shared.userManualChecks[screen.rawValue] != true {
            let manual = ctrl.storyboard!.instantiateViewController(withIdentifier: UserManualViewController.identifier) as! UserManualViewController
            
            manual.modalPresentationStyle = .popover
            manual.popoverPresentationController?.delegate = manual
            manual.popoverPresentationController?.sourceView = ctrl.view
            manual.popoverPresentationController?.sourceRect = CGRect(x: UIScreen.main.bounds.width, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
            manual.userScreen = screen

            ctrl.present(manual, animated: true, completion: nil)
        }
    }

    @IBOutlet weak var webView: UIWebView!

    var canScroll = false
    var canClose = false
    var userScreen: UserScreen!
}

extension UserManualViewController: UIWebViewDelegate, UIScrollViewDelegate {
    override func viewDidLoad() {
        self.webView.scrollView.delegate = self
        self.webView.delegate = self

        self.webView.loadRequest(string: "https://raw.githubusercontent.com/ShadowPrince/Panelchan/master/UserManual/\(self.userScreen.rawValue).html")
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.canScroll = true
        self.scrollViewDidScroll(webView.scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.canScroll && scrollView.contentOffset.y + scrollView.frame.height >= scrollView.contentSize.height - 30 {
            Settings.shared.userManualChecks[self.userScreen.rawValue] = true
            self.canClose = true
        }
    }
}

extension UserManualViewController: UIPopoverPresentationControllerDelegate {
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return self.canClose
    }
}
