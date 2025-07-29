//
//  GXStackVC.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/7/17.
//

class Example {
    var value: Int = 0

    func modifyValue() {
        // 修改 value
        value += 1
    }

    func nestedAccess() {
        let closure = {
            // 在闭包中同时访问和修改 value
            self.modifyValue()
            print(self.value)
        }

        // 在全局并发队列中调用闭包
        DispatchQueue.global().async {
            closure()
        }
    }
}

import UIKit
class GXStackVC: UIViewController {
    lazy var label: UILabel = {
        let t = UILabel()
        t.text = "123收到了封建势力党风建设老大腹肌是老大就撒溜达鸡算啦电极法算啦电极法算啦登记发啦生发剂"
        t.numberOfLines = 0
        return t
    }()
    lazy var label1: UILabel = {
        let t = UILabel()
        t.text = "123收到了封建势力党风建设老大腹肌是老大就撒溜达鸡算啦电极法算啦电极法算啦登记发啦生发剂"
        t.numberOfLines = 0
        return t
    }()
    lazy var button: UIButton = {
        let t = UIButton(type: .custom)
        t.setTitle("dslfa", for: .normal)
        t.addTarget(self, action: #selector(buttonClick), for: .touchUpInside)
        t.backgroundColor = .red
        return t
    }()
    @objc
    func buttonClick() {
        button.isSelected = !button.isSelected
        label.isHidden = !button.isSelected
        label1.isHidden = !button.isSelected
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        let t = UIStackView()
        t.axis = .vertical
        t.distribution = .fillProportionally
        t.alignment = .leading
        t.backgroundColor = .blue
        t.spacing = 10
        t.addArrangedSubview(label)
        t.addArrangedSubview(label1)
        t.addArrangedSubview(button)
        
        label.isHidden = true
        
        view.addSubview(t)
        t.translatesAutoresizingMaskIntoConstraints = false
        t.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 200).isActive = true
        t.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 200).isActive = true
        t.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        let q = Example()
        DispatchQueue.global().async {
            for _ in 0..<100 {
                q.nestedAccess()
            }
        }
        
        configRendering()
    }
}


extension GXStackVC {
    func configRendering() {
        let image1 = UIImage(named: "tv_icon")
        let imageView1 = UIImageView()
        imageView1.contentMode = .scaleAspectFit
        imageView1.image = image1
        
        let image2 = UIImage(named: "tv_icon")?.withRenderingMode(.alwaysTemplate)
        let imageView2 = UIImageView()
        imageView2.contentMode = .scaleAspectFit
        imageView2.image = image2
        print("\(imageView2.tintColor)")
        
        let image3 = UIImage(named: "tv_icon")?.withRenderingMode(.alwaysTemplate)
        let imageView3 = UIImageView()
        imageView3.contentMode = .scaleAspectFit
        imageView3.tintColor = .red
        imageView3.image = image3
        print("\(imageView3.tintColor)")
        
        self.view.addSubview(imageView1)
        imageView1.frame = .init(x: 100, y: 100, width: 30, height: 30)
        self.view.addSubview(imageView2)
        imageView2.frame = .init(x: 100, y: 150, width: 30, height: 30)
        self.view.addSubview(imageView3)
        imageView3.frame = .init(x: 100, y: 200, width: 30, height: 30)
    }
}
