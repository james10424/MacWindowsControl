//
//  constants.swift
//  Windows
//
//  Created by James on 7/2/21.
//  Copyright © 2021 James. All rights reserved.
//

import Foundation
import AppKit

let title = "❖"

/**
 Read the file given file name
 
 Return the object read if success
 */
func readWindows(fname: String) -> [WindowConfig]? {
    guard
        let content = try? String(contentsOfFile: fname),
        let data = content.data(using: .utf8)
    else {
        print("Failed to read song file")
        return nil
    }
    let decoder = JSONDecoder()
    do {
        let windows = try decoder.decode([WindowConfig].self, from: data)
        return windows
    } catch {
        print("error parsing windows: \(error)")
        return nil
    }
}

/**
 Reads the config from storage, or select a new file. If no previously saved storage, select a new file
 
 returns the object read if success
 
 The config has the following format:
 ```
 [
    {
        "processName": "window name",
        "windowName": null,
        "x": 2561,
        "y": -1093,
        "width": 1079,
        "height": 614
    },
    ...
 ]
```
 */
func readConfig(selectFile: Bool) -> [WindowConfig]? {
    let defaults = UserDefaults.standard
    var fname: String?
    let defaultFile = defaults.string(forKey: "windowConfig")
    if selectFile {
        // force to select a new file or no file saved
        fname = askForFile(defaultFile: defaultFile)
        guard fname != nil else {
            notification(
                title: "This doesn't work",
                text: "You haven't selected a file"
            )
            return nil
        }
    }
    else {
        guard defaultFile != nil else {return nil}
        // use the default file
        fname = defaultFile
    }

    guard let ws = readWindows(fname: fname!) else {
        notification(
            title: "Invalid config",
            text: "The config file you supplied is invalid"
        )
        return nil
    }
    print("Read these windows: ", ws)
    defaults.set(fname, forKey: "windowConfig")
    return ws
}

/**
 Displays a dialog, optional handler to handle what happens with the window and key press
 */
func notification(title: String, text: String, handler: ((NSAlert) -> Void)? = nil) {
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = text
    alert.alertStyle = .warning

    if handler != nil {
        handler!(alert)
    }
    else {
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

/**
 Ask for a file path, optional pre-selected file
 
 Return the file name if successful
 */
func askForFile(defaultFile: String?) -> String? {
    let dialog = NSOpenPanel()
    dialog.message = "Choose a window config file (json)"
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

func windowsToJSON(windows: [WindowConfig]) throws -> String {
    // convert list of windows into json
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    let data = try encoder.encode(
        windows.map {$0.jsonRepresentation}
    )
    return String(data: data, encoding: .utf8)!
}

/**
 Save a json representation of given windows to a file
 
 Return true if it has successfully been saved
 */
func saveToFile(windows: [WindowConfig]) -> Bool {
    // get json string
    guard let jsonString = try? windowsToJSON(windows: windows)
    else {
        print("Failed to convert windows to json")
        return false
    }
    
    // get save file dialog
    let dialog = NSSavePanel()
    var success = false
    dialog.nameFieldStringValue = "windowLocations"
    dialog.allowedFileTypes = ["json"]
    
    dialog.begin() { (result) -> Void in
        if  result == .OK,
            let fname = dialog.url {
            do {
                try jsonString.write(to: fname, atomically: true, encoding: .utf8)
                success = true
            } catch {
                print("Error writing to file: \(error)")
                success = false
            }
        }
        else {
            success = false
        }
    }
    return success
}

 func checkAccessibility() {
    //get the value for accesibility
    let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    //set the options: false means it wont ask
    //true means it will popup and ask
    let options = [checkOptPrompt: true]
    //translate into boolean value
    let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)

    if accessEnabled {
        print("Access Granted")
    } else {
        print("Access not allowed")
    }
}


let DEFAULT_WINDOW_CONFIG = WindowConfig(
    processName: "New Process",
    x: 0, y: 0,
    width: 0, height: 0,
    windowIdx: 0
)

let DEFAULT_WINDOW = Window(config: DEFAULT_WINDOW_CONFIG)
