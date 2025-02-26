//
//  ResultBuilderVC.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/4/28.
//

import UIKit
import Foundation

struct GXCellNode {
    var name: String = ""
    

}

@resultBuilder
struct GXNodeBuilder {
    static func buildBlock(_ components: String...) -> [GXCellNode] {
        components.compactMap { component in
            GXCellNode(name: component)
        }
    }
}

class ResultBuilderVC: UIViewController {
    /// 给整个方法添加
    @GXNodeBuilder
    func cellNodeBuilder2() -> [GXCellNode] {
        "123"
        "121231"
    }
    
    /// 给方法的某个参数添加
    func cellNodeBuilder(@GXNodeBuilder _ builder: () -> [GXCellNode]) -> [GXCellNode] {
        return builder()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let cellNodes2 = cellNodeBuilder2()
        print("给整个方法添加 : \(cellNodes2)")
        print("\n")
        
        
        let cellNodes = cellNodeBuilder {
            "123"
            "456"
        }
        print("给方法的某个参数添加 : \(cellNodes)")
        print("\n")
    }
}
