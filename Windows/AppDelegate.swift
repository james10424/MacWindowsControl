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
    var windows: [Window]?

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
        guard let ws = readConfig() else {
            return
        }
        windows = fileToWindows(content: ws)
    }
    
    @objc func click(sender: NSStatusItem) {
        setWindows(windows: &windows!)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

