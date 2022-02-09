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
    var lastError: String?

    init(config: WindowConfig) {
        self.config = config
    }
}

enum WindowError: Error {
    case AccessError(msg: String)
    case AXError(err: AXError)
}

/**
 GeWindowConfigby window owner name
 */
func getPIDByName(processName: String) throws -> Int32 {
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
    throw WindowError.AccessError(msg: "Can't find PID for \(processName)")
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
func getWindowByPID(
    pid: Int32,
    windowName: String?,
    windowIdx: Int
) throws -> AXUIElement {
    // get handle
    let app = AXUIElementCreateApplication(pid)
    var value: AnyObject?
    let err = AXUIElementCopyAttributeValue(
        app,
        kAXWindowsAttribute as CFString,
        &value
    ) as AXError

    guard err == .success else {
        throw WindowError.AXError(err: err)
    }
    
    // filter window with this name
    guard
        let windows = value as? [AXUIElement],
        windows.count > 0
    else {
        throw WindowError.AccessError(msg: "Failed to convert window results to AXUIElement for \(pid)")
    }

    if windowName == nil {
        // no window name to filter
        if windowIdx < windows.count && windowIdx >= 0 {
            return windows[windowIdx]
        }
        throw WindowError.AccessError(msg: "Index \(windowIdx) out of range")
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
    throw WindowError.AccessError(msg: "Index \(windowIdx) out of range when trying to get \(windowName!)")
}

/**
    Get the window `AXUIElement` by names and index
 */
func getWindowByName(processName: String, windowName: String?, windowIdx: Int) throws -> AXUIElement {
    let pid = try getPIDByName(processName: processName)
    let window = try getWindowByPID(pid: pid, windowName: windowName, windowIdx: windowIdx)
    return window
}

func setWindowPosition(_ window: AXUIElement, x: Int, y: Int) throws {
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
    if err != .success {
        throw WindowError.AXError(err: err)
    }
}

func setWindowSize(_ window: AXUIElement, width: Int, height: Int) throws {
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
    if err != .success {
        throw WindowError.AXError(err: err)
    }
}

/**
 Sets the window size and position by pid
 */
func setByRef(window: AXUIElement, x: Int, y: Int, width: Int, height: Int) throws {
    try setWindowPosition(window, x: x, y: y)
    try setWindowSize(window, width: width, height: height)
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
    do {
        try setByRef(
            window: window.windowRef!,
            x: config.x,
            y: config.y,
            width: config.width,
            height: config.height
        )
        window.lastError = nil  // clear error if success
    } catch WindowError.AXError(let err) {
        var msg: String
        if err == .apiDisabled {
            msg = "Assistive access disabled for \(window.config.processName)"
        } else {
            msg = "Error setting window for \(window.config.processName): \(err.rawValue)"
        }
        print(msg)
        window.lastError = msg
        window.windowRef = nil
    } catch {
        let msg = "Unknown error"
        print(msg)
        window.windowRef = nil
        window.lastError = msg
    }
}

/**
 Makes sure that the window object has a reference to the window
 then passes the window to a handler, so when the handler receives a window,
 it can assume that the window has a ref
 */
func ensureRef(window: inout Window) {
    if (window.windowRef != nil) {
        // clear error message if we have proper ref
        // next steps will set the error message if failed
        window.lastError = nil
        return
    }
    let config = window.config
    print("No ref stored for \(config.processName)")
    do {
        let windowRef = try getWindowByName(
            processName: config.processName,
            windowName: config.windowName,
            windowIdx: config.windowIdx
        )
        window.windowRef = windowRef
    } catch WindowError.AccessError(let msg) {
        print("Can't get window ref for \(config.processName): \(msg)")
        window.lastError = msg
    } catch WindowError.AXError(let err) {
        var msg: String
        if err == .apiDisabled {
            msg = "Assistive access disabled for \(window.config.processName)"
        } else {
            msg =  "Error getting window for \(window.config.processName): \(err.rawValue)"
        }
        print(msg)
        window.lastError = msg
    } catch {
        let msg = "Unexpected error"
        print(msg)
        window.lastError = msg
    }
}

/**
 Set the window attribute given a list of windows, might need to change the refernence
 */
func setWindow(window: inout Window) {
    ensureRef(window: &window)
    setByWindow(window: &window)
}

func getWindowPosition(windowRef: AXUIElement) throws -> CGPoint {
    var positionRef: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(
        windowRef,
        kAXPositionAttribute as CFString,
        &positionRef
    )
    guard err == .success else {
        throw WindowError.AXError(err: err)
    }
    var position: CGPoint = CGPoint()
    let success = AXValueGetValue(
        positionRef as! AXValue,
        AXValueType(rawValue: kAXValueCGPointType)!,
        &position
    )
    if !success {
        throw WindowError.AccessError(msg: "Failed to convert position data")
    }

    return position
}

func getWindowSize(windowRef: AXUIElement) throws -> CGSize {
    var sizeRef: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(
        windowRef,
        kAXSizeAttribute as CFString,
        &sizeRef
    )
    guard err == .success else {
        throw WindowError.AXError(err: err)
    }
    var size: CGSize = CGSize()
    let success = AXValueGetValue(
        sizeRef as! AXValue,
        AXValueType(rawValue: kAXValueCGSizeType)!,
        &size
    )
    if !success {
        throw WindowError.AccessError(msg: "Failed to convert size data")
    }

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

    do {
        let position = try getWindowPosition(windowRef: window.windowRef!)
        let size = try getWindowSize(windowRef: window.windowRef!)
        window.config.setPosition(x: Int(position.x), y: Int(position.y))
        window.config.setSize(width: Int(size.width), height: Int(size.height))
    } catch WindowError.AXError(let err) {
        var msg: String
        if err == .apiDisabled {
            msg = "Assistive access disabled for \(window.config.processName)"
        } else {
            msg = "Error getting window information for \(window.config.processName): \(err.rawValue)"
        }
        print(msg)
        window.lastError = msg
        window.windowRef = nil
    } catch WindowError.AccessError(let msg) {
        window.lastError = msg
        window.windowRef = nil
    } catch {
        let msg = "Unexpected error"
        print(msg)
        window.lastError = msg
        window.windowRef = nil
   }
}

/**
 Locate the window
 */
func locateWindow(window: inout Window) {
    ensureRef(window: &window)
    getWindowInfo(window: &window)
}
