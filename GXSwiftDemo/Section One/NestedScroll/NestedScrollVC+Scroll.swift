//
//  VDDetailContainerBlocV3+Scroll.swift
//  BBVideoDetail
//
//  Created by 孙广鑫 on 2025/7/28.
//

import UIKit
import Stevia

enum LayoutType {
    case ceillingToMax // 最大高度到最大，最小高度粉条
    case ceillingToHorizon // 最大高度16：9，最小高度粉条
    case horizonToMax // 最大高度到最大，最小高度16：9
    case horizonToHorizon // 最大最小都是16：9
}

struct LayoutInfo {
    var minHeight: CGFloat
    var maxHeight: CGFloat
    var extraHeight: CGFloat
    var extraOffset: CGFloat
    init(min: CGFloat, max: CGFloat,
         extraHeight: CGFloat,
         extraOffset: CGFloat = 0) {
        self.minHeight = min
        self.maxHeight = max
        self.extraHeight = extraHeight
        self.extraOffset = extraOffset
    }
    func isEqual(_ object: LayoutInfo) -> Bool {
        if abs(minHeight - object.minHeight) < 0.01 &&
           abs(maxHeight - object.maxHeight) < 0.01 &&
           abs(extraHeight - object.extraHeight) < 0.01 &&
           abs(extraOffset - object.extraOffset) < 0.01 {
            return true
        } else {
            return false
        }
    }
}

// MARK: Update Layout Info

extension VDDetailContainerBlocV3 {
    /// 更新详情页布局
    /// - Parameters:
    /// - offset: nil: 保持当前播放器高度；0：展开到最大高度；
    func _changeLayoutType(to type: LayoutType, offset: CGFloat? = nil, updateCanvas: Bool = true, animation: Bool = false) {
        guard let view = contentVC?.view else {
            return
        }
        let defaultHeight = self.layoutInfo.maxHeight + self.layoutInfo.extraHeight
        let lastPlayerHeight = playerVC.view.heightConstraint?.constant ?? defaultHeight
        
        self.layoutType = type
        self.layoutInfo = layoutInfo(with: type)
        
        // 简介容器可滚动区域
        let offsetRange = getOffsetRange(layoutInfo)
        
        let pullDismissThreshod = (view.bounds.height - layoutInfo.maxHeight - layoutInfo.extraHeight - Constant.safeAreaTop) / 4.0
        
        let keepOffset = layoutInfo.maxHeight + layoutInfo.extraHeight - lastPlayerHeight
        // 未指定offset则保持之前的offset
        var newOffset = offset ?? keepOffset
        newOffset = newOffset > offsetRange.max ? 0.0 : newOffset
        newOffset = newOffset < 0.0 ? 0.0 : newOffset
        
        //VKLogInfo(.common, .layout, "change layout type to: \(type)! 指定offset:\(offset ?? -1) newOffset:\(newOffset) min:\(offsetRange.min) max:\(offsetRange.max) last player height:\(lastPlayerHeight) pullDismissThreshod:\(pullDismissThreshod) animation: \(animation)")
        
        self.pullDismissThreshod = pullDismissThreshod
        scrollManager.offsetRange = offsetRange
        scrollManager.offset = newOffset
        reloadConstraints(with: newOffset, info: layoutInfo, updateCanvas: updateCanvas, animation: animation)
    }
}

// MARK: Scroll

