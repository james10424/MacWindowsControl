//
//  WindowManager.swift
//  Windows
//
//  Created by James on 7/2/21.
//  Copyright © 2021 James. All rights reserved.
//
// reference: https://stackoverflow.com/questions/47480873/set-the-size-and-position-of-all-windows-on-the-screen-in-swift
// reference: https://stackoverflow.com/questions/21069066/move-other-windows-on-mac-os-x-using-accessibility-api

import Foundation
import AppKit

/**
 Representation of a window that we need
 */
struct Window: Codable {
    var name: String {
        didSet {
            // setting new window name invalidates PID
            pid = nil
        }
    }
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var windowIdx: Int? // the window number, nil = the first, -1 = last
    var pid: Int32?
    var jsonRepresentation: Window {
        // strip out pid
        return Window(
            name: name,
            x: x,
            y: y,
            width: width,
            height: height,
            windowIdx: windowIdx ?? 0
        )
    }
    
    mutating func setPID(pid: Int32?) {
        self.pid = pid
    }
    
    mutating func setSize(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
    
    mutating func setPosition(x: Int, y: Int) {
        self.x = x
        self.y = y
    }

    var description: String {
        return "\(name) (\(x), \(y)) (\(width), \(height)) \(windowIdx ?? 0)"
    }
    
    func toJSON() -> String {
        let windowIdxStr: String = windowIdx == nil ? "" : ",\n    \"windowIdx\": \(windowIdx!)"
        return """
{
    "name": "\(name)",
    "x": \(x),
    "y": \(y),
    "width": \(width),
    "height": \(height)\(windowIdxStr)
}
"""
    }
}

/**
 Get pid by window owner name
 */
func getPIDByName(name: String) -> Int32? {
    if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] {
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
 Get the window handle by pid and window index
 */
func getWindowByPID(pid: Int32, windowIdx: Int?) -> AXUIElement? {
    // get handle
    let app = AXUIElementCreateApplication(pid)
    var value: AnyObject?
    let result = AXUIElementCopyAttributeValue(
        app,
        kAXWindowsAttribute as CFString,
        &value
    ) as AXError
    if result.rawValue != 0 {
        if result == .apiDisabled {
            print("Assistive access disabled for \(pid)")
        } else {
            print("Error getting window: \(result.rawValue)")
        }
        return nil
    }
    
    // get window by window index
    guard
        let windows = value as? [AXUIElement],
        windows.count > 0,
        let wid = windowIdx == nil ? 0 : (windowIdx == -1 ? windows.count - 1 : windowIdx),
        wid < windows.count,
        wid >= 0
    else {
        print("Failed to get window \(windowIdx ?? 0) for \(pid)")
        return nil
    }
    let window = windows[wid]
    return window
}

/**
 Sets the window size and position by pid
 */
func setByPID(pid: Int32, windowIdx: Int?, x: Int, y: Int, width: Int, height: Int) -> Bool {
    guard let window = getWindowByPID(pid: pid, windowIdx: windowIdx) else {return false}

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

/**
 Set window attributes by Window object
 */
func setByWindow(window: Window) -> Bool {
    return setByPID(
        pid: window.pid!,
        windowIdx: window.windowIdx,
        x: window.x,
        y: window.y,
        width: window.width,
        height: window.height
    )
}

/**
 Makes sure that each window object in the list has a pid and tries to get one if not
 then passes the window to a handler, so when the handler receives a window,
 it can assume that the window has a pid
 */
func ensurePID(windows: inout [Window], filter: IndexSet?, operation: (inout Window) -> Bool) {
    var errors: [String] = []
    let indicies = ((filter?.count ?? 0) > 0) ? filter! : IndexSet(windows.indices)
    for i in indicies {
        if (windows[i].pid == nil) {
            print("\(windows[i].name) pid not cached, getting its pid")
            windows[i].setPID(pid: getPIDByName(name: windows[i].name))
            if windows[i].pid == nil {
                // stil can't set pid
                errors.append("\(windows[i].name) can't get pid")
                continue
            }
        }
        else {
            print("\(windows[i].name) pid cache hit: \(windows[i].pid!)")
        }

        if !operation(&windows[i]) {
            // maybe pid changed, do it again
            print("\(windows[i].name) pid cache expired, trying to renew it")
            windows[i].setPID(pid: getPIDByName(name: windows[i].name))
            
            if windows[i].pid == nil || !operation(&windows[i]) {
                errors.append("Can't perform operation on window for \(windows[i].name)") // give up
            }
        }
    }
    if !errors.isEmpty {
        notification(
            title: "Some operations weren't successful",
            text: errors.joined(separator: "\n")
        )
    }
}

/**
 Set the window attribute given a list of windows, might need to change the refernence
 */
func setWindows(windows: inout [Window], filter: IndexSet? = nil) {
    ensurePID(windows: &windows, filter: filter) { (window: inout Window) in
        setByWindow(window: window)
    }
}

/**
 Gets and fills info given a window, overwrites the attributes
 */
func getInfoByPID(window: inout Window) -> Bool {
    guard window.pid != nil else {return false}
    guard let processWindow = getWindowByPID(pid: window.pid!, windowIdx: window.windowIdx) else {
        return false
    }
    var positionRef: CFTypeRef?
    var sizeRef: CFTypeRef?
    let positionError = AXUIElementCopyAttributeValue(processWindow, kAXPositionAttribute as CFString, &positionRef)
    let sizeError = AXUIElementCopyAttributeValue(processWindow, kAXSizeAttribute as CFString, &sizeRef)
    guard
        positionError.rawValue == 0,
        sizeError.rawValue == 0
    else {
        print("can't get info for \(window.name)")
        return false
    }
    var position: CGPoint = CGPoint()
    var size: CGSize = CGSize()
    AXValueGetValue(positionRef as! AXValue, AXValueType(rawValue: kAXValueCGPointType)!, &position)
    AXValueGetValue(sizeRef as! AXValue, AXValueType(rawValue: kAXValueCGSizeType)!, &size)

    window.setPosition(x: Int(position.x), y: Int(position.y))
    window.setSize(width: Int(size.width), height: Int(size.height))

    return true
}

/**
 Saves the current config in memory, also ask user if they want to save it to a file
 */
func saveWindows(windows: inout [Window], filter: IndexSet? = nil) {
    ensurePID(windows: &windows, filter: filter) { (window: inout Window) in
        getInfoByPID(window: &window)
    }
}

let DEFAULT_WINDOW = Window(
    name: "New Window",
    x: 0, y: 0,
    width: 0, height: 0,
    windowIdx: 0
)
