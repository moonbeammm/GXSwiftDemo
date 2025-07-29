//
//  CalendarTests.swift
//  GXSwiftDemoTests
//
//  Created by 孙广鑫 on 2025/5/11.
//

//import Foundation


import XCTest
//import GXSwiftDemo

final class CalendarTests: XCTestCase {
    public var gregorian: Calendar { formatter.calendar }
    public private(set) lazy var formatter: DateFormatter = {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "zh-CN")
        c.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        c.firstWeekday = 2
        
        let t = DateFormatter()
        t.dateFormat = "yyyy-MM-dd"
        t.calendar = c
        t.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        t.locale = Locale(identifier: "zh-CN")
        return t
    }()
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
    func testMontHead() throws {
        let t = formatter.date(from: "2024-05-25")
        guard let firstDay = gregorian.firstDayOfMonth(t) else { return }
//        guard let month = gregorian.date(byAdding: .month, value: 0, to: firstDay) else { return }
        
        let currentWeekday = gregorian.component(.weekday, from: firstDay)
        var number = ((currentWeekday - gregorian.firstWeekday) + 7) % 7
        if number == 0 {
            number = 7
        }
        
        let monthHead = gregorian.date(byAdding: .day, value: -number, to: firstDay)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let string = formatter.string(from: monthHead!)
        print(" \(monthHead) ")
    }
    
    func testIntToDate() throws {
        let t = formatter.date(from: "2024-05-25")
        let unitTime = 1747122986
        let date = Date(timeIntervalSince1970: TimeInterval(unitTime))
        print(date)
    }
}

public extension Calendar {
    private static var componentsKey: UInt8 = 0
    var privateComponents: DateComponents {
        get {
            if let components = objc_getAssociatedObject(self, &Calendar.componentsKey) as? DateComponents {
                return components
            }
            let components = DateComponents()
            objc_setAssociatedObject(self, &Calendar.componentsKey, components, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return components
        }
    }
    /// 返回传入日期所在月份的1号
    func firstDayOfMonth(_ month: Date?) -> Date? {
        guard let month = month else { return nil }
        var components = self.dateComponents([.year, .month, .day, .hour], from: month)
        components.day = 1
        return self.date(from: components)
    }
}
