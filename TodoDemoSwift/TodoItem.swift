//
//  TodoItem.swift
//  DQuery
//
//  Created by 陳小晶 on 16/1/11.
//  Copyright © 2016年 chi zhang. All rights reserved.
//

import Foundation
import CoreData
import DQuery

class TodoItem: NSManagedObject {
    class func topDisplayOrder(context: NSManagedObjectContext) -> Int {
        if let item = DQ.query(self, context: context).min("displayOrder").first() {
            if let order = item.displayOrder?.integerValue {
                return order - 1
            }
        }
        return 0
    }
}
