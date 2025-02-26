//
//  LargeButtonTestVC.swift
//  GXTest
//
//  Created by sgx on 2024/4/8.
//

import UIKit

open class VKButton: UIButton {
    
}

private var tapAreaExpansionInsetsKey: Void?

public extension VKButton {
    var tapAreaExpansionInsets: UIEdgeInsets {
        get {
            guard let value = objc_getAssociatedObject(self, &tapAreaExpansionInsetsKey) as? NSValue else {
                return .zero
            }
            return value.uiEdgeInsetsValue
        }
        set {
            let value = NSValue(uiEdgeInsets: newValue)
            objc_setAssociatedObject(self, &tapAreaExpansionInsetsKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if self.isHidden || !self.isUserInteractionEnabled || self.alpha < 0.01 {
            return nil
        }
        
        let expandedRect = self.bounds.inset(by: tapAreaExpansionInsets)
        
        if expandedRect.contains(point) {
            return self
        } else {
            return nil
        }
    }
}

class LargeButtonTestVC: UIViewController {
    

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
        
        
        let expandinset = UIEdgeInsets(top: -100, left: -100, bottom: 0, right: 0)
        
        let buttonRect = CGRect(x: 150, y: 200, width: 50, height: 50)
        
        
        
        view.addSubview(button)
        button.tapAreaExpansionInsets = expandinset
        button.frame = buttonRect
        
        
        let contentview = UIView()
        view.addSubview(contentview)
    
        let longpress = UILongPressGestureRecognizer(target: self, action: #selector(longpress))
        self.view.addGestureRecognizer(longpress)
        

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
    
    @objc private func longpress() {
        print("sgx >>> longpress")
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

    @objc private func appDidEnterBackground() {
        print("sgx >>> enterback")
    }
    
    deinit {
        print("sgx >> deinit")
//        NotificationCenter.default.removeObserver(self)
//        NotificationCenter.default.removeObserver(self)
//        NotificationCenter.default.removeObserver(self)
    }

}
