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
//  DQuery.swift
//
//  Created by Chi Zhang on 1/9/16.
//

import Foundation
import CoreData

// singleton API caller
public let DQ = DQAPI()

// supported store types
public enum StoreType: Int {
    case SQLite
    case InMemory
}

var monitorHandle: UInt8 = 0

// public APIs
public class DQAPI {
    public init() {}
    
    public enum OptionKey {
        case ModelName
        case StoreType
        case ModelFileBundle
        case StoreCoordinator
    }
    
    let dq = DQImpl()
    var isConfigured = false
    
    public func config(options: [OptionKey: Any]) {
        assert(!isConfigured, "DQAPIs should only be configured once!")
        
        let dqContext = DQContext()
        
        for (key, val) in options {
            switch key {
            case .ModelName:
                dqContext.modelName = val as! String
            case .StoreType:
                dqContext.storeType = val as! StoreType
            case .ModelFileBundle:
                dqContext.bundle = val as! NSBundle
            case .StoreCoordinator:
                dqContext.persistentStoreCoordinator = val as! NSPersistentStoreCoordinator
            }
        }
        
        dq.dqContext = dqContext
        isConfigured = true
    }
    
    public func objectWithID<T: NSManagedObject>(id: NSManagedObjectID) -> T {
        return self.dq.dqContext.defaultContext.objectWithID(id) as! T
    }
    
    public func objectsWithIDs<T: NSManagedObject>(ids: [NSManagedObjectID]) -> [T] {
        return ids.map { self.objectWithID($0) }
    }

    public func query<T:NSManagedObject>(entity: T.Type) -> DQQuery<T> {
        assert(isConfigured, "calling query when context is not configured")
        
        return dq.query(entity)
    }
    
    public func query<T:NSManagedObject>(entity: T.Type, context: NSManagedObjectContext) -> DQQuery<T> {
        assert(isConfigured, "calling query when context is not configured")

        return dq.query(entity, context: context)
    }
    
    public func insertObject<T:NSManagedObject>(entity: T.Type, block:(NSManagedObjectContext, T)->Void, sync: Bool = false, completion: ((NSManagedObjectID)->())?) {
        assert(isConfigured, "calling insertObject when context is not configured")

        return dq.insertObject(entity, block: block, sync: sync, completion: completion)
    }
    
    public func write(block: (NSManagedObjectContext)->Void, sync: Bool = false, completion: (()->Void)? = nil) {
        assert(isConfigured, "calling write when context is not configured")

        return dq.write(block, sync: sync, completion: completion)
    }
    
