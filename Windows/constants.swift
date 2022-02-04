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
func readWindows(fname: String) -> [[String: AnyObject]]? {
    guard
        let content = try? String(contentsOfFile: fname),
        let data = content.data(using: .utf8)
    else {
        print("Failed to read song file")
        return nil
    }
    do {
        let json_output = try JSONSerialization.jsonObject(with: data, options: [])
        print(json_output)
        return (json_output as! [[String: AnyObject]])
    } catch {
        print("error parsing songs: \(error)")
        return nil
    }
}

/**
 Convert the file string to Window object
 */
func fileToWindows(content: [[String: AnyObject]]) -> [Window] {
    var windows: [Window] = []
    var invalids: [[String: AnyObject]] = []
    for item in content {
        let windowIdx = item["windowIdx"] as? Int
        if let name = item["name"] as? String,
           let x = item["x"] as? Int,
           let y = item["y"] as? Int,
           let width = item["width"] as? Int,
           let height = item["height"] as? Int {
            windows.append(Window(
                name: name,
                x: x, y: y,
                width: width, height: height,
                windowIdx: windowIdx
            ))
        }
        else {
            invalids.append(item)
        }
    }
    if !invalids.isEmpty {
        notification(
            title: "Some operations weren't successful",
            text: invalids.map{"\($0)"}.joined(separator: "\n")
        )
    }
    return windows
}

/**
 Reads the config from storage, or select a new file. If no previously saved storage, select a new file
 
 returns the object read if success
 
 The config has the following format:
 [
    {
        "name": "window name",
        "x": 2561,
        "y": -1093,
        "width": 1079,
        "height": 614
    },
    ...
 ]
 */
func readConfig(selectFile: Bool) -> [[String: AnyObject]]? {
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

func windowsToJSON(windows: [Window]) throws -> String {
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
func saveToFile(windows: [Window]) -> Bool {
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
