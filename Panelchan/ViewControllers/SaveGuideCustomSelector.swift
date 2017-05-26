//
//  SaveGuideCustomSelectorViewController.swift
//  Panelchan
//
//  Created by shdwprince on 5/26/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class SaveGuideCustomSelectorViewController: UIViewController {
    @IBOutlet weak var selectorField: UITextField!
    @IBOutlet weak var resultsView: UITextView!

    enum Direction {
        case next
        case prev
    }

    var webView: UIWebView!
    var chanController: ChanController?
    var direction: SaveGuideCustomSelectorViewController.Direction!

    override func viewDidLoad() {
        switch self.direction! {
        case .next:
            self.selectorField.text = self.chanController?.nextSelector.custom
        case .prev:
            self.selectorField.text = self.chanController?.previousSelector.custom
        }
    }
    
    @IBAction func applyAction(_ sender: Any) {
        switch self.direction! {
        case .next:
            self.chanController?.nextSelector = ChanController.Selector(custom: self.selectorField.text!)
        case .prev:
            self.chanController?.previousSelector = ChanController.Selector(custom: self.selectorField.text!)
        }
    }
}
