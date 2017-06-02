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
        let tag, id, klass, custom: String

        init(tag: String, id: String, klass: String) {
            self.tag = tag
            self.id = id
            self.klass = klass
            self.custom = ""
        }

        init(custom selector: String) {
            self.tag = ""
            self.id = ""
            self.klass = ""
            self.custom = selector
        }

        init(_ dict: EmbedElement) {
            self.tag = dict["tag"]!
            self.id = dict["id"]!
            self.klass = dict["class"]!
            self.custom = ""
        }

        required init?(coder d: NSCoder) {
            self.tag = d.decode()
            self.id = d.decode()
            self.klass = d.decode()
            self.custom = d.decode()
        }

        func encode(with c: NSCoder) {
            c.encode(self.tag)
            c.encode(self.id)
            c.encode(self.klass)
            c.encode(self.custom)
        }
    }

    var previous, next: Selector
    var title: String
    var url: URL
    var thumbnail: URL?
    var updated: Date

    init(title: String, url: URL, thumbnail: URL?, previous psel: Selector, next nsel: Selector) {
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

        if let object = d.decodeObject() {
            self.thumbnail = object as? URL
        }
    }

    func encode(with c: NSCoder) {
        c.encode(self.title)
        c.encode(self.url)
        c.encode(self.next)
        c.encode(self.previous)
        c.encode(self.updated)

        if let url = self.thumbnail {
            c.encode(url)
        }
    }
}

class Store: NSObject, NSCoding {
    var series = [Series]()

    var count: Int {
        return self.series.count
    }

    fileprivate static let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!.appending("/database")
    static let shared = Store.restore()

    static func restore() -> Store {
        var instance = Store()
        print(Store.filePath)

        if FileManager.default.fileExists(atPath: Store.filePath) {
            instance = NSKeyedUnarchiver.unarchiveObject(withFile: Store.filePath) as! Store
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
        if !NSKeyedArchiver.archiveRootObject(self, toFile: Store.filePath) {
            assertionFailure("Failed to archieve root object!")
        }
    }
}
