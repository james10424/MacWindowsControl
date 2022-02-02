//
//  NumberFormatter.swift
//  Windows
//
//  Created by James on 2/1/22.
//  Copyright © 2022 James. All rights reserved.
//

import Foundation
import Cocoa

class NoSeparatorNumberFormatter: NumberFormatter {

    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        if partialString.isEmpty {
            return true
        }
        return Int(partialString) != nil
    }
}
