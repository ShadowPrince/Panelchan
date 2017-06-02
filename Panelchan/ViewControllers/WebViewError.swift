//
//  WebViewError.swift
//  Panelchan
//
//  Created by shdwprince on 6/2/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import UIKit

class WebViewErrorViewController: UIViewController {
    var webView: UIWebView!
    
    @IBOutlet weak var containerView: UIView!

}

// MARK: view
extension WebViewErrorViewController {
    override func viewDidLoad() {
        self.containerView.addSubview(self.webView)
        self.webView.frame = self.containerView.frame
    }
}

// MARK: actions
extension WebViewErrorViewController {
    @IBAction func closeAction(_ sender: Any) {
        self.webView.removeFromSuperview()
        self.dismiss(animated: true, completion: nil)
    }
}
