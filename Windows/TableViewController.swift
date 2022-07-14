//
//  TableViewController.swift
//  Windows
//
//  Created by James on 1/30/22.
//  Copyright © 2022 James. All rights reserved.
//

import Cocoa

let col_to_cell = [
    NSUserInterfaceItemIdentifier(rawValue: "process_name_col"): NSUserInterfaceItemIdentifier(rawValue: "process_name_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_name_col"): NSUserInterfaceItemIdentifier(rawValue: "window_name_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_index_col"): NSUserInterfaceItemIdentifier(rawValue: "window_index_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_x_col"): NSUserInterfaceItemIdentifier(rawValue: "window_x_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_y_col"): NSUserInterfaceItemIdentifier(rawValue: "window_y_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_width_col"): NSUserInterfaceItemIdentifier(rawValue: "window_width_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "window_height_col"): NSUserInterfaceItemIdentifier(rawValue: "window_height_cell"),
    NSUserInterfaceItemIdentifier(rawValue: "status_col"): NSUserInterfaceItemIdentifier(rawValue: "status_cell")
]

class TableViewController: NSViewController {
    @IBOutlet weak var tableView: NSTableView!
    var windowManager: WindowManager!
    var appDelegate: AppDelegate!
    var isEditing: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDelegate = NSApplication.shared.delegate as? AppDelegate
        self.windowManager = appDelegate.windowManager

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
        for row in selected_rows {
            self.windowManager.setWindow(i: row)
        }

        // reload the status column
        self.reloadColumn(rows: selected_rows, col: self.tableView.numberOfColumns - 1)
    }
    
    @IBAction func locate(_ sender: Any) {
        guard self.stopEditing() else {return}

        let selected_rows = self.tableView.selectedRowIndexes
        for row in selected_rows {
            self.windowManager.locateWindow(i: row)
        }
        self.reloadInplace()
    }
    
    @IBAction func open(_ sender: Any) {
        guard self.stopEditing() else {return}

        self.appDelegate.initWindow(selectFile: true)
        self.windowManager = appDelegate.windowManager
        self.tableView.reloadData()
    }
    
    @IBAction func save(_ sender: Any) {
        guard self.stopEditing() else {return}
        var _ = saveToFile(windows: self.windowManager.windows.map { $0.config })
    }
    
    @IBAction func remove(_ sender: Any) {
        guard self.stopEditing() else {return}

        let selected_rows = self.tableView.selectedRowIndexes
        guard selected_rows.count > 0 else {return}
        self.windowManager.filterWindows(indicies: selected_rows)

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
        self.windowManager.addWindow(window: DEFAULT_WINDOW)
        self.tableView.beginUpdates()
        self.tableView.insertRows(
            at: IndexSet([self.windowManager.windows.count - 1]),
            withAnimation: .slideDown
        )
        self.tableView.endUpdates()
        self.tableView.editColumn(0, row: self.windowManager.windows.count - 1, with: nil, select: true)
    }
    
    @IBAction func rowSelectionDidChange(_ sender: Any) {
        
    }
    
    /**
     Reload the data without removing selected rows
     */
    func reloadInplace() {
        self.tableView.beginUpdates()
        self.tableView.reloadData(
            forRowIndexes: IndexSet(0...(self.tableView.numberOfRows - 1)),
            columnIndexes: IndexSet(0...(self.tableView.numberOfColumns - 1))
        )
        self.tableView.endUpdates()
    }
    
    func reloadColumn(rows: IndexSet, col: Int) {
        self.tableView.beginUpdates()
        self.tableView.reloadData(
            forRowIndexes: rows,
            columnIndexes: IndexSet([col])
        )
        self.tableView.endUpdates()
    }
    
    func reloadOne(row: Int, col: Int) {
        self.tableView.beginUpdates()
        self.tableView.reloadData(
            forRowIndexes: IndexSet([row]),
            columnIndexes: IndexSet([col])
        )
        self.tableView.endUpdates()
    }
    
    func reloadOne(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        let col = self.tableView.column(for: sender as NSView)
        self.reloadOne(row: row, col: col)
    }

    @IBAction func processNameEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windowManager.windows.count else {return}
        guard !sender.stringValue.isEmpty && self.windowManager.windows[row].config.processName != sender.stringValue else {return}
        self.windowManager.setProcessName(i: row, processName: sender.stringValue)
        self.reloadOne(sender)
    }

    @IBAction func windowNameEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windowManager.windows.count else {return}
        guard !sender.stringValue.isEmpty && self.windowManager.windows[row].config.windowName != sender.stringValue else {return}
        self.windowManager.setWindowName(i: row, windowName: sender.stringValue)
        self.reloadOne(sender)
    }
    
    @IBAction func indexEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windowManager.windows.count else {return}
        guard self.windowManager.windows[row].config.windowIdx != sender.integerValue else {return}
        self.windowManager.setIndex(i: row, index: sender.integerValue)
        self.reloadOne(sender)
    }
    
    @IBAction func xEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windowManager.windows.count else {return}
        guard self.windowManager.windows[row].config.x != sender.integerValue else {return}
        self.windowManager.setX(i: row, x: sender.integerValue)
        self.reloadOne(sender)
    }
    
    @IBAction func yEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windowManager.windows.count else {return}
        guard self.windowManager.windows[row].config.y != sender.integerValue else {return}
        self.windowManager.setY(i: row, y: sender.integerValue)
        self.reloadOne(sender)
    }
    
    @IBAction func widthEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windowManager.windows.count else {return}
        guard self.windowManager.windows[row].config.width != sender.integerValue else {return}
        self.windowManager.setWidth(i: row, width: sender.integerValue)
        self.reloadOne(sender)
    }
    
    @IBAction func heightEdit(_ sender: NSTextField) {
        let row = self.tableView.row(for: sender as NSView)
        guard row >= 0 && row < self.windowManager.windows.count else {return}
        guard self.windowManager.windows[row].config.height != sender.integerValue else {return}
        self.windowManager.setHeight(i: row, height: sender.integerValue)
        self.reloadOne(sender)
    }
}

