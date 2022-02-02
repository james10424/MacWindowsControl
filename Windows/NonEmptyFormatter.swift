//
//  NonEmptyFormatter.swift
//  Windows
//
//  Created by James on 2/1/22.
//  Copyright © 2022 James. All rights reserved.
//

import Foundation

class NonEmptyFormatter: Formatter {
    
    override func string(for obj: Any?) -> String? {
        return obj as? String
    }

    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        obj?.pointee = string as AnyObject
        return true
    }
    
    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        return !partialString.isEmpty
    }
}
