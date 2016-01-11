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
//  TodoListDataController.swift
//
//  Created by chi on 16/1/10.
//


import Foundation
import CoreData
import DQuery

class TodoListDataController {
    private var todoItems = [NSManagedObjectID]()
    private var doneItems = [NSManagedObjectID]()
    
    // data change callback
    var onChange: (()->())?
    private var shouldAutoReloadOnDataChange = true
    
    init() {
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataChanged:", name: NSManagedObjectContextObjectsDidChangeNotification, object: session.defaultContext)
    }
    
    deinit {
        print("deinit view model")
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: session.defaultContext)
    }
    
    @objc func dataChanged(notification: NSNotification) {
        //        print("changed: \(notification)")
        if shouldAutoReloadOnDataChange {
            self.reloadDataFromDB({
//                print("on change!!! \(self)")
                self.onChange?()
            })
        }
    }
    
    func todoItemAtRow(row: Int) -> TodoItemViewModel {
        return TodoItemViewModel(itemId: self.todoItems[row])
    }
    
    func doneItemAtRow(row: Int) -> TodoItemViewModel {
        return TodoItemViewModel(itemId: self.doneItems[row])
    }
    
    var todoItemsCount: Int {
        return todoItems.count
    }
    
    var doneItemsCount: Int {
        return doneItems.count
    }
    
    func reloadDataFromDB(completion: (() -> ())? = nil) {
        let query = DQ.query(TodoItem).orderBy("displayOrder")
        query.execute { (context, objectIds) in
            var todoItems = [NSManagedObjectID]()
            var doneItems = [NSManagedObjectID]()
            for objId in objectIds {
                let item: TodoItem = context.dq_objectWithID(objId)
                if item.isDone?.boolValue == true {
                    doneItems.append(objId)
                } else {
                    todoItems.append(objId)
                }
            }
            // TODO: sort done items by done time
            dispatch_async(dispatch_get_main_queue(), {
                self.todoItems = todoItems
                self.doneItems = doneItems
                print("reloaded todo items from db")
                completion?()
            })
        }
    }
    
    func moveTodoItem(fromRow srcRow: Int, toRow destRow: Int, completion: (()->())? = nil) {
        if srcRow == destRow {
            return
        }
        
        self.shouldAutoReloadOnDataChange = false

        var todoItems = self.todoItems
        
        DQ.write (
            { context in
                let exchangeWithBelow = { (row: Int) in
                    let item: TodoItem = context.dq_objectWithID(todoItems[row])
                    let nextItem: TodoItem = context.dq_objectWithID(todoItems[row+1])
                    swap(&item.displayOrder, &nextItem.displayOrder)
                    swap(&todoItems[row], &todoItems[row+1])
                }
                
                if srcRow < destRow {
                    for row in srcRow..<destRow {
                        exchangeWithBelow(row)
                    }
                } else {
                    for row in (destRow..<srcRow).reverse() {
                        exchangeWithBelow(row)
                    }
                }
                
                dispatch_sync(dispatch_get_main_queue(), {
                    self.todoItems = todoItems
                })
            },
            sync: false,
            completion: {
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
        
    }
    
    func deleteTodoItemAtRow(row: Int, completion: (()->())?) {
        let objId = self.todoItems[row]
        
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.todoItems.removeAtIndex(row)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }
    
    func deleteDoneItemAtRow(row: Int, completion: (()->())?) {
        let objId = self.doneItems[row]
        
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            {context in
                let item: TodoItem = context.dq_objectWithID(objId)
                item.dq_delete()
            },
            sync: false,
            completion: {
                self.doneItems.removeAtIndex(row)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }

    
    func markTodoItemAsDoneAtRow(row: Int, completion: (()->())?) {
        let objId = self.todoItems[row]
        
        self.shouldAutoReloadOnDataChange = false
        DQ.write(
            {context in
                // TODO: done time
                let item: TodoItem = context.dq_objectWithID(objId)
                item.isDone = true
            },
            sync: false,
            completion: {
                self.todoItems.removeAtIndex(row)
                self.doneItems.insert(objId, atIndex: 0)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }

    
    func insertTodoItem(title title: String, completion: (()->())?) {
        self.shouldAutoReloadOnDataChange = false
        DQ.insertObject(TodoItem.self,
            block: {context, item in
                item.title = title
                item.displayOrder = 1 //TodoItem.topDisplayOrder(context)
            },
            sync: false,
            completion: { objId in
                self.todoItems.insert(objId, atIndex: 0)
                completion?()
                self.shouldAutoReloadOnDataChange = true
        })
    }
}