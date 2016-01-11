# DQuery - data framework based on Core Data

## What is DQuery?
DQuery is a framework for querying/manipulating persistent data in iOS.
It is based on Core Data, the Official data persistent framework provided by
apple.

## Highlights
### Simple API
DQuery uses a simple DSL to do queries. You don't have to
struggle with `NSFetchRequests` and `NSPredicates` any more. Compare:

```swift
DQ.query(TodoItem).filter("isDone = false").orderBy("displayOrder").all()
```

versus

```swift
let request = NSFetchRequest(entityName: entityName)
request.predicate = NSPredicate(format: "isDone = false")
request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
try? context.executeFetchReqest(request)
// ...
```

Using DQuery saves your time and greatly improves readability.

### Concurrency done right
Concurrency in core data can be hard. DQuery manages async reads and writes
with action blocks. You provide customized writing/reading behavior in an action
block, and threads are automatically managed for you.

DQuery uses a three-layer parent-child context model to achieve concurrency,
which supports both reads and writes in the background, without blocking the UI
thread.

### 100% compatible with core data
Unlike sqlite wrappers like Realm, DQuery is completely based on core data, you
will not lose any features that core data offers, among which are
fetched results controllers, Xcode design tools and instruments etc.

## Core Concepts
### Queries
In DQuery the way to initiate a query is `DQ.query(ModelClass)`, where
`ModelClass` is the subclass of `NSManagedObject` you want to query. Predicates can
be chained on queries, e.g.:

```swift
DQ.query(ModelClass).filter("field1 = %@", val1).filter("field2 = val2")
```

You can either retrieve the result synchronously by `.all()` or asynchronously by
`.execute()`.

### Action Blocks Conventions
DQuery uses blocks to manage application logic. For example, an asynchronous
write can be initiated by calling `DQ.write()`:

```swift
let employees = [
    ["name": "Alice", "age": 20],
    ["name": "Bob", "age": 30],
    ["name": "Celine", "age": 31],
    ["name": "Dave", "age": 32],
    ["name": "Eric", "age": 21]
]

DQ.write(
    {context in
        // load test data
        for emp in employees {
            let employee = Employee.dq_insertInContext(context)
            employee.name = emp["name"] as? String
            employee.age = emp["age"] as! Int
        }
    },
    sync: true)
```

Note that the context provided by the action block is a private context running
in the background, and any code in the block is running on a background thread.

As a convention, all the action blocks (e.g. the `block` param in `write()` and
`execute()`) run in the background, and all the completion blocks
(e.g. the `completion` param in `write()` and `execute()`) run in the main
thread. This is convenient for the "do this work in the background,
and update UI when it's done" pattern.


## Q&A
### How do I use DQuery with NSFetchedResultsController?
The query object (obtained by calling `DQ.query()`) has a method
`.fetchedResultsController()`, which returns a `NSFetchedResultsController` object
for the query. Note that this can only be used in the main thread(Which is
typically what you want).

### How do I use DQuery with my own persistent store?
You can use `DQ.config([.StoreCoordinator: yourcoordinator])` to make DQuery do
queries in your already set-up coordinator. Note that `DQ.config` is designed to
be called only once.

### How do I use DQuery with my own context?
If you just want the query syntactic sugars(without writes and inserts), that's
totally fine too. Just use `DQ.query(ModelClass.self, context:yourowncontext)` in
your context. You can still get async/sync reads using `all()` and `execute()`,
respectively.

### How do I use DQuery with multiple data models?
DQ is the global singleton query object, and it works only with one data model.
But If you really need multiple models(which is rarely the case), you can
initialize your own DQAPI instances, and configure them the same way you use
`DQ.config()`.


## See Also
The three-layer parent-child context model is explained in detail [Here](https://developmentnow.com/2015/04/28/experimenting-with-the-parent-child-concurrency-pattern-to-optimize-coredata-apps/).

## TodoDemoSwift walkthrough
The `TodoDemoSwift` project is a sample project with the purpose of showing how to
work with DQuery.

## TODO
support grouping without fetchedresultscontrllers

support data migration and versioning