extension VDDetailContainerBlocV3 {
    func onPanGestureEndScroll(_ offset: CGFloat, velocity: CGFloat) {
        //VKLogInfo(.common, .layout, "on pan gesture end scroll offset:\(offset) velocity:\(velocity)")
        guard offset < 0 else { return }
        if offset <= -pullDismissThreshod || velocity > 600 { // dismiss
            guard let view = self.tabContainerVC.view else { return }
            let offset = view.bounds.height
            // self.draggingFlow?.onNext(.dismiss)
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let view = self?.tabContainerVC.view else { return }
                view.alpha = 0.0
                view.transform = CGAffineTransform(translationX: 0, y: offset)
            }
        } else {
            curveEaseOutAnimation(alpha: 1.0, offset: offset, animation: nil) { [weak self] in
                guard let self = self else { return }
                guard let view = self.tabContainerVC.view else { return }
                view.alpha = 1.0
                view.transform = CGAffineTransform.identity
                
                self.scrollManager.offset = 0.0
                self.onPanGestureDidScroll(with: 0.0, info: self.layoutInfo)
                //self.draggingFlow?.onNext(.recover)
            }
        }
    }
    
    func onPanGestureDidScroll(with offset: CGFloat, info: LayoutInfo) {
        //draggingFlow?.onNext(.dragging)
        reloadConstraints(with: offset, info: info)
    }

    func onPanGestureBeginScroll(_ info: LayoutInfo) {
        //draggingFlow?.onNext(.begin)
        let draggingDownEnable: Bool = draggingDownEnable()
        updateOffsetRange(info, draggingDownEnable: draggingDownEnable)
    }
}

// MARK: Update Constraints

