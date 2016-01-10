//
//  Employee+CoreDataProperties.swift
//  DQuery
//
//  Created by Chi Zhang on 1/10/16.
//  Copyright © 2016 chi zhang. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Employee {

    @NSManaged var name: String?
    @NSManaged var age: NSNumber?

}
