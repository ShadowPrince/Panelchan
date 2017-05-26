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
    enum Direction {
        case next
        case prev
    }

    enum Mode {
        case test
        case apply
    }

    @IBOutlet weak var selectorField: UITextField!
    @IBOutlet weak var resultsView: UITextView!
    @IBOutlet weak var applyButton: UIButton!

    var webView: UIWebView!
    var chanController: ChanController?
    var direction: SaveGuideCustomSelectorViewController.Direction!
    fileprivate var _mode = Mode.test
    var mode: Mode {
        set {
            self._mode = newValue
            self.enteredMode(newValue)
        }
        get {
            return self._mode
        }
    }
}

// MARK: views
extension SaveGuideCustomSelectorViewController {
    func enteredMode(_ mode: Mode) {
        switch mode {
        case .test:
            self.applyButton.setTitle("Test", for: .normal)
        case .apply:
            self.applyButton.setTitle("Apply", for: .normal)
        }
    }
    
    override func viewDidLoad() {
        self.mode = .test
        self.resultsView.text = ""

        switch self.direction! {
        case .next:
            self.selectorField.text = self.chanController?.nextSelector.custom
        case .prev:
            self.selectorField.text = self.chanController?.previousSelector.custom
        }
    }
}

// MARK: actions
extension SaveGuideCustomSelectorViewController: UITextFieldDelegate {
    @IBAction func applyAction(_ sender: Any) {
        switch self.mode {
        case .test:
            self.resultsView.text = "Number of elements matching: \(self.webView.pch_count(selector: self.selectorField.text!))"
            self.mode = .apply
        case .apply:
            switch self.direction! {
            case .next:
                self.chanController?.nextSelector = ChanController.Selector(custom: self.selectorField.text!)
            case .prev:
                self.chanController?.previousSelector = ChanController.Selector(custom: self.selectorField.text!)
            }
        }
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.mode = .test
        return true
    }
}