extension VDDetailContainerBlocV3 {
    private func reloadConstraints(with offset: CGFloat, info: LayoutInfo, updateCanvas: Bool = true, animation: Bool = false) {
        var playerHeight: CGFloat
        var topMargin = info.maxHeight + info.extraHeight + Constant.safeAreaTop - offset
        
        if topMargin <= (Constant.horizonHeight + Constant.safeAreaTop) {
            // 在小于16：9高度区域滚动
            playerHeight = topMargin - Constant.safeAreaTop
        } else if topMargin < (Constant.horizonHeight + info.extraHeight + Constant.safeAreaTop),
                  topMargin > (Constant.horizonHeight + Constant.safeAreaTop) {
            // 在黑条范围内滚动
            playerHeight = Constant.horizonHeight
        } else if info.maxHeight > Constant.horizonHeight,
                  topMargin >= (Constant.horizonHeight + info.extraHeight + Constant.safeAreaTop),
                  topMargin < (info.maxHeight + info.extraHeight + Constant.safeAreaTop) {
            // 在大于黑条，小于竖屏最大高度区域滚动（应该只有竖屏视频才会进）
            playerHeight = topMargin - info.extraHeight - Constant.safeAreaTop
        } else {
            // 在超出播放器最大高度区域滚动
            playerHeight = info.maxHeight
        }
        if isFullScreen {
            topMargin = isVerticalScreen ? Constant.SCREEN_HEIGHT : Constant.SCREEN_WIDTH
        }
        
        // VKLogInfo(.common, .layout, "reload constraints! to playerheight:\(playerHeight) to topmargin:\(topMargin)")
        
        updateConstaintes(playerHeight, topMargin, info, updateCanvas, animation)
        //constraintsChanged(offset, playerHeight, topMargin, info)
//        reloadRenderMode()
        
        contentVC?.setNeedsStatusBarAppearanceUpdate()
        contentVC?.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    private func updateConstaintes(_ playerHeight: CGFloat, _ topMargin: CGFloat, _ info: LayoutInfo, _ updateCanvas: Bool = true, _ animation: Bool) {
        let t1 = updatePlayerConstraintsIfNeeded(playerHeight, updateCanvas: updateCanvas, info: info)
        let t2 = updateTabContainerConstraintsIfNeeded(topMargin, info: info)
        if (t1 || t2) && animation {
            //VKLogInfo(.common, .layout, "update constraints animation!")
            UIView.animate(withDuration: 0.15) { [weak self] in
                self?.contentVC?.view.layoutIfNeeded()
            }
        }
    }
    
    private func updatePlayerConstraintsIfNeeded(_ playerHeight: CGFloat,updateCanvas: Bool = true, info: LayoutInfo) -> Bool {
        guard let contentVC = contentVC else {
            return false
        }
        playerVC.view.topConstraint?.constant = Constant.safeAreaTop
        if isFullScreen {
            if let topConstraint = playerVC.view.topConstraint {
                topConstraint.constant = isVerticalScreen ? 0 : Constant.safeAreaTop
            }
            if let heightConstraint = playerVC.view.heightConstraint {
                heightConstraint.isActive = false
            }
            if let bottomConstraint = playerVC.view.bottomConstraint {
                bottomConstraint.isActive = true
            } else {
                let playerViewBottomConstraint = playerVC.view.bottomAnchor.constraint(equalTo: contentVC.view.bottomAnchor)
                playerViewBottomConstraint.priority = UILayoutPriority.required
                playerViewBottomConstraint.isActive = true
            }
        } else {
            if let topConstraint = playerVC.view.topConstraint {
                topConstraint.constant = Constant.safeAreaTop
            }
            if let bottomConstraint = playerVC.view.bottomConstraint {
                bottomConstraint.isActive = false
            }
            let containerHeight = playerHeight + info.extraHeight
            let currentHeight = playerVC.view.heightConstraint?.constant ?? 0.0
            guard abs(currentHeight - containerHeight) >= 1.0 else {
                // VKLogInfo(.common, .layout, "player约束无变更，丢弃此次更新")
                return false
            }
            if let heightConstraint = playerVC.view.heightConstraint {
                heightConstraint.isActive = true
                heightConstraint.constant = containerHeight
            } else {
                let playerViewHeightConstraint = playerVC.view.heightAnchor.constraint(equalToConstant: containerHeight)
                playerViewHeightConstraint.priority = UILayoutPriority.required
                playerViewHeightConstraint.isActive = true
            }
//            if updateCanvas {
//                updatePlayerCanvasRect(.init(x: 0, y: 0, width: SCREEN_WIDTH, height: containerHeight))
//            }
        }
        return true
    }
    
    private func updateTabContainerConstraintsIfNeeded(_ topMargin: CGFloat, info: LayoutInfo) -> Bool {
        var heightDiff: CGFloat
        if isFullScreen {
            heightDiff = Constant.SCREEN_WIDTH - (Constant.SCREEN_HEIGHT - Constant.horizonHeight)
        } else {
//            heightDiff = min(topMargin, info.maxHeight + info.extraHeight + Constant.safeAreaTop)
            heightDiff = info.minHeight + info.extraHeight + Constant.safeAreaTop - info.extraOffset
        }
        let oldTopMargin = tabContainerVC.view.topConstraint?.constant ?? 0.0
        let oldHeight = tabContainerVC.view.heightConstraint?.constant ?? 0.0
        guard abs(oldTopMargin - topMargin) >= 1.0 || abs(oldHeight + heightDiff) >= 1.0 else {
            // VKLogInfo(.common, .layout, "tab container约束无变更，丢弃此次更新")
            return false
        }
//        print("sgx >>>>> height \(heightDiff) \(topMargin)")
        tabContainerVC.view.topConstraint?.constant = topMargin
        // 没用用底部约束的原因是转屏全屏时高度会变成0
        tabContainerVC.view.heightConstraint?.constant = -heightDiff
        return true
    }
}

// MARK: Helper

extension VDDetailContainerBlocV3 {
    /// 更新tabContainer滚动范围
    /// 可拖拽：min：屏幕底部；max：播放器最小高度
    /// 不可拖拽：min：播放器最大高度；max：播放器最小高度
    private func updateOffsetRange(_ info: LayoutInfo, draggingDownEnable: Bool) {
        let range = getOffsetRange(info, draggingDownEnable: draggingDownEnable)
        //VKLogInfo(.common, .layout, "update offset range:\(range)")
        scrollManager.offsetRange = range
    }

    /// 简介tab能否向下拉超出播放器最大高度
    func draggingDownEnable() -> Bool {
        guard MockInfo.ff.canDraggingToStory else {
            return false
        }
        return true
    }
    
