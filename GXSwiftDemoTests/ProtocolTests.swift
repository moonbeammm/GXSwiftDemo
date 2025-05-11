//
//  ProtocolTests.swift
//  GXSwiftDemoTests
//
//  Created by 孙广鑫 on 2025/4/10.
//

import XCTest

protocol GXProtocol {
    
}
class GXBase: NSObject {
    var age: Int = 0
}
class GXA: GXBase, GXProtocol {
    
}
class GXB: GXBase, GXProtocol {
    
}
class GXC: GXBase, GXProtocol {
    
}
final class ProtocolTests: XCTestCase {
    var modules: [GXProtocol] = [GXA(),GXB(),GXC()]
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    func testMapArray() throws {
        
        func replaceFirst(module: GXProtocol) {
            let t = findFirst(type1: type(of: module))
            print("----\(t)---\(type(of: self.modules[0])) --- \(type(of: module)) -- \(module.self)")
        }
        func findFirst(type1: GXProtocol.Type) {
            let t = modules.firstIndex(where: { type(of: $0) == type1 })
            print("----\(t)---\(type(of: self.modules[0])) ")
        }
        let gxb = GXB()
        replaceFirst(module: gxb)
        findFirst(type1: GXC.self)
        
    }
    
    func testCrash() throws {
        var modules: [GXBase]? = nil
        let specialTag = modules?.first(where: { $0.age == 100 })?.age
        print("----\(specialTag)---\(type(of: self.modules[0])) ")
    }
    
}
//public func replaceFirstModule(_ module: AnyObject, _ animation: Bool = true) {
//    guard let module = module as? (any VDModuleProtocol),
//          var modules = self.modules,
//          let index = modules.firstIndex(where: { type(of: $0) == type(of: module) }) else {
//        return
//    }
//    modules[index] = module
//    updates(modules, animation)
//}
