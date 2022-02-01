//
//  TableViewController.swift
//  Windows
//
//  Created by James on 1/30/22.
//  Copyright © 2022 James. All rights reserved.
//

import Cocoa

let col_to_cell = [
    NSUserInterfaceItemIdentifier(rawValue: "window_name_col"): NSUserInterfaceItemIdentifier(rawValue: "window_name_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_index_col"): NSUserInterfaceItemIdentifier(rawValue: "window_index_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_x_col"): NSUserInterfaceItemIdentifier(rawValue: "window_x_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_y_col"): NSUserInterfaceItemIdentifier(rawValue: "window_y_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_width_col"): NSUserInterfaceItemIdentifier(rawValue: "window_width_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_height_col"): NSUserInterfaceItemIdentifier(rawValue: "window_height_cell"),
]

class TableViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    var windowViewModel: WindowViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        self.windowViewModel = WindowViewModel(appDelegate.windows!)

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func apply(_ sender: Any) {
//        print(self.windowViewModel.windows[0].)
        let selected_rows = self.tableView.selectedRowIndexes
        if selected_rows.count == 0 {
            setWindows(windows: &self.windowViewModel.windows)
        } else {
            var filtered_windows = selected_rows.map {
                self.windowViewModel.windows[$0]
            }
            setWindows(windows: &filtered_windows)
        }
    }
}

extension TableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.windowViewModel.windows.count
    }
}

extension TableViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let currentWindow = windowViewModel.windows[row]
        guard
            let columnIdentifier = tableColumn?.identifier,
            let cellIdentifier = col_to_cell[columnIdentifier] else {
            return nil
        }
        guard
            let cellView = tableView.makeView(
                withIdentifier: cellIdentifier,
                owner: self
            ) as? NSTableCellView,
            let textField = cellView.textField
        else {
            print("Can't get \(cellIdentifier)")
            return nil
        }
        
        switch cellView.identifier?.rawValue {
        case "window_name_cell":
            textField.stringValue = currentWindow.name
            break
        case "window_index_cell":
            textField.integerValue = currentWindow.windowIdx ?? 0
            break
        case "window_x_cell":
            textField.integerValue = currentWindow.x
            break
        case "window_y_cell":
            textField.integerValue = currentWindow.y
            break
        case "window_width_cell":
            textField.integerValue = currentWindow.width
            break
        case "window_height_cell":
            textField.integerValue = currentWindow.height
            break
        default:
            return nil
        }

        return cellView
    }
}
