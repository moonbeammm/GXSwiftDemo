//
//  PointerArrayTestVC.swift
//  GXTest
//
//  Created by sgx on 2023/11/28.
//

import UIKit

class PointerArrayTestVC: UIViewController {
    private lazy var button: VKButton = {
        let button = VKButton(type: .custom)
        button.addTarget(self, action: #selector(thirdLineBtnAction), for: .touchUpInside)
        button.backgroundColor = .red
        return button
    }()
    var obj: NSObject?
    let pointerArray = NSPointerArray.weakObjects()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        view.addSubview(button)
        button.frame = CGRect(x: 150, y: 200, width: 50, height: 50)
        

        // 创建一个NSPointerArray实例，指定存储的对象类型为AnyObject，并设置弱引用选项
        

        // 创建一个对象
        
        
        obj = NSObject()
        // 将对象添加到NSPointerArray中
        if let t = obj {
            pointerArray.addPointer(Unmanaged.passUnretained(t).toOpaque())
        }

        // 打印数组中的元素数量
        print("Number of elements in pointerArray: \(pointerArray.count)")
        for t in pointerArray.allObjects {
            print("t:=------ \(t)")
        }
        // 释放对象
        obj = nil
    }

    @objc private func thirdLineBtnAction() {
        pointerArray.compact()
        // 打印数组中的元素数量
        print("Number of elements in pointerArray after releasing obj: \(pointerArray.allObjects) \(pointerArray.count)")
        for t in pointerArray.allObjects {
            print("t:=------ \(t)")
        }
        print("sgx >>> enterback")
    }
}
