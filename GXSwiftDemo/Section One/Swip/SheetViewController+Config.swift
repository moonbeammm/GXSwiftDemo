//
//  SheetViewController+Config.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

public struct SheetOptions {
    /// 顶部bar的高度，如果为0则不展示
    public var pullBarViewHeight: CGFloat = 24
    /// 顶部滑动热区，滑动此热区时不响应scrollView滚动
    public var pullBarEventHeight: CGFloat = 40
    
    public var transitionAnimationOptions: UIView.AnimationOptions = [.curveEaseOut]
    public var transitionDampening: CGFloat = 0.7
    /// Transition velocity base value. Automatically adjusts based on the initial size of the sheet.
    public var transitionVelocity: CGFloat = 0.8
    /// Default value 500, greater value will require more velocity to dismiss. Lesser values will do opposite.
    public var pullDismissThreshod: CGFloat = 500.0
    /// 向下滑动多少比例size变化到下个状态
    public var dismissScale: CGFloat = 0.3
    /// 业务方自定义高度
    /// - Parameters:
    ///     - extraHeight: 额外高度，resultH = extraHeight + preferredHeight
    public var preferredHeight: ((CGFloat) -> CGFloat)?
    
    // life cycle
    /// 弹窗即将展示
    public var willShow: ((SheetViewController) -> Void)?
    /// 弹窗已经展示
    public var didShow: ((SheetViewController) -> Void)?
    /// 弹窗即将消失
    public var willDismiss: ((SheetViewController) -> Void)?
    /// 弹窗已经消失
    public var didDismiss: ((SheetViewController) -> Void)?
    /// 更新多主题
    /// - Parameters:
    ///  - mask: 蒙层
    ///  - container: 弹窗容器
    ///  - indicator：顶部条
    public var updateTheme: ((UIView, UIView, UIView) -> Void)?
    /// size模式变化
    public var sizeModeChanged: ((SheetViewController, SheetSize, CGFloat) -> Void)?
    /// VKSwipeVC.view.frame变化
    /// - Parameters:
    ///   - rect: new frame
    ///   - offset: 滑动的偏移量,只有手势拖动时才大于0.如果是动画则为0
    public var rectChanged: ((SheetViewController,CGRect, CGFloat) -> Void)?
}

public enum SheetSize: Equatable {
    case intrinsic
    case specify(CGFloat)
    case fullscreen
    case percent(Float)
    case marginFromTop(CGFloat)
}

extension SheetViewController {
    func willShow() {
        startFrameAnimation()
        print("sgx >> will show")
        self.options.willShow?(self)
    }
    func didShow() {
        stopFrameAnimation()
        print("sgx >> did show")
        self.options.didShow?(self)
    }
    func willDismiss() {
        print("sgx >> will dismiss")
        startFrameAnimation()
        self.options.willDismiss?(self)
    }
    func didDismiss() {
        stopFrameAnimation()
        print("sgx >> did dismiss")
        self.options.didDismiss?(self)
    }
    func updateTheme(mask: UIView, container: UIView, indicator: UIView) {
        print("sgx >> updateTheme")
        self.options.updateTheme?(mask, container, indicator)
    }
    func sizeModeChanged(_ old: SheetSize, _ new: SheetSize) {
        if old != new {
            print("sgx >> sizeModeChanged old:\(old), new: \(new)")
            self.options.sizeModeChanged?(self, new, height(for: new))
        }
    }
    func rectChanged(frame: CGRect, offset: CGFloat) {
        print("sgx >> rectChanged! frame:\(frame) offset: \(offset)")
        self.options.rectChanged?(self, frame, offset)
    }
    func panBegan() {
        print("sgx >> panBegan isFocused:\(panGesture.isFocused) isTouchedTopbar:\(panGesture.isTouchedTopbar) isPanning:\(panGesture.isPanning), firstTouchPoint:\(panGesture.firstTouchPoint) firstTouchSize:\(panGesture.firstTouchSize)")
    }
    func panChanged() {
        print("sgx >> panChanged")
    }
    func panEnded() {
        print("sgx >> panEnded")
    }
    func panCancelOrFailed() {
        print("sgx >> panCancelOrFailed")
    }
}
