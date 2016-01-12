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
//  DQueryTests.swift
//
//  Created by Chi Zhang on 1/9/16.
//

import XCTest
@testable import DQuery

class DQueryTests: XCTestCase {
    override class func setUp() {
//        DQ.config([.ModelName: "TestModel", .StoreType: StoreType.InMemory, .ModelFileBundle: NSBundle(forClass: self)])
        DQ.config([.ModelName: "TestModel", .StoreType: StoreType.SQLite, .ModelFileBundle: NSBundle(forClass: self)])
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        let employees = [
            ["name": "Alice", "age": 20, "salary": 1000],
            ["name": "Bob", "age": 30, "salary": 2500],
            ["name": "Celine", "age": 31, "salary": 2300],
            ["name": "Dave", "age": 31, "salary": 2200],
            ["name": "Eric", "age": 20, "salary": 1500]
        ]
        DQ.write(
            {context in
                // delete all data
                for employee in DQ.query(Employee).all() {
                    employee.dq_delete()
                }
                // load test data
                for emp in employees {
                    let employee = Employee.dq_insertInContext(context)
                    employee.name = emp["name"] as? String
                    employee.age = emp["age"] as! Int
                    employee.salary = emp["salary"] as! Int
                }
            },
            sync: true)

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testQuerySingle() {
        let result = DQ.query(Employee).filter("name = 'Alice'").first()
        assert(result?.name == "Alice", "search for Alice")
    }
    
    func testQueryMultiple() {
        let ageLimit = 30
        let result = DQ.query(Employee).filter("age > %@", ageLimit).all()
        let aboveThirty = Set<String>(result.map {$0.name!})
        
        assert(result.count == 2, "there should be 2 employees above thirty")
        assert(!aboveThirty.contains("Bob"), "Bob should not be above thirty")
        assert(aboveThirty.contains("Celine"), "Celine should be above thirty")
        assert(aboveThirty.contains("Dave"), "Dave should be above thirty")
    }
    
    func testQueryAsync() {
        let ageLimit = 30
        // we must force this to run synchronously, 
        // or the function will return immediately and the assertions won't be able to run
        DQ.query(Employee).filter("age > %@", ageLimit).execute(sync: true) {(context, objectIds) in
            let aboveThirty = Set<String>(objectIds.map {
                let employee: Employee = context.dq_objectWithID($0)
                return employee.name!
            })
            assert(objectIds.count == 2, "there should be 2 employees above thirty")
            assert(!aboveThirty.contains("Bob"), "Bob should not be above thirty")
            assert(aboveThirty.contains("Celine"), "Celine should be above thirty")
            assert(aboveThirty.contains("Dave"), "Dave should be above thirty")
        }
    }
    
    func testDelete() {
        let query = DQ.query(Employee).filter("name = 'Alice'")
        assert(query.count() == 1, "Alice should exist before delete")
        let alice = query.first()
        let objId = alice!.objectID
        
        DQ.write(
            {context in
                let alice = context.dq_objectWithID(objId)
                alice.dq_delete()
            },
            sync: true)
        
        assert(query.count() == 0, "Alice should be deleted")
    }
    
    func testGroupBy() {
        let query = DQ.query(Employee).select(["@max.salary"], asNames: ["max_salary"]).groupBy("age")
        query.all().forEach { item in
            if item["age"] as! Int == 20 {
                assert(item["max_salary"] as! Int == 1500)
            }
        }
        
        query.execute(sync: true) { result in
            for item in result {
                if item["age"] as! Int == 30 {
                    assert(item["max_salary"] as! Int == 2500)
                }
            }
            print("result: \(result)")
        }
    }
    
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock {
//            // Put the code you want to measure the time of here.
//        }
//    }
    
}
