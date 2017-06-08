//
//  UICollectionViewCell.swift
//  Panelchan
//
//  Created by shdwprince on 6/5/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import UIKit

var UICollectionViewCellReusableIdentifiers: UInt8 = 4
extension UICollectionViewCell {
    fileprivate var __simple_identifier: IndexPath {
        get {
            return objc_getAssociatedObject(self, &UICollectionViewCellReusableIdentifiers) as! IndexPath
        }

        set {
            objc_setAssociatedObject(self, &UICollectionViewCellReusableIdentifiers, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func _simple_register(for path: IndexPath) {
        self.__simple_identifier = path
    }

    func _simple_check(for path: IndexPath) -> Bool {
        return self.__simple_identifier == path
    }
}

protocol SimpleUICollectionViewBindable {
    func _simple_set<T>(_ value: T)
    func _simple_nil()
}

extension UILabel: SimpleUICollectionViewBindable {
    func _simple_set<T>(_ value: T) {
        self.text = value as! String
    }

    func _simple_nil() {
        self.text = nil
    }
}

extension UIImageView: SimpleUICollectionViewBindable {
    func _simple_set<T>(_ value: T) {
        self.image = value as! UIImage
    }

    func _simple_nil() {
        self.image = nil
    }
}


extension UICollectionViewCell {
    func _simple_set<T>(_ value: T?, tag: Int) {
        (self.viewWithTag(tag) as! SimpleUICollectionViewBindable)._simple_set(value)
    }

    func _simple_nil(tag: Int) {
        (self.viewWithTag(tag) as! SimpleUICollectionViewBindable)._simple_nil()
    }

}
