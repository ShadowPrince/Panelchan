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
    @IBOutlet weak var guideText: UITextView!

    func enteredStage(_ stage: SaveGuideViewController.Stage) {
        switch stage {
        case .initial:
            self.guideText.text = "Loading page..."
        case .nextSelector:
            self.guideText.text = "Step 1/2: Press and hold on button which opens new page (or new set/chapter)"
        case .previousSelector:
            self.guideText.text = "Step 2/2: Press and hold on button which opens previous page (or, again, previous set/chapter)"
        case .finished(let controller):
            self.guideText.text = "Setup finished. You can test the settings using the buttons to the right"
            self.chanController = controller
            self.chanController?.delegate = self
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
    
    @IBAction func prevPageAction(_ sender: Any) {
        self.chanController?.requestPrev()
    }

    @IBAction func nextPageAction(_ sender: Any) {
        self.chanController?.requestNext()
    }

    func chanController(_ controller: ChanController, gotImage url: String) {
        print("got image \(url)")
        ImageProxyCache.sharedProxy.waitForImageData(for: url) { (data) in
            if let data = data {
                self.imgView.image = UIImage(data: data)
            }
        }
    }

    func chanController(_ controller: ChanController, didFailWith error: Error) {
        print(error)
    }
}
