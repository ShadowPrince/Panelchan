//
//  SettingsController.swift
//  Panelchan
//
//  Created by shdwprince on 6/6/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var updateThumbnailSwitch: UISwitch!
    @IBOutlet weak var updateTitleSwitch: UISwitch!
    @IBOutlet weak var controlTypeControl: UISegmentedControl!

    override func viewDidLoad() {
        self.updateThumbnailSwitch.isOn = Settings.shared.updateThumbnail
        self.updateTitleSwitch.isOn = Settings.shared.updateTitle
        self.controlTypeControl.selectedSegmentIndex = Settings.shared.controlType
    }

    override func viewDidDisappear(_ animated: Bool) {
        Settings.shared.updateThumbnail = self.updateThumbnailSwitch.isOn
        Settings.shared.updateTitle = self.updateTitleSwitch.isOn
        Settings.shared.controlType = self.controlTypeControl.selectedSegmentIndex
    }
    
    @IBAction func resetUserManualPopupsAction(_ sender: Any) {
        Settings.shared.userManualChecks = [:]
    }
}
