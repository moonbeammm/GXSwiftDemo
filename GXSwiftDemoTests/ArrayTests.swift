//
//  ArrayTests.swift
//  GXSwiftDemoTests
//
//  Created by sgx on 2024/5/11.
//

import XCTest

struct A {
    let avid: Int64
    var b: [B]?
}
struct B {
    let cid: Int64
}

final class ArrayTests: XCTestCase {

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
        // 定义一个元素结构体
        struct Element {
            var isHidden: Bool
            // 其他属性...
        }

        // 假设elements是一个包含Element的二维数组
        var elements: [[Element]] = [
            [Element(isHidden: false), Element(isHidden: true), Element(isHidden: false)],
            [Element(isHidden: true), Element(isHidden: false), Element(isHidden: false)],
            [Element(isHidden: true), Element(isHidden: true), Element(isHidden: true)]
        ]

        // 过滤掉所有isHidden为true的元素
        let filteredElements = elements.map { $0.filter { !$0.isHidden } }

        // 过滤掉所有count为0的子数组
        let finalFilteredElements = filteredElements.filter { $0.count > 0 }


        for t in finalFilteredElements {
            print("----\n")
            print("count: \(t.count)")
        }
        // 输出过滤后的结果
        print(finalFilteredElements)
        
    }
    func testStringAsInt() throws {
        let t: Any = "1"
        let m = t as? Int
        print(m)
    }
    
    func testArrayenum() throws {
        let b1 = B(cid: 1)
        let b2 = B(cid: 2)
        let b3 = B(cid: 3)
        let array = [A(avid: 1, b: [B(cid: 11),B(cid: 12),B(cid: 13)]),
                     A(avid: 2, b: [B(cid: 21),B(cid: 22),B(cid: 23)]),
                     A(avid: 3, b: [B(cid: 31),B(cid: 32),B(cid: 33)])]
        for (x, y) in array.enumerated() where y.avid == 1 {
            for (q,w) in y.b!.enumerated() where w.cid == 22 {
                print("----------------x: \(q), q: \(w)")
            }
            print("-------------x: \(x), q: \(y)")
        }
    }
    
    func testReversedAvid() throws {
        class BBPlayerEpisodeItem {
            var avid: Int64
            var cid: Int64
            
            init(avid: Int64, cid: Int64) {
                self.avid = avid
                self.cid = cid
            }
        }
        
        

        func reversedByAvid(_ episodes: [BBPlayerEpisodeItem]) -> [BBPlayerEpisodeItem] {
            var groupEpisodes: [[BBPlayerEpisodeItem]] = []
            var previousAvid: Int64?
            
            for t in episodes {
                if t.avid != previousAvid {
                    groupEpisodes.append([t])
                } else if let i = groupEpisodes.indices.last {
                    groupEpisodes[i].append(t)
                } else {
                    
                }
                previousAvid = t.avid
            }
            
            let reversed = groupEpisodes.reversed()
            let flat = reversed.flatMap { $0 }
            return flat
        }

        // 示例数据
        let a0 = BBPlayerEpisodeItem(avid: 2000, cid: 1000)
        let a1 = BBPlayerEpisodeItem(avid: 100, cid: 100)
        let a11 = BBPlayerEpisodeItem(avid: 100, cid: 1011)
        let a12 = BBPlayerEpisodeItem(avid: 100, cid: 102)
        let a2 = BBPlayerEpisodeItem(avid: 5000, cid: 50)

        let episodes = [a0, a1, a11, a12, a2]

        // 测试函数
        let sortedEpisodes = reversedByAvid(episodes)
        for episode in sortedEpisodes {
            print("avid: \(episode.avid), cid: \(episode.cid)")
        }
    }
    
    func testAttributed() throws {
        var tempText = NSAttributedString(string: "优化合集在消费侧的体验")
        while tempText.length > 4 {
//            print(tempText.length)
            tempText = tempText.attributedSubstring(from: NSRange(location: 0, length: tempText.length - 1))
//            print(tempText.length)
        }
        print("\(tempText)---------------")
    }
    
    func testAttributed2() throws {
        var tempText = NSAttributedString(string: "优化合集在消费侧的体验")
        while tempText.length > 4 {
            if let t = tempText.safe_attributedSubstring(from: NSRange(location: 0, length: tempText.length - 1)) {
                tempText = t
            } else {
                break
            }
            print(tempText.length)
        }
    }
    



}
extension NSAttributedString {
    func safe_attributedSubstring(from range: NSRange) -> NSAttributedString? {
        guard range.location >= 0, range.location + range.length <= self.length else {
            return nil
        }
        return self.attributedSubstring(from: range)
    }
}