    private func getOffsetRange(_ layout: LayoutInfo, draggingDownEnable: Bool = true) -> (min: CGFloat, max: CGFloat) {
        guard let view = contentVC?.view else {
            return (min: 0, max: 0)
        }
        let maxOffset = layout.maxHeight + layout.extraOffset - layout.minHeight
        var minOffset: CGFloat
        if draggingDownEnable {
            minOffset = -(view.bounds.height - layout.maxHeight - layout.extraHeight - Constant.safeAreaTop)
        } else {
            minOffset = 0.0
        }
        return (min: minOffset, max: maxOffset)
    }
    
    private func layoutInfo(with type: LayoutType) -> LayoutInfo {
        var layoutInfo: LayoutInfo
        let maxHeight = Constant.SCREEN_WIDTH / minRatio()
        switch type {
        case .horizonToMax:
            layoutInfo = LayoutInfo(min: Constant.horizonHeight,
                                    max: maxHeight,
                                    extraHeight: blackBarHeight)
        case .ceillingToMax:
            layoutInfo = LayoutInfo(min: Constant.ceilingHeight,
                                    max: maxHeight,
                                    extraHeight: blackBarHeight,
                                    extraOffset: blackBarHeight)
        case .horizonToHorizon:
            layoutInfo = LayoutInfo(min: Constant.horizonHeight,
                                    max: Constant.horizonHeight,
                                    extraHeight: blackBarHeight)
        case .ceillingToHorizon:
            layoutInfo = LayoutInfo(min: Constant.ceilingHeight,
                                    max: Constant.horizonHeight,
                                    extraHeight: blackBarHeight,
                                    extraOffset: blackBarHeight)
        }
        return layoutInfo
    }
}

extension VDDetailContainerBlocV3 {
    private func curveEaseOutAnimation(alpha: CGFloat, offset: CGFloat, duration: CGFloat = 0.15, animation: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.8,
            options: [.curveEaseOut],
            animations: { [weak self] in
                guard let view = self?.tabContainerVC.view else { return }
                view.alpha = alpha
                view.transform = CGAffineTransform(translationX: 0, y: offset)
                animation?()
            },
            completion: { _ in
                completion?()
            }
        )
    }
    
    var isFullScreen: Bool {
        return mockInfo.isFullscreen
    }
    
    var isVerticalScreen: Bool {
        return mockInfo.videoWidth < mockInfo.videoHeight
    }
    
    private func minRatio() -> CGFloat {
//        if forceHorizonRatio {
//            return Constant.maxRatio
//        } else {
            let minRatio = Constant.SCREEN_WIDTH / (Constant.SCREEN_HEIGHT - Constant.bottomMinMargin - Constant.safeAreaTop - blackBarHeight)
            let currentRatio = mockInfo.videoWidth / mockInfo.videoHeight
            let result = max(minRatio, min(currentRatio, Constant.maxRatio))
            return result
//        }
    }
    
    private func getCanvasInset() -> UIEdgeInsets {
        if isFullScreen {
            return .zero
        } else {
            let halfScreenBottomExtraHeight = blackBarHeight
            return .init(top: 0, left: 0, bottom: halfScreenBottomExtraHeight, right: 0)
        }
    }
    
    /// 获取调整后的播放器 canvas rect
    private func getAdjustedCanvasRect(from rect: CGRect) -> CGRect {
        var canvasRect: CGRect
        let inset = getCanvasInset()
        canvasRect = rect.inset(by: inset)
        return canvasRect
    }
    
    /// 更新画布尺寸
    /// - Params: isNeedAdjust 是否需要自动适配，默认true
    /// 如重置场景无需自动适配，则传false
    /// 如传入的为播放器容器的rect，则传true
    func updatePlayerCanvasRect(_ new: CGRect, isNeedAdjust: Bool = true) {
        // VKLogInfo(.common, .layout, "update player canvas rect：\(new)")
//        var canvasRect: CGRect
//        if isNeedAdjust {
//            canvasRect = getAdjustedCanvasRect(from: new)
//        } else {
//            canvasRect = new
//        }
        // playerBloc.player.setCanvasRect(canvasRect)
    }

