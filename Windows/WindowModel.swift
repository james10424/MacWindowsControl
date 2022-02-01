//
//  WindowModel.swift
//  Windows
//
//  Created by James on 1/31/22.
//  Copyright © 2022 James. All rights reserved.
//

import Foundation

class WindowViewModel: NSObject {
    var windows: [Window]!
    
    init(_ windows: [Window]) {
        super.init()
        self.windows = windows
    }
}
