//
//  Settings.swift
//  Panelchan
//
//  Created by shdwprince on 6/6/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation

class Settings {
    fileprivate enum Paths: String {
        case updateTitle = "updateTitle"
        case updateThumbnail = "updateThumbnail"
        case controlType = "controlType"
        case userManualChecks = "userManualChecks"
        case databaseVersion = "databaseVersion"
    }

    fileprivate static let Defaults: [Paths: Any] = [Paths.updateTitle: false,
                                                     Paths.updateThumbnail: true,
                                                     Paths.userManualChecks: [:],
                                                     Paths.controlType: 1,
                                                     Paths.databaseVersion: Store.Version, ]

    static let shared = Settings()

    fileprivate func get<T>(_ path: Paths) -> T {
        return UserDefaults.standard.value(at: path.rawValue) ?? Settings.Defaults[path] as! T
    }

    fileprivate func set<T>(_ path: Paths, value: T) {
        UserDefaults.standard.set(value, forKey: path.rawValue)
    }
}

// MARK: vars
extension Settings {
    var updateTitle: Bool {
        get { return self.get(.updateTitle) }
        set { self.set(.updateTitle, value: newValue) }
    }

    var updateThumbnail: Bool {
        get { return self.get(.updateThumbnail) }
        set { self.set(.updateThumbnail, value: newValue) }
    }

    var controlType: Int {
        get { return self.get(.controlType) }
        set { self.set(.controlType, value: newValue) }
    }

    var userManualChecks: [String: Bool] {
        get { return self.get(.userManualChecks) }
        set { self.set(.userManualChecks, value: newValue) }
    }

    var databaseVersion: Int {
        get { return self.get(.databaseVersion) }
        set { self.set(.databaseVersion, value: newValue) }
    }
}
