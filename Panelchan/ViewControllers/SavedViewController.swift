//
//  SavedViewController.swift
//  Panelchan
//
//  Created by shdwprince on 5/23/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

class SavedViewController: UIViewController {
    enum Segues: String {
        case saveGuide = "saveGuide"
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.performSegue(withIdentifier: Segues.saveGuide.rawValue, sender: nil)
    }
}
