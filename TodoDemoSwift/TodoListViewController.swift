//
// Copyright 2016 DQuery
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  TodoListViewController.swift
//
//  Created by chi on 16/1/10.
//

import UIKit

class TodoListViewController: UIViewController {
    var innerTableViewController: TodoListTableViewController?
    
    @IBAction func newTodoItem(sender: AnyObject) {
        innerTableViewController?.startComposingNewTodoItem()
    }
}

class TodoListTableViewController: UITableViewController {
    enum Section: Int {
        case Todo = 0
        case Done
        func name() -> String {
            switch self {
            case .Todo:
                return "TODO"
            case .Done:
                return "DONE"
            }
        }
        
        static var count = 2
    }
    
    enum Cell: String {
        case NewItemCell = "NewTodoItemIdentifier"
        case TodoItemCell = "TodoItemCellIdentifier"
        case DoneItemCell = "DoneItemCellIdentifier"
        
        var identifier: String { return self.rawValue }
    }
    
    var isComposingNewTodoItem: Bool = false
    
    let dataController = TodoListDataController()
    
    override func didMoveToParentViewController(parent: UIViewController?) {
        if let todoListVC = parent as? TodoListViewController {
            todoListVC.innerTableViewController = self
        }
    }
    
    override func viewDidLoad() {
        tableView.estimatedRowHeight = 40
        tableView.separatorStyle = .None
        dataController.reloadDataFromDB({
            self.tableView.reloadData()
        })
    }
    
    // MARK: table view
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let (row, section) = (indexPath.row, indexPath.section)
        
        switch Section(rawValue: section)! {
        case .Todo:
            var itemRow = row
            if self.isComposingNewTodoItem {
                if row == 0 {
                    // the composing cell
                    let cell = tableView.dequeueReusableCellWithIdentifier(Cell.NewItemCell.identifier) as! NewTodoItemCell
                    cell.textView.text = ""
                    cell.actionTriggered = { [weak self] (cell, action) in
                        let inserted = action == .OK
                        self?.endComposingNewTodoItem(insertedNewItem: inserted)
                    }
                    return cell
                } else {
                    itemRow -= 1
                }
            }
            // a todo item cell
            let cell = tableView.dequeueReusableCellWithIdentifier(Cell.TodoItemCell.identifier) as! TodoItemCell
            let viewModel = self.dataController.todoItemAtRow(itemRow)
            cell.configureWithViewModel(viewModel)
            cell.actionTriggered = { [weak self] (cell, action) in
                if action == .MarkAsDone {
                    self?.markItemAsDoneForCell(cell)
                }
            }
            return cell
        case .Done:
            // done item cell
            let cell = tableView.dequeueReusableCellWithIdentifier(Cell.DoneItemCell.identifier) as! DoneItemCell
            let viewModel = self.dataController.doneItemAtRow(indexPath.row)
            cell.configureWithViewModel(viewModel)
            cell.actionTriggered = { [weak self] (cell, action) in
                if action == .Delete {
                    self?.deleteDoneItemForCell(cell)
                }
            }
            return cell
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Section.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)!.name()
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .Todo:
            let count = self.dataController.todoItemsCount
            if self.isComposingNewTodoItem {
                return count + 1
            }
            return count
        case .Done:
            return self.dataController.doneItemsCount
        }
    }
    
    // MARK: cell actions
    func deleteDoneItemForCell(cell: DoneItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.dataController.deleteDoneItemAtRow(indexPath.row) {
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
        }
    }
    
    func markItemAsDoneForCell(cell: TodoItemCell) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.dataController.markTodoItemAsDoneAtRow(indexPath.row) {
                self.tableView.beginUpdates()
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: Section.Done.rawValue)], withRowAnimation: .Automatic)
                self.tableView.endUpdates()
            }
        }
    }
    
    // MARK: composing
    func startComposingNewTodoItem() {
        if self.isComposingNewTodoItem {
            return
        }
        
        self.isComposingNewTodoItem = true
        self.tableView.beginUpdates()
        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Left)
        self.tableView.endUpdates()
    }
    
    func endComposingNewTodoItem(insertedNewItem insertedNewItem: Bool) {
        if !self.isComposingNewTodoItem {
            return
        }
        
        if let newTodoItemCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? NewTodoItemCell {
            newTodoItemCell.textView.resignFirstResponder()
            if insertedNewItem {
                let title = newTodoItemCell.textView.text
                self.dataController.insertTodoItem(title: title) {
                    self.isComposingNewTodoItem = false
                    self.tableView.beginUpdates()
                    self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
                    if insertedNewItem {
                        self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Automatic)
                    }
                    self.tableView.endUpdates()
                }
            } else {
                self.isComposingNewTodoItem = false
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)], withRowAnimation: .Left)
            }
        }
        
    }
}