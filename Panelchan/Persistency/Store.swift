//
//  Store.swift
//  Panelchan
//
//  Created by shdwprince on 5/27/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation

class Series: NSObject, NSCoding {
    class Selector: NSObject, NSCoding {
        let tag, id, klass, text, title, custom: String

        init(tag: String, id: String, klass: String, text: String, title: String) {
            self.tag = tag
            self.id = id
            self.klass = klass
            self.text = text
            self.title = title
            self.custom = ""
        }

        init(custom selector: String) {
            self.tag = ""
            self.id = ""
            self.klass = ""
            self.text = ""
            self.title = ""
            self.custom = selector
        }

        init(_ dict: EmbedElement) {
            self.tag = dict["tag"]!
            self.id = dict["id"] ?? ""
            self.klass = dict["class"] ?? ""
            self.text = dict["text"] ?? ""
            self.title = dict["title"] ?? ""
            self.custom = ""
        }

        required init?(coder d: NSCoder) {
            self.tag = d.decode()
            self.id = d.decode()
            self.klass = d.decode()
            self.text = d.decode()
            self.title = d.decode()
            self.custom = d.decode()
        }

        func encode(with c: NSCoder) {
            c.encode(self.tag)
            c.encode(self.id)
            c.encode(self.klass)
            c.encode(self.text)
            c.encode(self.title)
            c.encode(self.custom)
        }
    }

    var previous, next: Selector
    var title: String
    var url: URL
    var thumbnail: URL
    var updated: Date

    init(title: String, url: URL, thumbnail: URL, previous psel: Selector, next nsel: Selector) {
        self.title = title
        self.url = url
        self.thumbnail = thumbnail
        self.next = nsel
        self.previous = psel
        self.updated = Date()
    }

    required init?(coder d: NSCoder) {
        // hooray type system!
        self.title = d.decode()
        self.url = d.decode()
        self.next = d.decode()
        self.previous = d.decode()
        self.updated = d.decode()
        self.thumbnail = d.decode()
    }

    func encode(with c: NSCoder) {
        c.encode(self.title)
        c.encode(self.url)
        c.encode(self.next)
        c.encode(self.previous)
        c.encode(self.updated)
        c.encode(self.thumbnail)
    }
}

class Store: NSObject, NSCoding {
    var series = [Series]()

    var count: Int {
        return self.series.count
    }

    static let Version = 2
    fileprivate static let FilePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!.appending("/database")
    static let shared = Store.restore()

    static func restore() -> Store {
        var instance = Store()
        print(Store.FilePath)

        if FileManager.default.fileExists(atPath: Store.FilePath) && Settings.shared.databaseVersion == Store.Version {
            instance = NSKeyedUnarchiver.unarchiveObject(withFile: Store.FilePath) as! Store
        }

        return instance
    }

    required init?(coder d: NSCoder) {
        self.series = d.decode()
    }

    override init() {
        self.series = [Series]()
        
        super.init()
    }

    func encode(with c: NSCoder) {
        c.encode(self.series)
    }

    func insert(_ series: Series) {
        self.series.append(series)
        self.series.sort { $0.updated > $1.updated }

        self.store()
    }

    func remove(at index: Int) {
        self.series.remove(at: index)
    }

    func store() {
        Settings.shared.databaseVersion = Store.Version
        if !NSKeyedArchiver.archiveRootObject(self, toFile: Store.FilePath) {
            assertionFailure("Failed to archieve root object!")
        }
    }
}
