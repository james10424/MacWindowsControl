//
//  AppDelegate.swift
//  Windows
//
//  Created by James on 7/1/21.
//  Copyright © 2021 James. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var windows = [
        Window(name: "Discord", x: 2561, y: -478, width: 1078, height: 659, windowIdx: nil),
        Window(name: "Mail", x: 2560, y: 182, width: 1079, height: 692, windowIdx: nil),
        Window(name: "iTunes", x: 3159, y: 1057, width: 448, height: 448, windowIdx: 0),
        Window(name: "iTunes", x: 2560, y: 875, width: 1080, height: 566, windowIdx: 1),
    ]

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem.button {
            button.title = title
            button.action = #selector(self.click(sender:))
            button.target = self
            button.sendAction(on: [.leftMouseUp])
        }
    }
    
    @objc func click(sender: NSStatusItem) {
        setWindows(windows: &windows)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

