//
//  TodoItem+CoreDataProperties.swift
//  DQuery
//
//  Created by 陳小晶 on 16/1/11.
//  Copyright © 2016年 chi zhang. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TodoItem {

    @NSManaged var title: String?
    @NSManaged var isDone: NSNumber?
    @NSManaged var displayOrder: NSNumber?

}
