//
//  SaveGuideInfoPanel.swift
//  Panelchan
//
//  Created by shdwprince on 5/26/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class SaveGuideInfoPanelViewController: UIViewController, ChanControllerDelegate {
    enum Segues: String {
        case customPrevSelector = "customPrevSelector"
        case customNextSelector = "customNextSelector"
    }

    var webView: UIWebView!
    var chanController: ChanController?
    
    @IBOutlet weak var imgView: UIImageView!
    @IBOutlet weak var prevButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var guideText: UILabel!
    @IBOutlet weak var guideProgress: UILabel!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var saveButton: UIButton!

    override func viewDidLoad() {
        self.guideText.text = "Waiting ..."
        self.guideProgress.text = ""
        self.nameField.text = "----"
        self.domainLabel.text = "----"

        self.saveButton.isEnabled = false
        self.controls(locked: true)
    }

    func controls(locked l: Bool) {
        self.nextButton.isEnabled = !l
        self.prevButton.isEnabled = !l
        self.saveButton.isEnabled = !l
    }

    func enteredStage(_ stage: SaveGuideViewController.Stage) {
        // talking about one liners
        let progressText = { (0 ..< $0).reduce("") { acc, _ in acc.appending("✓")} }

        switch stage {
        case .initial:
            self.guideText.text = "Loading page ..."
            self.guideProgress.text = progressText(0)
        case .nextSelector:
            self.guideText.text = "Step 1/3: Press and hold button which opens new page"
            self.guideProgress.text = progressText(1)
        case .previousSelector:
            self.guideText.text = "Step 2/3: Press and hold button which opens previous page"
            self.guideProgress.text = progressText(2)
        case .finished(let controller), .editing(controller: let controller):
            self.guideText.text = "Step 2/3: Review name & settings"
            self.guideProgress.text = progressText(3)
            
            self.chanController = controller
            self.chanController?.delegate = self
            self.chanController?.requestCurrent()
            
            self.nameField.text = self.chanController?.series.title
            self.domainLabel.text = self.chanController?.series.url.host

            self.controls(locked: false)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segues.customNextSelector.rawValue || segue.identifier == Segues.customPrevSelector.rawValue {
            let ctrl = segue.destination as! SaveGuideCustomSelectorViewController
            ctrl.webView = self.webView
            ctrl.chanController = self.chanController

            if segue.identifier == Segues.customNextSelector.rawValue {
                ctrl.direction = .next
            } else {
                ctrl.direction = .prev
            }
        }

        super.prepare(for: segue, sender: sender)
    }
}

// MARK: actions
extension SaveGuideInfoPanelViewController: UITextFieldDelegate {
    @IBAction func prevPageAction(_ sender: Any) {
        self.chanController?.requestPrev()
        self.controls(locked: true)
    }

    @IBAction func nextPageAction(_ sender: Any) {
        self.chanController?.requestNext()
        self.controls(locked: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.chanController?.series.title = textField.text!

        textField.resignFirstResponder()
        return true
    }
}

// MARK: chan ctrl
extension SaveGuideInfoPanelViewController {
    func chanController(_ controller: ChanController, gotImage url: URL) {
        print("got image \(url)")
        ImageResolver.shared.waitForImageData(for: url) { (image) in
            if let image = image {
                self.imgView.image = image
            } else {
                self.present(UIAlertController(title: "Error", message: "Failed to load image", preferredStyle: .alert), animated: true, completion: nil)
            }

            self.controls(locked: false)
        }
    }

    func chanController(_ controller: ChanController, didFailWith error: ChanController.Errors) {
        self.present(UIAlertController.init(title: "Error", message: error.stringValue, preferredStyle: .alert), animated: true, completion: nil)
        self.controls(locked: false)
    }
}
