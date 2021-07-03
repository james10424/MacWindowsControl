//
//  WindowManager.swift
//  Windows
//
//  Created by James on 7/2/21.
//  Copyright © 2021 James. All rights reserved.
//

import Foundation
import AppKit

struct Window {
    let name: String
    let x: Int
    let y: Int
    let width: Int
    let height: Int
    var windowIdx: Int? // the window number, nil = the first
    var pid: Int32?
    
    mutating func setPID(pid: Int32?) {
        self.pid = pid
    }

    var description: String {
        return "\(name) (\(x), \(y)) (\(width), \(height)) \(windowIdx ?? 0)"
    }
}

func notification(title: String, text: String) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = text
    alert.alertStyle = .warning
    alert.addButton(withTitle: "OK")
    alert.runModal()
}

func askForFile(defaultFile: String?) -> String? {
    let dialog = NSOpenPanel()
    dialog.title = "Choose a window config file (json)"
    dialog.showsResizeIndicator = true
    dialog.showsHiddenFiles = false
    dialog.allowsMultipleSelection = false
    dialog.canChooseDirectories = false
    dialog.allowedFileTypes = ["json"]
    if defaultFile != nil {
        dialog.directoryURL = NSURL.fileURL(withPath: defaultFile!)
    }
    if dialog.runModal() == .OK {
        return dialog.url?.path
    }
    return nil
}

/**
 Get pids by name
 */
func getPIDByName(name: String) -> Int32? {
    if let windowList = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: AnyObject]] {

        for window in windowList {
            if  let windowOwner = window[kCGWindowOwnerName as String] as? String,
                windowOwner == name,
                let pid = window[kCGWindowOwnerPID as String] as? Int32 {
                return pid
            }
        }
    }

    return nil
}

/**
 Sets the window size and position by pid
 */
func setByPID(pid: Int32, windowIdx: Int?, x: Int, y: Int, width: Int, height: Int) -> Bool {
    // get handle
    let app = AXUIElementCreateApplication(pid)
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(
        app,
        kAXWindowsAttribute as CFString,
        &value
    ) as AXError
    if result.rawValue != 0 {
        print("Error: \(result.rawValue)")
        return false
    }
    
    // get window by window index
    let wid = windowIdx ?? 0
    guard
        let windows = value as? [AXUIElement],
        windows.count > 0,
        wid >= 0,
        wid < windows.count
    else {
        print("Failed to get window for \(pid)")
        return false
    }

    let window = windows[wid]
    // got window, set attr
    var point = CGPoint(x: x, y: y)
    let position = AXValueCreate(
        AXValueType(rawValue: kAXValueCGPointType)!,
        &point
    )!
    AXUIElementSetAttributeValue(
        window,
        kAXPositionAttribute as CFString,
        position
    )
    
    var rect = CGSize(width: width, height: height)
    let size = AXValueCreate(
        AXValueType(rawValue: kAXValueCGSizeType)!,
        &rect
    )!
    AXUIElementSetAttributeValue(
        window,
        kAXSizeAttribute as CFString,
        size
    )
    return true
}

func setByWindow(window: Window) -> Bool {
    return setByPID(pid: window.pid!, windowIdx: window.windowIdx, x: window.x, y: window.y, width: window.width, height: window.height)
}

func setWindows(windows: inout [Window]) {
    var errors: [String] = []
    for (i, _) in windows.enumerated() {
        if (windows[i].pid == nil) {
            print("\(windows[i].name) pid not cached, getting its pid")
            windows[i].setPID(pid: getPIDByName(name: windows[i].name))
            if windows[i].pid == nil {
                // stil can't set pid
                errors.append("\(windows[i]) can't get pid")
                continue
            }
        }
        else {
            print("\(windows[i].name) pid cache hit")
        }

        if !setByWindow(window: windows[i]) {
            // maybe pid changed, do it again
            print("\(windows[i]) pid cache expired, trying to renew it")
            windows[i].setPID(pid: getPIDByName(name: windows[i].name))
            if !setByWindow(window: windows[i]) {
                errors.append("Can't set window for \(windows[i].name)") // give up
            }
        }
    }
    if !errors.isEmpty {
        notification(title: "Some operations weren't successful", text: errors.joined(separator: "\n"))
    }
}
