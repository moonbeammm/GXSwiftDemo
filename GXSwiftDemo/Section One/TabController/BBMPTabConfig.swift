//
//  BBMPTabConfig.swift
//  BFCTabContainer
//
//  Created by 香辣虾 on 2020/4/17.
//  Copyright © 2020 bilibili. All rights reserved.
//

import Foundation
import UIKit

enum BBMPTabItemAlignment: UInt {
    case left
    case center
    case right
}

class BBMPExtraTabConfig: NSObject {
    var topMargin: CGFloat = 0
    var height: CGFloat = 0
    var animation: Bool = false
    var delay: CGFloat = 0
    var animationDuration: CGFloat = 0

    // ✅ ExtraTab动画生命周期回调
    /// 即将开始收起动画
    /// - Parameter duration: 动画时长
    var onWillCollapse: ((TimeInterval) -> Void)?

    /// 收起动画完成
    /// - Parameter finished: 动画是否正常完成（false表示被中断）
    var onDidCollapse: ((Bool) -> Void)?

    /// 即将开始展开动画
    /// - Parameter duration: 动画时长
    var onWillExpand: ((TimeInterval) -> Void)?

    /// 展开动画完成
    /// - Parameter finished: 动画是否正常完成
    var onDidExpand: ((Bool) -> Void)?

    /// 动画进度回调（可选，用于更精细的控制）
    /// - Parameters:
    ///   - progress: 动画进度 0.0 ~ 1.0
    ///   - isCollapsing: true表示收起动画，false表示展开动画
    var onAnimationProgress: ((CGFloat, Bool) -> Void)?
}

class BBMPBottomTabConfig: NSObject {
    var height: CGFloat = 0
    var animation: Bool = false
    var delay: CGFloat = 0
    var animationDuration: CGFloat = 0
}

class BBMPTabItemConfig: NSObject {
    /// 每个item的宽度，优先使用BBMPTabItem的itemWidth。
    var itemWidth: CGFloat = 0
    /// 每个item扩大的宽度，为了增大热区
    var itemExpandWidth: CGFloat = 0
    /// 每个item的间距
    var horizonMargin: CGFloat = 0
    var topMargin: CGFloat = 0
    var bottomMargin: CGFloat = 0

    static func defaultConfig() -> BBMPTabItemConfig {
        return BBMPTabItemConfig()
    }
}

class BBMPTabIndicatorConfig: NSObject {
    var width: CGFloat = 0
    var height: CGFloat = 2
    var cornerRadius: CGFloat = 1
    var bottomMargin: CGFloat = 0
    var horizonMargin: CGFloat = 0

    static func defaultConfig() -> BBMPTabIndicatorConfig {
        let config = BBMPTabIndicatorConfig()
        config.width = 0
        config.height = 2
        config.cornerRadius = 1
        config.bottomMargin = 0
        config.horizonMargin = 0
        return config
    }
}

class BBMPTabConfig: NSObject {
    var adjustInset: Bool = false
    /// 整个tab的左右间距
    var contentInset: UIEdgeInsets = .zero
    var alignment: BBMPTabItemAlignment = .left
    var itemConfig: BBMPTabItemConfig = BBMPTabItemConfig.defaultConfig()
    var indicatorConfig: BBMPTabIndicatorConfig = BBMPTabIndicatorConfig.defaultConfig()

    static func defaultConfig() -> BBMPTabConfig {
        let config = BBMPTabConfig()
        config.contentInset = .zero
        config.alignment = .left
        config.itemConfig = BBMPTabItemConfig.defaultConfig()
        config.indicatorConfig = BBMPTabIndicatorConfig.defaultConfig()
        return config
    }
}

class BBMPSkinTabConfig: NSObject {
    var hasSkin: Bool = false
    var height: CGFloat = 0
    var width: CGFloat = 0
}