extension TableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.windowManager.windows.count
    }
}

extension TableViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let currentWindow = self.windowManager.windows[row]
        let currentWindowConfig = currentWindow.config
        guard
            let columnIdentifier = tableColumn?.identifier,
            let cellIdentifier = col_to_cell[columnIdentifier] else {
            return nil
        }
        guard
            let cellView = tableView.makeView(
                withIdentifier: cellIdentifier,
                owner: self
            ) as? NSTableCellView
        else {
            print("Can't get \(cellIdentifier.rawValue)")
            return nil
        }
        
        let textField = cellView.textField
        let imageView = cellView.imageView
        
        switch cellView.identifier?.rawValue {
        case "process_name_cell":
            textField?.stringValue = currentWindowConfig.processName
            break
        case "window_name_cell":
            if currentWindowConfig.windowName != nil {
                textField?.stringValue = currentWindowConfig.windowName!
            }
            break
        case "window_x_cell":
            textField?.integerValue = currentWindowConfig.x
            break
        case "window_y_cell":
            textField?.integerValue = currentWindowConfig.y
            break
        case "window_width_cell":
            textField?.integerValue = currentWindowConfig.width
            break
        case "window_height_cell":
            textField?.integerValue = currentWindowConfig.height
            break
        case "window_index_cell":
            textField?.integerValue = currentWindowConfig.windowIdx
            break
        case "status_cell":
            if currentWindow.windowRef == nil {
                imageView?.image = NSImage(imageLiteralResourceName: "NSStatusUnavailable")
                // set the error message
                cellView.toolTip = currentWindow.lastError
            }
            else {
                imageView?.image = NSImage(imageLiteralResourceName: "NSStatusAvailable")
                // clear the error message
                cellView.toolTip = nil
            }
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