    /// 黑边实验
    /// 【【播放器专项】播放详情页增加黑边强化播控+页面改浮层_播放】
    /// https://www.tapd.cn/tapd_fe/20055921/story/detail/1120055921004635337
    var blackBarHeight: CGFloat {
        if MockInfo.hitBlackBar {
            return Constant.extraHeight
        } else {
            return 0.0
        }
    }
}

// MARK: Constraints

extension VDDetailContainerBlocV3 {
    func configSubviews() {
        guard let contentVC = contentVC else { return }

        playerVC.willMove(toParent: contentVC)
        contentVC.addChild(playerVC)
        playerVC.didMove(toParent: contentVC)
        tabContainerVC.willMove(toParent: contentVC)
        contentVC.addChild(tabContainerVC)
        tabContainerVC.didMove(toParent: contentVC)

        contentVC.view.addSubview(playerVC.view)
        playerVC.view.addSubview(blackBar)
        contentVC.view.addSubview(tabContainerVC.view)


        playerVC.view.translatesAutoresizingMaskIntoConstraints = false
        playerVC.view.topAnchor.constraint(equalTo: contentVC.view.topAnchor, constant: Constant.safeAreaTop).isActive = true
        playerVC.view.leftAnchor.constraint(equalTo: contentVC.view.leftAnchor).isActive = true
        playerVC.view.rightAnchor.constraint(equalTo: contentVC.view.rightAnchor).isActive = true
        
        blackBar.translatesAutoresizingMaskIntoConstraints = false
        blackBar.bottomAnchor.constraint(equalTo: playerVC.view.bottomAnchor).isActive = true
        blackBar.leftAnchor.constraint(equalTo: playerVC.view.leftAnchor).isActive = true
        blackBar.rightAnchor.constraint(equalTo: playerVC.view.rightAnchor).isActive = true
        blackBar.heightAnchor.constraint(equalToConstant: blackBarHeight).isActive = true

        tabContainerVC.view.translatesAutoresizingMaskIntoConstraints = false
        tabContainerVC.view.topAnchor.constraint(equalTo: contentVC.view.topAnchor).isActive = true
        tabContainerVC.view.leftAnchor.constraint(equalTo: contentVC.view.leftAnchor).isActive = true
        tabContainerVC.view.widthAnchor.constraint(equalToConstant: Constant.SCREEN_WIDTH).isActive = true
        tabContainerVC.view.heightAnchor.constraint(equalTo: contentVC.view.heightAnchor).isActive = true

        

    }
}

extension VDDetailContainerBlocV3 {
    enum Constant {
        static let extraHeight: CGFloat = 58.0
        static let containerCornerRadius: CGFloat = 12.0
        static let ceilingHeight: CGFloat = 64.0
        static let horizonHeight: CGFloat = SCREEN_WIDTH / (16.0 / 9.0)
        static let maxRatio: CGFloat = 16.0 / 9.0
        // https://www.tapd.cn/43363994/prong/stories/view/1143363994004352889
        // 播放器最大高度 = 屏高 - bottomMinMargin - safeAreaTop - blackBarHeight
        static let bottomMinMargin: CGFloat = 244.0
        static var safeAreaTop: CGFloat {
            guard let window = UIApplication.shared.keyWindow else { return 0.0 }
            let safeAreaTop = window.safeAreaInsets.bottom > 0 ? window.safeAreaInsets.top : 0.0
            return safeAreaTop
        }
        static var SCREEN_WIDTH: CGFloat {
            min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        }
        static var SCREEN_HEIGHT: CGFloat {
            max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        }
    }
}
