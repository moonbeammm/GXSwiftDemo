//
//  SheetViewController+Config.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

public class SheetViewController: UIViewController {
    internal var sizes: [SheetSize] = [.intrinsic] {
        didSet {
            self.updateOrderedSizes()
        }
    }
    internal var orderedSizes: [SheetSize] = []
    internal var currentSize: SheetSize = .intrinsic
    
    /// 手势冲突
    internal var observedViews = NSPointerArray.weakObjects()
    /// pan手势
    internal var panGestureRecognizer: UIPanGestureRecognizer?
    /// pan手势相关信息
    typealias PanGestureInfo = (isFocused: Bool, isTouchedTopbar: Bool, isPanning: Bool, firstTouchPoint: CGPoint, firstTouchSize: CGSize)
    internal var panGesture: PanGestureInfo = (false, false, false, CGPoint.zero, CGSize.zero)
    /// frame变化
    internal var displayLink : CADisplayLink?
    internal var displayLastTime : TimeInterval = 0.0
    
    internal private(set) var options: SheetOptions
        
    internal private(set) var contentViewController: SheetContentViewController
    internal var contentViewHeightConstraint: NSLayoutConstraint?
    
    internal lazy var maskView = {
        let t = UIView()
        return t
    }()
    
    public init(controller: UIViewController, sizes: [SheetSize] = [.intrinsic], options: SheetOptions? = nil) {
        self.options = options ?? SheetOptions()
        self.contentViewController = SheetContentViewController(childViewController: controller, options: self.options)
        self.sizes = sizes.count > 0 ? sizes : [.intrinsic]
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.configSubviews()
        self.updateThemeColor()
        self.resize(to: self.sizes.first ?? .intrinsic, animated: false)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateOrderedSizes()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: self.currentSize, animated: false)
    }
}

extension SheetViewController: SheetContentViewDelegate {
    /// 更新内在高度，仅设置size为`.intrinsic`才会生效
    func preferredHeightChanged(oldHeight: CGFloat, newSize: CGFloat) {
        guard newSize > options.extraHeight else {
            return
        }
        if self.sizes.contains(.intrinsic) {
            self.updateOrderedSizes()
        }
        if self.currentSize == .intrinsic, !panGesture.isPanning {
            self.resize(to: .intrinsic)
        }
    }
}
