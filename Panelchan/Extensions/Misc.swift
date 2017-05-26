//
//  Optional.swift
//  Panelchan
//
//  Created by shdwprince on 5/24/17.
//  Copyright © 2017 shdwprince. All rights reserved.
//

import Foundation

struct OptionalUnwrapError: Error {
    
}

extension Optional {
    func tryUnwrap() throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw OptionalUnwrapError()
        }
    }
}
