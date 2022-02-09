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
struct WindowConfig: Codable {
    var processName: String
    /**
        Optional, to pick lock in a window with this name in the title bar.
        If `nil`, then will use the `windowIdx` to index into multiple windows of this process
     */
    var windowName: String? = nil
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    /**
        The window index, 1 = top, if there are multiple windows with the same name
     */
    var windowIdx: Int

    var jsonRepresentation: WindowConfig {
        // strip out pid and windowID
        return WindowConfig(
            processName: processName,
            windowName: windowName,
            x: x,
            y: y,
            width: width,
            height: height,
            windowIdx: windowIdx
        )
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
        return "\(processName) \(windowName ?? "") (\(x), \(y)) (\(width), \(height)) \(windowIdx)"
    }
}

struct Window {
    var config: WindowConfig
    var windowRef: AXUIElement?
    
    init(config: WindowConfig) {
        self.config = config
    }
}

/**
 GeWindowConfigby window owner name
 */
func getPIDByName(processName: String) -> Int32? {
    if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: AnyObject]] {
        for window in windowList {
            if  let _processName = window[kCGWindowOwnerName as String] as? String,
                let pid = window[kCGWindowOwnerPID as String] as? Int32,
                // check for process name
                _processName == processName
            {
                return pid
            }
        }
    }
    print("Can't find PID for \(processName)")
    return nil
}

func getWindowTitle(_ window: AXUIElement) -> String? {
    var titleRef: AnyObject?
    let err = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
    guard err == .success else {
        return nil
    }
    return titleRef as? String
}

/**
 Get the window `AXUIElement` by pid, window name and window index
 */
func getWindowByPID(pid: Int32, windowName: String?, windowIdx: Int) -> AXUIElement? {
    // get handle
    let app = AXUIElementCreateApplication(pid)
    var value: AnyObject?
    let err = AXUIElementCopyAttributeValue(
        app,
        kAXWindowsAttribute as CFString,
        &value
    ) as AXError

    guard err == .success else {
        if err == .apiDisabled {
            print("Assistive access disabled for \(pid)")
        } else {
            print("Error getting window: \(err.rawValue)")
        }
        return nil
    }
    
    // filter window with this name
    guard
        let windows = value as? [AXUIElement],
        windows.count > 0
    else {
        print("Failed to get window \(windowIdx) for \(pid)")
        return nil
    }

    if windowName == nil {
        // no window name to filter
        if windowIdx < windows.count && windowIdx >= 0 {
            return windows[windowIdx]
        }
        return nil
    }

    // do name filtering
    var filteredWindows: [AXUIElement] = []
    for window in windows {
        let _windowName = getWindowTitle(window)
        if _windowName == windowName {
            filteredWindows.append(window)
        }
    }

    if windowIdx < filteredWindows.count && windowIdx >= 0 {
        return filteredWindows[windowIdx]
    }
    return nil
}

/**
    Get the window `AXUIElement` by names and index
 */
func getWindowByName(processName: String, windowName: String?, windowIdx: Int) -> AXUIElement? {
    guard
        let pid = getPIDByName(processName: processName),
        let window = getWindowByPID(pid: pid, windowName: windowName, windowIdx: windowIdx)
    else {
        print("Can't get window \(processName)")
        return nil
    }
    return window
}

func setWindowPosition(_ window: AXUIElement, x: Int, y: Int) -> AXError {
    var point = CGPoint(x: x, y: y)
    let position = AXValueCreate(
        AXValueType(rawValue: kAXValueCGPointType)!,
        &point
    )!
    let err = AXUIElementSetAttributeValue(
        window,
        kAXPositionAttribute as CFString,
        position
    )
    return err
}

func setWindowSize(_ window: AXUIElement, width: Int, height: Int) -> AXError {
    var rect = CGSize(width: width, height: height)
    let size = AXValueCreate(
        AXValueType(rawValue: kAXValueCGSizeType)!,
        &rect
    )!
    let err = AXUIElementSetAttributeValue(
        window,
        kAXSizeAttribute as CFString,
        size
    )
    return err
}

/**
 Sets the window size and position by pid
 */
func setByRef(window: AXUIElement, x: Int, y: Int, width: Int, height: Int) -> AXError? {
    let err_pos = setWindowPosition(window, x: x, y: y)
    if err_pos != .success {
        return err_pos
    }
    let err_size = setWindowSize(window, width: width, height: height)
    if err_size != .success {
        return err_size
    }
    return nil
}

/**
 Set window attributes by Window object
 */
func setByWindow(window: inout Window) {
    guard window.windowRef != nil else {
        print("Window \(window.config.processName) does not have a ref yet")
        return
    }
    let config = window.config
    let err = setByRef(
        window: window.windowRef!,
        x: config.x,
        y: config.y,
        width: config.width,
        height: config.height
    )
    if err != nil && err! != .success {
        window.windowRef = nil
        print("Failed to set atrs for \(window.config.processName) with \(err!.rawValue)")
    }
}

/**
 Makes sure that the window object has a reference to the window
 then passes the window to a handler, so when the handler receives a window,
 it can assume that the window has a ref
 */
func ensureRef(window: inout Window) {
//    let indicies = ((filter?.count ?? 0) > 0) ? filter! : IndexSet(windows.indices)
    let config = window.config
    if (window.windowRef == nil) {
        print("\(config.processName)'s has no ref stored yet")
        guard let windowRef = getWindowByName(
            processName: config.processName,
            windowName: config.windowName,
            windowIdx: config.windowIdx
        ) else {
            print("Can't get window ref for \(config.processName)")
            return
        }
        window.windowRef = windowRef
    }
}

/**
 Set the window attribute given a list of windows, might need to change the refernence
 */
func setWindow(window: inout Window) {
    ensureRef(window: &window)
    setByWindow(window: &window)
}

func getWindowPosition(windowRef: AXUIElement) -> CGPoint? {
    var positionRef: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(
        windowRef,
        kAXPositionAttribute as CFString,
        &positionRef
    )
    guard err == .success else {
        print("can't get position with error \(err.rawValue)")
        return nil
    }
    var position: CGPoint = CGPoint()
    AXValueGetValue(
        positionRef as! AXValue,
        AXValueType(rawValue: kAXValueCGPointType)!,
        &position
    )

    return position
}

func getWindowSize(windowRef: AXUIElement) -> CGSize? {
    var sizeRef: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(
        windowRef,
        kAXSizeAttribute as CFString,
        &sizeRef
    )
    guard err == .success else {
        print("can't get size with error \(err.rawValue)")
        return nil
    }
    var size: CGSize = CGSize()
    AXValueGetValue(
        sizeRef as! AXValue,
        AXValueType(rawValue: kAXValueCGSizeType)!,
        &size
    )

    return size
}

/**
 Gets and fills info given a window, overwrites the attributes
 */
func getWindowInfo(window: inout Window) {
    guard window.windowRef != nil else {
        print("Window \(window.config.processName) does not have a window ref yet")
        return
    }

    guard
        let position = getWindowPosition(windowRef: window.windowRef!),
        let size = getWindowSize(windowRef: window.windowRef!)
    else {
        print("Failed to get info for \(window.config.processName)")
        window.windowRef = nil
        return
    }

    window.config.setPosition(x: Int(position.x), y: Int(position.y))
    window.config.setSize(width: Int(size.width), height: Int(size.height))
}

/**
 Locate the window
 */
func locateWindow(window: inout Window) {
    ensureRef(window: &window)
    getWindowInfo(window: &window)
}