    public func monitor(object: AnyObject, block: ([NSObject: AnyObject])->()) {
        let monitor = DQMonitor(block: block, context: dq.dqContext.defaultContext)
        objc_setAssociatedObject(object, &monitorHandle, monitor, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}


// wraps Core Data context
class DQContext {
    var modelName: String! = nil
    var storeType: StoreType = .SQLite
    lazy var bundle: NSBundle = {
//        print("using main bundle automatically")
        return NSBundle.mainBundle()
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // create model
//        print("init persistentStoreCoordinator automatically")
//        print("model name: \(self.modelName)")
        let modelURL = self.bundle.URLForResource(self.modelName, withExtension: "momd")!
        //                let modelURL = NSBundle(forClass: DQContext.self).URLForResource(self.modelName, withExtension: "momd")!
        let model = NSManagedObjectModel(contentsOfURL: modelURL)!
        
        // create coordinator
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
//        print("coordinator: \(coordinator)")
        
        var coreDataStoreType: String
        var url: NSURL?
        
        switch self.storeType {
        case .SQLite:
            coreDataStoreType = NSSQLiteStoreType
            let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
            let applicationDocumentsDirectory = urls[urls.count-1]
            url = applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.modelName).sqlite")
        case .InMemory:
            coreDataStoreType = NSInMemoryStoreType
        }
        
        do {
            try coordinator.addPersistentStoreWithType(coreDataStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            let failureReason = "There was an error creating or loading the application's saved data."
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    // the context for main queue
    lazy var defaultContext: NSManagedObjectContext = {
        var context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.parentContext = self.rootContext
        return context
    }()

    // the private writer context running on background
    lazy var rootContext: NSManagedObjectContext = {
        var context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        context.performBlockAndWait({
            let coordinator = self.persistentStoreCoordinator
            context.persistentStoreCoordinator = coordinator
        })
        
        return context
    }()

    // save all contexts
    func save() {
        self.defaultContext.performBlockAndWait({
            // TODO this is run on the UI queue, count the performance
            if self.defaultContext.hasChanges {
                do {
                    try self.defaultContext.save()
//                    print("saved default")
                } catch {
                    print("save default error")
                    return
                }
            }
        })
        
        self.rootContext.performBlock({
            if self.rootContext.hasChanges {
                do {
                    try self.rootContext.save()
//                    print("saved root")
                } catch {
                    print("save root error")
                    return
                }
            }
        })
    }

}


class DQImpl {
    var dqContext: DQContext! = nil
    
    func query<T:NSManagedObject>(entity: T.Type) -> DQQuery<T> {
        let entityName:String = NSStringFromClass(entity).componentsSeparatedByString(".").last!
        return DQQuery<T>(entityName: entityName, context: dqContext.defaultContext)
    }
    
    func query<T:NSManagedObject>(entity: T.Type, context: NSManagedObjectContext) -> DQQuery<T> {
        let entityName:String = NSStringFromClass(entity).componentsSeparatedByString(".").last!
        return DQQuery<T>(entityName: entityName, context: context)
    }
    
    func insertObject<T:NSManagedObject>(entity: T.Type, block:(NSManagedObjectContext, T)->Void, sync: Bool = false, completion: ((NSManagedObjectID)->())?) {
        let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.parentContext = dqContext.defaultContext
        let entityName = NSStringFromClass(entity).componentsSeparatedByString(".").last!
        
        let writeBlock = {
            let obj = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: privateContext) as! T
            block(privateContext, obj)
            do {
                try privateContext.save()
            } catch {
                print("unable to save private context!")
            }
            self.dqContext.save()
            let objId = obj.objectID
            dispatch_async(dispatch_get_main_queue(), {
                completion?(objId)
            })
        }
        
        if sync {
            privateContext.performBlockAndWait(writeBlock)
        } else {
            privateContext.performBlock(writeBlock)
        }
    }
    
    func write(block: (NSManagedObjectContext)->Void, sync: Bool = false, completion: (()->Void)? = nil) {
        let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.parentContext = dqContext.defaultContext
        
        let writeBlock = {
            block(privateContext)
            do {
                try privateContext.save()
            } catch {
                print("unable to save private context!")
            }
            self.dqContext.save()
            dispatch_async(dispatch_get_main_queue(), {
                completion?()
            })
        }
        
        if sync {
            privateContext.performBlockAndWait(writeBlock)
        } else {
            privateContext.performBlock(writeBlock)
        }
    }
}


public class DQQuery<T:NSManagedObject> {
    let entityName: String
    let context: NSManagedObjectContext
    var predicate: NSPredicate?
    var sortDescriptors = [NSSortDescriptor]()
    var section: String?
    var limit: Int?
    var groupByKeys = [String]()
    var selectedColumns = [String]()
    var columnAliases = [String]()
    
    private var fetchRequest: NSFetchRequest {
        get {
            let request = NSFetchRequest(entityName: entityName)
            if let pred = predicate {
                request.predicate = pred
            }
            request.sortDescriptors = self.sortDescriptors
            if let limit = self.limit {
                request.fetchLimit = limit
            }
            return request
        }
    }
    
    public init(entityName: String, context: NSManagedObjectContext) {
        self.context = context
        self.entityName = entityName
    }
    
    public func filter(format: String, _ args: AnyObject...) -> Self {
        let pred = NSPredicate(format: format, argumentArray: args)
        
        if let oldPred = predicate {
            predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [oldPred, pred])
        } else {
            predicate = pred
        }
        
        return self
    }
    
    public func select(columns: [String], asNames: [String]) -> Self {
        self.selectedColumns = columns
        self.columnAliases = asNames
        return self
    }
    
    public func groupBy(key: String) -> DQGroupedQuery<T> {
        return DQGroupedQuery<T>(keys: [key], query: self)
    }
    
    public func groupBy(keys: [String]) -> DQGroupedQuery<T> {
        return DQGroupedQuery<T>(keys: keys, query: self)
    }
    
    public func orderBy(key: String, ascending: Bool = true) -> Self {
        self.sortDescriptors.append(NSSortDescriptor(key: key, ascending: ascending))
        return self
    }
    
    public func limit(limit: Int) -> Self {
        self.limit = limit
        return self
    }
    
    public func max(key: String) -> Self {
        return orderBy(key, ascending: false).limit(1)
    }
    
    public func min(key: String) -> Self {
        return orderBy(key, ascending: true).limit(1)
    }
    
    // sync fetch
    public func all() -> [T] {
        var results = [T]()
        
        context.performBlockAndWait({
            let request = self.fetchRequest
            if let r = try? self.context.executeFetchRequest(request) {
                results = r as! [T]
            }
        })
        
        return results
    }
    
    // sync count
    public func count() -> Int {
        var result = 0
        
        context.performBlockAndWait({
            let request = self.fetchRequest
            if let r = try? self.context.executeFetchRequest(request) {
                result = r.count
            }
        })
        
        return result
    }
    
    // return fist object
    public func first() -> T? {
        var result: T?
        
        context.performBlockAndWait({
            let request = self.fetchRequest
            if let r = try? self.context.executeFetchRequest(request) {
                for rr in r {
                    result = rr as? T
                    break
                }
            }
        })
        
        return result
    }
    
    
    // async fetch
    public func execute(sync sync: Bool = false, complete: ((NSManagedObjectContext, [NSManagedObjectID]) -> Void)? = nil) {
        let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.parentContext = self.context
        
        let blk = {
            let request = self.fetchRequest
            if let results = try? privateContext.executeFetchRequest(request) {
                var objectIDs = [NSManagedObjectID]()
                for r in results {
                    objectIDs.append(r.objectID)
                }
                
                complete?(privateContext, objectIDs)
            }
        }

        if sync {
            privateContext.performBlockAndWait(blk)
        } else {
            privateContext.performBlock(blk)
        }
    }
    
    public func fetchedResultsController(sectionNameKeyPath: String) -> NSFetchedResultsController {
        return NSFetchedResultsController(fetchRequest: self.fetchRequest,
            managedObjectContext: self.context,
            sectionNameKeyPath: sectionNameKeyPath, cacheName: entityName)
    }
}


public class DQGroupedQuery<T:NSManagedObject> {
    var query: DQQuery<T>
    var keys: [String]
    
    var fetchRequest: NSFetchRequest {
        let request = query.fetchRequest
        
        var properties = [AnyObject]()
        
        for (expr, alias) in zip(query.selectedColumns, query.columnAliases) {
            let expressionDescription = NSExpressionDescription()
            expressionDescription.name = alias
            expressionDescription.expression = NSExpression(format: expr)
            expressionDescription.expressionResultType = .FloatAttributeType
            properties.append(expressionDescription)
        }
        
        for key in self.keys {
            properties.append(key)
        }
        
        request.propertiesToFetch =  properties
        request.propertiesToGroupBy = self.keys
        request.resultType = .DictionaryResultType
        return request
    }
    
    init(keys: [String], query: DQQuery<T>) {
        self.query = query
        self.keys = keys
    }
    
    public func all() -> [[String: AnyObject]] {
        var result = [[String: AnyObject]]()
        query.context.performBlockAndWait({
            if let r = try? self.query.context.executeFetchRequest(self.fetchRequest) {
                result = r as! [[String: AnyObject]]
            }
        })
        return result
    }
    
    // async fetch
    public func execute(sync sync: Bool = false, complete: (([[String: AnyObject]]) -> Void)? = nil) {
        let privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.parentContext = self.query.context
        
        let blk = {
            let request = self.fetchRequest
            if let results = try? privateContext.executeFetchRequest(request) {
                complete?(results as! [[String: AnyObject]])
            } else {
                complete?([[String: AnyObject]]())
            }
        }
        
        if sync {
            privateContext.performBlockAndWait(blk)
        } else {
            privateContext.performBlock(blk)
        }
    }

}


class DQMonitor {
    let monitorBlock: ([NSObject: AnyObject])->()
    let context: NSManagedObjectContext
    
    init(block: ([NSObject: AnyObject])->(), context: NSManagedObjectContext) {
        self.monitorBlock = block
        self.context = context
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataChanged:", name: NSManagedObjectContextObjectsDidChangeNotification, object: context)
    }
    
    deinit {
//        print("deinit monitor!")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextObjectsDidChangeNotification, object: self.context)
    }
    
    @objc func dataChanged(notification: NSNotification) {
        if notification.userInfo != nil {
            monitorBlock(notification.userInfo!)
        }
    }
}


// TODO: move to separate file
public extension NSManagedObject {
    public class func dq_insertInContext(context: NSManagedObjectContext) -> Self {
        return dq_insertInContextHelper(context)
    }
    
    private class func dq_insertInContextHelper<T>(context: NSManagedObjectContext) -> T {
        let entityName = NSStringFromClass(self).componentsSeparatedByString(".").last!
        return NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: context) as! T
    }
    
    public func dq_delete() {
        self.managedObjectContext?.deleteObject(self)
    }
}


// TODO: move to separate file
public extension NSManagedObjectContext {
    public func dq_objectWithID<T: NSManagedObject>(id: NSManagedObjectID) -> T {
        return self.objectWithID(id) as! T
    }
    
    public func dq_objectsWithIDs<T: NSManagedObject>(ids: [NSManagedObjectID]) -> [T] {
        return ids.map { (id) -> T in
            dq_objectWithID(id)
        }
    }
}


