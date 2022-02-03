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
    var windows: [Window]!
    var appDelegate: AppDelegate!
    var isEditing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDelegate = NSApplication.shared.delegate as? AppDelegate
        self.windows = appDelegate.windows

        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func stopEditing() -> Bool {
        guard
            let table_window = self.tableView.window,
            table_window.makeFirstResponder(table_window)
        else {
            print("Failed to stop editing")
            return false
        }
        return true
    }
    
    @IBAction func apply(_ sender: Any) {
        guard self.stopEditing() else {return}

        let selected_rows = self.tableView.selectedRowIndexes
        setWindows(windows: &self.windows, filter: selected_rows)
    }
    
    @IBAction func locate(_ sender: Any) {
        guard self.stopEditing() else {return}

        let selected_rows = self.tableView.selectedRowIndexes
        saveWindows(windows: &self.windows, filter: selected_rows)
        self.tableView.reloadData()
    }
    
    @IBAction func open(_ sender: Any) {
        guard self.stopEditing() else {return}

        self.appDelegate.initWindow(selectFile: true)
        self.windows = self.appDelegate.windows
        self.tableView.reloadData()
    }
    
    @IBAction func save(_ sender: Any) {
        guard self.stopEditing() else {return}
        var _ = saveToFile(windows: self.windows)
    }
    
    @IBAction func remove(_ sender: Any) {
        guard self.stopEditing() else {return}

        let selected_rows = self.tableView.selectedRowIndexes
        guard selected_rows.count > 0 else {return}
        let filtered_windows = self.windows.indices.filter {
            !selected_rows.contains($0)
        }.map {
            self.windows[$0]
        }
        self.appDelegate.windows = filtered_windows
        self.windows = filtered_windows

        self.tableView.beginUpdates()
        self.tableView.removeRows(
            at: selected_rows,
            withAnimation: .slideUp
        )
        self.tableView.endUpdates()
    }
    
    @IBAction func add(_ sender: Any) {
        guard self.stopEditing() else {return}

        // add a new item with default values
        self.windows.append(DEFAULT_WINDOW)
        self.tableView.beginUpdates()
        self.tableView.insertRows(
            at: IndexSet([self.windows.count - 1]),
            withAnimation: .slideDown
        )
        self.tableView.endUpdates()
        self.tableView.editColumn(0, row: self.windows.count - 1, with: nil, select: true)
    }
    
    @IBAction func rowSelectionDidChange(_ sender: Any) {
        
    }
    
    func reloadOne(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        let col = self.tableView.column(for: sender as NSView)
        self.tableView.beginUpdates()
        self.tableView.reloadData(
            forRowIndexes: IndexSet([row]),
            columnIndexes: IndexSet([col])
        )
        self.tableView.endUpdates()
    }

    @IBAction func windowNameEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windows.count else {return}
        guard self.windows[row].name != sender.stringValue else {return}
        self.windows[row].name = sender.stringValue
        self.reloadOne(sender)
    }
    
    @IBAction func indexEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windows.count else {return}
        guard self.windows[row].windowIdx != sender.integerValue else {return}
        self.windows[row].windowIdx = sender.integerValue
        self.reloadOne(sender)
    }
    
    @IBAction func xEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windows.count else {return}
        guard self.windows[row].x != sender.integerValue else {return}
        self.windows[row].x = sender.integerValue
        self.reloadOne(sender)
    }
    
    @IBAction func yEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windows.count else {return}
        guard self.windows[row].y != sender.integerValue else {return}
        self.windows[row].y = sender.integerValue
        self.reloadOne(sender)
    }
    
    @IBAction func widthEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windows.count else {return}
        guard self.windows[row].width != sender.integerValue else {return}
        self.windows[row].width = sender.integerValue
        self.reloadOne(sender)
    }
    
    @IBAction func heightEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windows.count else {return}
        guard self.windows[row].height != sender.integerValue else {return}
        self.windows[row].height = sender.integerValue
        self.reloadOne(sender)
    }
}

extension TableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.windows.count
    }
}

extension TableViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let currentWindow = self.windows[row]
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
    
    func controlTextDidEndEditing(_ obj: Notification) {
        // go to the next or prev col via tab
        guard
            let view = obj.object as? NSView,
            let textMovementInt = obj.userInfo?["NSTextMovement"] as? Int,
            let textMovement = NSTextMovement(rawValue: textMovementInt)
        else {
            print("Failed to handle control text end editing")
            return
        }
        
        let col = self.tableView.column(for: view)
        let row = self.tableView.row(for: view)
        
        let next_col: Int
        
        switch textMovement {
        case .tab:
            next_col = col + 1
            break
        case .backtab:
            next_col = col - 1
        default: return
        }
        
        if next_col >= 0 && next_col < self.tableView.numberOfColumns {
            DispatchQueue.main.async {
                self.tableView.editColumn(next_col, row: row, with: nil, select: true)
            }
        }
    }
}
