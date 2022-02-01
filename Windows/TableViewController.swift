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
    var appDelegate: AppDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDelegate = NSApplication.shared.delegate as? AppDelegate
        self.windowViewModel = WindowViewModel(appDelegate.windows!)

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    @IBAction func apply(_ sender: Any) {
        let selected_rows = self.tableView.selectedRowIndexes
        setWindows(windows: &self.windowViewModel.windows, filter: selected_rows)
    }
    
    @IBAction func locate(_ sender: Any) {
        let selected_rows = self.tableView.selectedRowIndexes
        saveWindows(windows: &self.windowViewModel.windows, filter: selected_rows)
        self.tableView.reloadData()
    }
    
    @IBAction func open(_ sender: Any) {
        self.appDelegate.initWindow(selectFile: true)
        self.windowViewModel.windows = self.appDelegate.windows!
        self.tableView.reloadData()
    }
    
    @IBAction func save(_ sender: Any) {
        var _ = saveToFile(windows: self.windowViewModel.windows)
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
