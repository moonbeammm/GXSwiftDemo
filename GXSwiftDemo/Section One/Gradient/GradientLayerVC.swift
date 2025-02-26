//
//  GradientLayerVC.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/6/13.
//

import UIKit
import CoreFoundation

public class VKGradientView: UIView {
    // 设置变化的点位 0,0 为左下角, 1,1为右上角,
    // 默认从(0.5,0) 到(0.5,1)  即从上到下
    public init(colors: [CGColor], start: CGPoint, end: CGPoint, locations: [Double]) {
        super.init(frame: .zero)
        configGradient(colors: colors, start: start, end: end, locations: locations)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override class var layerClass: AnyClass {
        CAGradientLayer.self
    }
    
    func configGradient(colors: [CGColor], start: CGPoint, end: CGPoint, locations: [Double]) {
        let layer = self.layer as? CAGradientLayer
        layer?.locations = locations.map { NSNumber(value: $0) }
        layer?.colors = colors
        layer?.startPoint = start
        layer?.endPoint = end
    }
}


class GradientLayerVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        // MARK: - 内容的阴影
        
        let colors: [CGColor] = [
            UIColor(hex: 0x000000, alpha: 1.00 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.98 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.95 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.88 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.80 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.71 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.61 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.50 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.39 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.29 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.20 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.12 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.05 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.02 * 0.88).cgColor,
            UIColor(hex: 0x000000, alpha: 0.00 * 0.88).cgColor,
        ]

        let locations: [Double] = [
            0.00,
            0.09,
            0.17,
            0.24,
            0.31,
            0.37,
            0.44,
            0.50,
            0.56,
            0.63,
            0.69,
            0.76,
            0.83,
            0.91,
            1.00,
        ]


        
        let v = VKGradientView(colors: colors,
                               start: CGPoint(x: 0.5, y: 0.0),
                               end: CGPoint(x: 0.5, y: 1.0),
                               locations: locations)
        view.addSubview(v)
        v.frame = CGRect(x: 100, y: 100, width: 200, height: 400)
        
//        let s = UIScrollView()
//        v.addSubview(s)
//        s.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
//        s.contentSize = CGSize(width: 410, height: 30)
//
//        let t = UILabel()
//        t.text = "优化合集在消费侧的体验"
//        t.backgroundColor = .blue
//        t.frame = CGRect(x: 0, y: 0, width: 200, height: 30)
//        s.addSubview(t)
//
//        let t1 = UILabel()
//        t1.text = "优化合集在消费侧的体验"
//        t1.backgroundColor = .blue
//        t1.frame = CGRect(x: 200 + 10, y: 0, width: 200, height: 30)
//        s.addSubview(t1)
        
        

        
//        let gradientLayer = CAGradientLayer()
//        gradientLayer.locations = [NSNumber(value: 0.0),
//                                   NSNumber(value: 1.0)]
//        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
//        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
//        gradientLayer.colors = [UIColor.clear.cgColor,
//                                UIColor.white.cgColor]
//        gradientLayer.frame = v.bounds
//        v.layer.mask = gradientLayer
        
        
//        // MARK: - btn的间距设置
//        let b = UIButton(type: .custom)
//        view.addSubview(b)
//        b.frame = CGRect(x: 100, y: 200, width: 100, height: 30)
//        b.setImage(UIImage(named: "tv_icon"), for: .normal)
//        b.setTitle("哈哈", for: .normal)
//        b.backgroundColor = .red
//        
//        let spacing: CGFloat = 10.0
//        b.imageEdgeInsets = UIEdgeInsets(top: 0, left: -spacing / 2, bottom: 0, right: spacing / 2)
//        b.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: -spacing / 2)
//
//        // MARK: - view边边的阴影
//        
//        let shadowView = UIView()
//        shadowView.frame = CGRect(x: 100, y: 300, width: 100, height: 100)
//        shadowView.backgroundColor = .black
//        view.addSubview(shadowView)
//        shadowView.addLeftSideShadow()
        
    }


}
extension UIColor {
    convenience init(hex: Int, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}
extension UIView {
    func addLeftSideShadow() {
        let radius = 20.0
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 1.0
        self.layer.shadowRadius = 15
        self.layer.shadowOffset = CGSize(width: 10, height: 0)
        self.layer.masksToBounds = false


        // Create a shadow path that only covers the left side
        let shadowPath = UIBezierPath()
        shadowPath.move(to: CGPoint(x: 0, y: 0))
        shadowPath.addLine(to: CGPoint(x: -radius, y: 0))
        shadowPath.addLine(to: CGPoint(x: -radius, y: bounds.height))
        shadowPath.addLine(to: CGPoint(x: 0, y: bounds.height))
        shadowPath.close()

        self.layer.shadowPath = shadowPath.cgPath
    }
}
