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
    var windowManager: WindowManager = WindowManager()

    lazy var ui: NSWindowController? = {
        NSStoryboard(
            name: "Main",
            bundle: nil
        ).instantiateController(withIdentifier: "ui") as? NSWindowController
    }()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusBarItem.button {
            button.title = title
            button.action = #selector(self.click(sender:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        initWindow(selectFile: false)
        checkAccessibility()
    }
    
    func initWindow(selectFile: Bool) {
        guard let configs = readConfig(selectFile: selectFile) else {
            return
        }
        self.windowManager.updateWindowConfig(configs: configs)
    }
    
    func startUI() {
        self.ui?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func click(sender: NSStatusItem) {
        guard let e = NSApp.currentEvent else {return}
        switch e.type {
        case .leftMouseUp:
            for i in 0...self.windowManager.windows.count - 1 {
                self.windowManager.setWindow(i: i)
            }
            break
        case .rightMouseUp:
            self.startUI()
            break
        case .otherMouseUp:
            print("other mouse")
            break
        default:
            print("no function for this key")
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

