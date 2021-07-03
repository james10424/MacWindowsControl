//
//  constants.swift
//  Windows
//
//  Created by James on 7/2/21.
//  Copyright © 2021 James. All rights reserved.
//

import Foundation

let title = "❖"

let fname = "/Users/james/applescripts/windows.json"

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
            windows.append(Window(name: name, x: x, y: y, width: width, height: height, windowIdx: windowIdx))
        }
        else {
            invalids.append(item)
        }
    }
    if !invalids.isEmpty {
        notification(title: "Some operations weren't successful", text: invalids.map{"\($0)"}.joined(separator: "\n"))
    }
    else {
        notification(title: "Read these windows", text: windows.map{"\($0.description)"}.joined(separator: "\n"))
    }
    return windows
}
