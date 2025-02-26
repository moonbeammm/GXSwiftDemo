//
//  StringCountTests.swift
//  GXSwiftDemoTests
//
//  Created by sgx on 2024/4/21.
//

import XCTest

final class StringCountTests: XCTestCase {

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
        
        let str = "小白不留行"
        
        print("startIndex：\(str.startIndex)")
        print("endIndex：\(str.endIndex)")
        print("字符数：\(str.count)")
        
        print("startIndex：\(str.utf16.startIndex)")
        print("endIndex：\(str.utf16.endIndex)")
        print("字符数：\(str.utf16.count)")
        
        print("startIndex：\(str.utf8.startIndex)")
        print("endIndex：\(str.utf8.endIndex)")
        print("字符数：\(str.utf8.count)")
        
        print("startIndex：\(str.utf8CString.startIndex)")
        print("endIndex：\(str.utf8CString.endIndex)")
        print("字符数：\(str.utf8CString.count)")
        
        print("startIndex：\(str.unicodeScalars.startIndex)")
        print("endIndex：\(str.unicodeScalars.endIndex)")
        print("字符数：\(str.unicodeScalars.count)")
        
        print("UTF-16 编码单元数量：\(str.utf16.count)") // 输出：UTF-16 编码单元数量：11
        print("UTF-8 字节数量：\(str.utf8.count)") // 输出：UTF-8 字节数量：17
        

    }
    
    func testRange() throws {
        let str1 = "123456234"
        let str2 = "234"

        if let range = str1.range(of: str2) {
            let startIndex = str1.distance(from: str1.startIndex, to: range.lowerBound)
            let endIndex = str1.distance(from: str1.startIndex, to: range.upperBound)
            print("str2 在 str1 中的范围是：\(startIndex)..<\(endIndex)")
        } else {
            print("str2 不在 str1 中")
        }
    }
    
    func testIndex() throws {
        let str1 = "123456234"
        let str2 = "234"

        let endIndex = str1.index(str1.startIndex, offsetBy: 1, limitedBy: str1.endIndex)
        print("\(endIndex)")
    }
    
    func testFileManager() {
        func readLocalFile(forName name: String) -> String? {
            do {
                if let fileURL = Bundle.main.url(forResource: name, withExtension: "txt") {
                    let text = try String(contentsOf: fileURL, encoding: .utf8)
                    return text
                }
            } catch {
                print("Error reading local file: \(error)")
            }
            return nil
        }

        // 读取名为 "example" 的文本文件
        if let fileContent = readLocalFile(forName: "out") {
            print(fileContent)
            print("count: \(fileContent.count)")
            
            for index in fileContent.indices {
                print("sgx >>>> index:\(index), \(fileContent[index])")
            }
        } else {
            print("File not found or unable to read file.")
        }
    }
    
    func testHilight() {
        let texts = ["123","#sgx#","456"]
        
        var str: String = ""
        for t in texts {
            str.append(t)
        }
        print("\(str)")
        
        let replaceStr = str.replacingOccurrences(of: "#", with: "")
        print("\(replaceStr)")
        
        
    }
    
    func testNSStringRange() {
        let text: NSString = "123456"
        let t = text.range(of: "23456")
        print("length: \(text.length)")
        print(t)
    }
    
    func testUnicode() {
        let unified = "\u{309A}"
        
        let unifiedOfString = unified as String
        let unifiedOfNSString = unified as NSString
        
        print("sgx >>> \(unifiedOfString)") // ビ é
        print("sgx <<< \(unifiedOfNSString)") // ビ é
        
        let unifiedOfStringOfAppend = "@\(unifiedOfString)"
        let unifiedOfNSStringOfAppend = NSString(format: "@%@", unifiedOfNSString)
        
        print("sgx >>> \(unifiedOfStringOfAppend) -- count: \(unifiedOfStringOfAppend.count)") // ビ é
        print("sgx >>> \(unifiedOfStringOfAppend) -- utf8 count: \(unifiedOfStringOfAppend.utf8.count)") // ビ é
        print("sgx >>> \(unifiedOfStringOfAppend) -- utf16 count: \(unifiedOfStringOfAppend.utf16.count)") // ビ é
        print("sgx >>> \(unifiedOfStringOfAppend) -- unicodeScalars count: \(unifiedOfStringOfAppend.unicodeScalars.count)") // ビ é
        print("sgx <<< \(unifiedOfNSStringOfAppend) -- length: \(unifiedOfNSStringOfAppend.length)") // ビ é
        
        print(unified.count)
        print(unified.utf8.count)
        print(unified.utf16.count)
        print(unified.unicodeScalars.count)
    }
    
    func test309AOfNSString() {
        let t = "\u{309A}"
        
        let tOfString = t as NSString
        print("\n \(tOfString) 的 count \(tOfString.length)")
        
        let tOfStringOfAppend = "a\(tOfString)" as NSString
        print("\n \(tOfStringOfAppend) 的 count \(tOfStringOfAppend.length)")
        
        
    }
    
    func test309A() {
        let t = "\u{309A}"
        
        let tOfString = t as String
        
        print("\n \(tOfString) 的 count \(tOfString.count)") // 默认utf-8
        print("\n \(tOfString) 的 utf8 count \(tOfString.utf8.count)")
        print("\n \(tOfString) 的 utf16 count \(tOfString.utf16.count)")
        print("\n \(tOfString) 的 unicodeScalars count \(tOfString.unicodeScalars.count)")
        
        let tOfStringOfAppend = "a\(tOfString)"
        
        print("\(tOfStringOfAppend) 的 count \(tOfStringOfAppend.count)")
        print("\n \(tOfStringOfAppend) 的 utf8 count \(tOfStringOfAppend.utf8.count)")
        print("\n \(tOfStringOfAppend) 的 utf16 count \(tOfStringOfAppend.utf16.count)")
        print("\n \(tOfStringOfAppend) 的 unicodeScalars count \(tOfStringOfAppend.unicodeScalars.count)")
        
        for t in tOfStringOfAppend.unicodeScalars {
            print("sgx >>>> \(t)")
        }
        
        struct Desc {
            let text: String
            let type: Int
        }
        
        let infos = [Desc(text: "记忆不吃鱼", type: 1),
                     Desc(text: "-", type: 0),
                     Desc(text: "\(tOfString)小白不留行", type: 1),
                     Desc(text: "-", type: 0),
                     Desc(text: "玄云", type: 1)]
        
        let descStr = infos.reduce("") { result, desc in
            let text = desc.type == 1 ? "@\(desc.text)" : desc.text
            return result + text
        }
        
        print("descStr:\(descStr)--count:\(descStr.utf16.count)")
        
        
        var offset = 0
        
        infos.forEach { desc in
            let text = desc.text
            if desc.type != 1 {
                offset += text.utf16.count
            } else {
                if let startIndex = descStr.index(descStr.startIndex, offsetBy: offset, limitedBy: descStr.endIndex),
                   let endIndex = descStr.index(startIndex, offsetBy: text.utf16.count + 1, limitedBy: descStr.endIndex) {
                    
                    print("text:\(text)--text count:\(text.utf16.count)")
                    
                    let range = NSRange(startIndex ..< endIndex, in: descStr)
                    
                    print("sgx >> text:\(text) Range: \(range)")
                    let descStrOfNSString = descStr as NSString
                    let textOfNSString = descStrOfNSString.substring(with: range)
                    print("sgx textOfNSString:\(textOfNSString)")
                }
                offset += text.utf16.count + 1
            }
        }
    }
    
    func testPrintUnicode() {
        let character = "‼"
        for scalar in character.unicodeScalars {
            print("\(scalar) 的 Unicode 编码为 \(scalar.value)")
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    func testInterval() throws {
        let index = 1
        print("--------")
        for i in 0..<index {
            print("---\(i)")
        }
        //--------
        //---0
        
        let index1 = 0
        print("111--------")
        for i in 0..<index1 {
            print("111---\(i)")
        }
        //111--------
        
//        let index2 = -1
//        print("111--------")
//        for i in 0..<index2 { // Thread 1: Fatal error: Range requires lowerBound <= upperBound
//            print("111---\(i)")
//        }
        // crash
    }
    
    func testSorted() throws {
        let offsets = [0: 0.0, 1: 60.0, 2: 90.0]

        func getOffsetIndex(for offset: CGFloat) -> Int {
            // 获取所有键值并排序
            let sortedKeys = offsets.keys.sorted()
            
            // 二分查找合适的键值
            var low = 0
            var high = sortedKeys.count - 1
            
            while low <= high {
                let mid = (low + high) / 2
                let sortedKey = sortedKeys[mid]
                let midValue = offsets[sortedKey] ?? -1
                
                if offset == midValue {
                    return sortedKeys[mid]
                } else if offset > midValue {
                    low = mid + 1
                } else {
                    high = mid - 1
                }
            }
            
            // 返回最后一个符合条件的键值
            return sortedKeys[max(0, high)]
        }

        // 测试
        assert(getOffsetIndex(for: -10) == 0)
        assert(getOffsetIndex(for: 0) == 0)
        assert(getOffsetIndex(for: 20) == 0)
        assert(getOffsetIndex(for: 60) == 1)
        assert(getOffsetIndex(for: 70) == 1)
        assert(getOffsetIndex(for: 90) == 2)
        assert(getOffsetIndex(for: 100) == 2)
    }
    

    func testReadableString() throws {
        print(5.readableString)
        assert(5.readableString == "0:05")
        print(50.readableString)
        assert(50.readableString == "0:50")
        print(120.readableString)
        assert(120.readableString == "2:00")
        print(700.readableString)
        assert(700.readableString == "11:40")
        print(3600.readableString)
        assert(3600.readableString == "01:00:00")
        print(36032423420.readableString)
        /*
         0:05
         0:50
         2:00
         11:40
         01:00:00
         */
    }
    func testStringParams() throws {
        assert("https://www.baidu.com".bfc_appendParams(["a":"123"]) == "https://www.baidu.com?a=123")
        assert("https://www.baidu.com/".bfc_appendParams(["a":"123"]) == "https://www.baidu.com/?a=123")
        assert("https://www.baidu.com?a=345".bfc_appendParams(["a":"123"]) == "https://www.baidu.com?a=345")
        assert("https://www.baidu.com/?a=345".bfc_appendParams(["a":"123"]) == "https://www.baidu.com/?a=345")
    }
}
extension Int {
    var readableString: String {
        if self == 0 {
            return "--"
        }
        
        let seconds = self % 60
        let minutes = (self / 60) % 60
        let hours = self / 3600
        
        if hours > 0 {
            return String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
        } else {
            return "\(minutes):\(String(format: "%02ld", seconds))"
        }
    }
}

extension String {
    func bfc_appendParams(_ params: [String: String]) -> String {
        guard var urlComponents = URLComponents(string: self) else {
            return self
        }
        
        var queryItems = urlComponents.queryItems ?? []
        
        for (key, value) in params {
            // 检查是否已经有该参数
            if !queryItems.contains(where: { $0.name == key }) {
                let queryItem = URLQueryItem(name: key, value: value)
                queryItems.append(queryItem)
            }
        }
        
        urlComponents.queryItems = queryItems
        
        return urlComponents.url?.absoluteString ?? self
    }
}
