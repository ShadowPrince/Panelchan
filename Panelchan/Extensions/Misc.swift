//
//  Optional.swift
//  Panelchan
//
//  Created by shdwprince on 5/24/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation
import UIKit

struct OptionalUnwrapError: Error { }

extension Optional {
    func tryUnwrap() throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw OptionalUnwrapError()
        }
    }
}

extension UIResponder {
    func performChainAction(_ sel: Selector, sender: Any) {
        var responder = self
        while let next = responder.next {
            if responder.responds(to: sel) {
                responder.perform(sel, with: sender)
                return
            }

            responder = next
        }
    }
}

extension NSCoder {
    func decode<T>() -> T {
        return self.decodeObject() as! T
    }
}
