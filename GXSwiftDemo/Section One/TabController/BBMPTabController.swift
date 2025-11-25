//
//  BBMPTabController.swift
//  BFCTabContainer
//
//  Created by 香辣虾 on 2020/3/21.
//  Copyright © 2020 bilibili. All rights reserved.
//

import UIKit

let BBMPTabControllerUnselect: Int = -1
let BBMPTabControllerTabHeight: CGFloat = 40

enum BBMPVCStatus: UInt {
    case viewUnknown = 0
    case viewWillAppear
    case viewDidAppear
    case viewWillDisappear
    case viewDidDisappear
}

//protocol BBMPTabControllerScrollView: AnyObject {
//    func bfc_child_scrollView() -> UIScrollView?
//}

protocol BBMPTabControllerDataSource: AnyObject {
    /// 子视图总数
    func bfc_numbersOfViewController(in tabController: BBMPTabController) -> Int
    /// 对应下标的子视图
    func bfc_viewController(at index: Int, in tabController: BBMPTabController) -> UIViewController?

    /// 对应下标的tabItem
    func bfc_tabItem(at index: Int, in tabController: BBMPTabController) -> BBMPTabItem
    /// 自定义tab右侧视图
    func bfc_tabRightView(in tabController: BBMPTabController) -> UIView?
    /// 自定义tab上额外tab
    func bfc_extraTabView(in tabController: BBMPTabController) -> UIView?
    /// 自定义tab上额外tab的配置
    func bfc_extraTabViewConfig(in tabController: BBMPTabController) -> BBMPExtraTabConfig?
    /// 自定义tab下bottom
    func bfc_bottomTabView(in tabController: BBMPTabController) -> UIView?
    /// 自定义tab下bottom配置
    func bfc_bottomTabViewConfig(in tabController: BBMPTabController) -> BBMPBottomTabConfig?
    /// 自定义tab皮肤背景
    func bfc_skinTabViewConfig(in tabController: BBMPTabController) -> BBMPSkinTabConfig?
}

// 为 DataSource 提供默认实现
extension BBMPTabControllerDataSource {
    func bfc_tabItem(at index: Int, in tabController: BBMPTabController) -> BBMPTabItem {
        return BBMPTabItem()
    }

    func bfc_tabRightView(in tabController: BBMPTabController) -> UIView? {
        return nil
    }

    func bfc_extraTabView(in tabController: BBMPTabController) -> UIView? {
        return nil
    }

    func bfc_extraTabViewConfig(in tabController: BBMPTabController) -> BBMPExtraTabConfig? {
        return nil
    }

    func bfc_bottomTabView(in tabController: BBMPTabController) -> UIView? {
        return nil
    }

    func bfc_bottomTabViewConfig(in tabController: BBMPTabController) -> BBMPBottomTabConfig? {
        return nil
    }

    func bfc_skinTabViewConfig(in tabController: BBMPTabController) -> BBMPSkinTabConfig? {
        return nil
    }
}

@objc protocol BBMPTabControllerDelegate: AnyObject {
    /// tab统一配置 （当bfc_tabView存在的时候）
    func bfc_tabConfig(in tabController: BBMPTabController) -> BBMPTabConfig?
    /// 在reload的时候会默认定位到指定下标
    @objc optional func bfc_defaultSelectIndex(in tabController: BBMPTabController) -> Int
    /// 在reload的时候是否预加载对应下标vc（除非必要，不建议）
    @objc optional func bfc_needPreloadViewController(at index: Int, in tabController: BBMPTabController) -> Bool

    /// 点击tab对应下标回调（当bfc_tabView存在的时候）
    @objc optional func bfc_tapTabItem(at index: Int, in tabController: BBMPTabController)
    /// 滚动至tab对应下标回调（当bfc_tabView存在的时候）
    @objc optional func bfc_scrollTabItem(at index: Int, in tabController: BBMPTabController)
    /// 选中对应下标回调
    @objc optional func bfc_selectTabItem(at index: Int, in tabController: BBMPTabController)
    /// 再次选中对应下标回调
    @objc optional func bfc_selectTabItemAgain(at index: Int, in tabController: BBMPTabController)

    /// 刷新动作完成回调
    @objc optional func bfc_reloadFinish(in tabController: BBMPTabController)

    /// 滚动过程中，尝试预加载目标页面
    @objc optional func bfc_scrollToPreloadViewController(at index: Int, isFirstLoad: Bool, in tabController: BBMPTabController)

    @objc optional func bfc_beginScrollPageView(in tabController: BBMPTabController)
    @objc optional func bfc_finishScrollPageView(in tabController: BBMPTabController)
}

class BBMPTabController: UIViewController {

    weak var dataSource: BBMPTabControllerDataSource?
    weak var delegate: BBMPTabControllerDelegate?

    /// 当前vc状态
    var bfc_vcStatus: BBMPVCStatus = .viewUnknown

    /// 当前选中下标
    var selectIndex: Int = BBMPTabControllerUnselect
    /// 当前选中视图
    weak var selectViewController: UIViewController?

    /// tab点击,切换vc是否动画 默认NO 无动画
    var tabAnimated: Bool = false
    /// tab是否自适应layout
    var autoLayoutFit: Bool = false

    /// 子VC当前偏移顶部距离
    var subVCOriginY: CGFloat = 0

    var numbersOfViewController: Int = 0
    var loadedViewControllers: [String: UIViewController] = [:]
    weak var rightView: UIView?
    weak var extraTabView: UIView?
    weak var bottomTabView: UIView?
    var expectIndex: Int = BBMPTabControllerUnselect
    var transition: Bool = false

    let placeHolderKey = "_place_holder_"
    
    var skinBgViewLeadingConstraint: NSLayoutConstraint?
    var tabItemViewConstraints: [NSLayoutConstraint] = []
    var containerConstraints: [NSLayoutConstraint] = []

    // MARK: - Lifecycle

    override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        return false
    }

    override func loadView() {
        super.loadView()
        view = bfc_scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        configSubviews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if autoLayoutFit {
            bfc_pageView.setContentOffset(CGPoint(x: CGFloat(selectIndex) * bfc_pageView.frame.width, y: 0), animated: false)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        bfc_vcStatus = .viewWillAppear
        updateStatus(.viewWillAppear, vc: selectViewController, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bfc_vcStatus = .viewDidAppear
        updateStatus(.viewDidAppear, vc: selectViewController, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        bfc_vcStatus = .viewWillDisappear
        updateStatus(.viewWillDisappear, vc: selectViewController, animated: animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        bfc_vcStatus = .viewDidDisappear
        updateStatus(.viewDidDisappear, vc: selectViewController, animated: animated)
    }

    deinit {
        bfc_scrollView.removeAllObserves()
    }
    
    @discardableResult
    func loadVCAtIndex(_ index: Int) -> UIViewController? {
        var vc = loadedViewControllers["\(index)"]
        if vc == nil || vc?.title == placeHolderKey {
            vc = insertVC(dataSource?.bfc_viewController(at: index, in: self), toIndex: index)
        }
        return vc
    }

    @discardableResult
    func insertVC(_ vc: UIViewController?, toIndex index: Int) -> UIViewController? {
        guard let vc = vc, index >= 0, index < numbersOfViewController else { return nil }

        let cur = loadedViewControllers["\(index)"]
        if cur?.title == placeHolderKey {
            cur?.removeFromParent()
            cur?.view.removeFromSuperview()
        }

        loadedViewControllers["\(index)"] = vc
        addChild(vc)

        let y = subVCOriginY > 0 ? subVCOriginY : 0

        if index >= bfc_pageView.container.arrangedSubviews.count {
            bfc_pageView.container.addArrangedSubview(vc.view)
        } else {
            bfc_pageView.container.insertArrangedSubview(vc.view, at: index)
        }

        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.widthAnchor.constraint(equalTo: bfc_pageView.widthAnchor),
            vc.view.heightAnchor.constraint(equalTo: bfc_pageView.heightAnchor, constant: -y)
        ])

        return vc
    }

    func updateStatus(_ status: BBMPVCStatus, vc: UIViewController?, animated: Bool) {
        guard let vc = vc else { return }

        // 使用关联对象来记录状态
        let statusKey = "bfc_vc_status"
        if let storedStatus = objc_getAssociatedObject(vc, statusKey) as? BBMPVCStatus,
           storedStatus == status {
            return
        }

        objc_setAssociatedObject(vc, statusKey, status, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        switch status {
        case .viewWillAppear:
            vc.beginAppearanceTransition(true, animated: animated)
        case .viewWillDisappear:
            vc.beginAppearanceTransition(false, animated: animated)
        case .viewDidAppear, .viewDidDisappear:
            vc.endAppearanceTransition()
        default:
            break
        }
    }
    
    func _selectToIndex(_ index: Int, animated: Bool, forceLifecycle: Bool) {
        guard index >= 0 && index < numbersOfViewController else { return }

        // 渲染视图更新选中vc
        let selectVC = loadVCAtIndex(index)
        let lastSelectVC = selectViewController
        selectViewController = selectVC

        // 更新选中下标
        setSelectIndex(index)

        let ignore = lastSelectVC === selectVC && !forceLifecycle

        // 生命周期管理
        if !ignore && bfc_vcStatus.rawValue < BBMPVCStatus.viewWillDisappear.rawValue {
            updateStatus(.viewWillDisappear, vc: lastSelectVC, animated: false)
            if bfc_vcStatus.rawValue >= BBMPVCStatus.viewWillAppear.rawValue {
                updateStatus(.viewWillAppear, vc: selectVC, animated: false)
            }
        }

        if transition {
            // 上一次转场未完成，取消避免重复
            transition = false
            bfc_pageView.layer.removeAllAnimations()
        }

        if animated {
            transition = true
            UIView.animate(withDuration: 0.25, animations: {
                self.bfc_pageView.setContentOffset(CGPoint(x: self.bfc_pageView.frame.width * CGFloat(index), y: 0), animated: false)
            }, completion: { finished in
                if finished {
                    self.transition = false
                    // 生命周期管理
                    if !ignore && self.bfc_vcStatus.rawValue < BBMPVCStatus.viewDidDisappear.rawValue {
                        self.updateStatus(.viewDidDisappear, vc: lastSelectVC, animated: false)
                        if self.bfc_vcStatus.rawValue >= BBMPVCStatus.viewDidAppear.rawValue {
                            self.updateStatus(.viewDidAppear, vc: selectVC, animated: false)
                        }
                    }
                }
            })
        } else {
            transition = false
            bfc_pageView.setContentOffset(CGPoint(x: bfc_pageView.frame.width * CGFloat(index), y: 0), animated: false)
            // 生命周期管理
            if !ignore && bfc_vcStatus.rawValue < BBMPVCStatus.viewDidDisappear.rawValue {
                updateStatus(.viewDidDisappear, vc: lastSelectVC, animated: false)
                if bfc_vcStatus.rawValue >= BBMPVCStatus.viewDidAppear.rawValue {
                    updateStatus(.viewDidAppear, vc: selectVC, animated: false)
                }
            }
        }
    }
    
    private func setSelectIndex(_ index: Int) {
        let lastSelectIndex = selectIndex
        selectIndex = index
        bfc_tabItemView.selectToIndex(index, animated: tabAnimated)

        if lastSelectIndex == index {
            if index != BBMPTabControllerUnselect {
                delegate?.bfc_selectTabItemAgain?(at: index, in: self)
            }
        } else {
            if index != BBMPTabControllerUnselect {
                delegate?.bfc_selectTabItem?(at: index, in: self)
            }
        }
    }

    // MARK: - Lazy Load

    lazy var contentView: UIView = {
        return UIView()
    }()

    lazy var container: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    lazy var bfc_tabContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        return stack
    }()

    lazy var bfc_tabView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    lazy var bfc_skinBgView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 0
        return imageView
    }()

    lazy var bfc_tabItemView: BBMPTabScrollView = {
        let tabScrollView = BBMPTabScrollView()
        tabScrollView.backgroundColor = .clear
        tabScrollView.bounces = false
        tabScrollView.scrollDelegate = self
        tabScrollView.dataSource = self
        tabScrollView.scrollsToTop = false
        tabScrollView.isDirectionalLockEnabled = true
        tabScrollView.showsVerticalScrollIndicator = false
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.contentInsetAdjustmentBehavior = .never
        tabScrollView.heightAnchor.constraint(equalToConstant: BBMPTabControllerTabHeight).isActive = true
        return tabScrollView
    }()

    lazy var bfc_pageView: BBMPPageScrollView = {
        let pageScrollView = BBMPPageScrollView()
        pageScrollView.backgroundColor = .clear
        pageScrollView.bounces = false
        pageScrollView.delegate = self
        pageScrollView.scrollsToTop = false
        pageScrollView.isPagingEnabled = true
        pageScrollView.isDirectionalLockEnabled = true
        pageScrollView.showsVerticalScrollIndicator = false
        pageScrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            pageScrollView.contentInsetAdjustmentBehavior = .never
        }
        return pageScrollView
    }()

    lazy var bfc_scrollView: BBMPScrollView = {
        let scrollView = BBMPScrollView()
        scrollView.backgroundColor = .white
        scrollView.bounces = false
        scrollView.delegate = self
        scrollView.isDirectionalLockEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        return scrollView
    }()

    lazy var bottomLine: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
}

// MARK: - BBMPTabScrollViewDataSource
extension BBMPTabController: BBMPTabScrollViewDataSource {
    func bfc_numbersOfItem(in tabScrollView: BBMPTabScrollView) -> Int {
        return dataSource?.bfc_numbersOfViewController(in: self) ?? 0
    }

    func bfc_tabItem(at index: Int, in tabScrollView: BBMPTabScrollView) -> BBMPTabItem {
        return dataSource?.bfc_tabItem(at: index, in: self) ?? BBMPTabItem()
    }
}

// MARK: - BBMPTabScrollViewDelegate
extension BBMPTabController: BBMPTabScrollViewDelegate {
    func bfc_tabConfig(in tabScrollView: BBMPTabScrollView) -> BBMPTabConfig? {
        return delegate?.bfc_tabConfig(in: self) ?? BBMPTabConfig.defaultConfig()
    }

    func bfc_selectTabItem(at index: Int, in tabScrollView: BBMPTabScrollView) {
        delegate?.bfc_tapTabItem?(at: index, in: self)
        if let item = dataSource?.bfc_tabItem(at: index, in: self), !item.disable {
            bfc_selectToIndex(index, animated: tabAnimated)
        }
        tabAdaptSkin(progress: CGFloat(index))
    }
}

// MARK: - UIScrollViewDelegate
extension BBMPTabController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard numbersOfViewController > 0, scrollView == bfc_pageView else { return }

        let index = Int(floor(scrollView.contentOffset.x / scrollView.frame.width + 0.5))
        if index != selectIndex {
            bfc_selectToIndex(index, animated: false)
            delegate?.bfc_scrollTabItem?(at: index, in: self)
        }
        delegate?.bfc_finishScrollPageView?(in: self)
        expectIndex = BBMPTabControllerUnselect
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard numbersOfViewController > 0, scrollView == bfc_pageView else { return }

        let progress = scrollView.contentOffset.x / scrollView.frame.width
        bfc_tabItemView.scorllToProgress(progress)
        tabAdaptSkin(progress: progress)

        var expectIdx = -1
        if progress > CGFloat(selectIndex) {
            // 向右滑动
            expectIdx = Int(ceil(progress))
        } else if progress < CGFloat(selectIndex) {
            // 向左滑动
            expectIdx = Int(floor(progress))
        }

        if expectIdx >= 0 && expectIdx < numbersOfViewController && expectIdx != expectIndex {
            expectIndex = expectIdx
            let isFirstLoad = loadedViewControllers["\(expectIdx)"] == nil
            delegate?.bfc_scrollToPreloadViewController?(at: expectIdx, isFirstLoad: isFirstLoad, in: self)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.bfc_beginScrollPageView?(in: self)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {}

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {}
}

//// MARK: - UIViewController Extension
//extension UIViewController: BBMPTabControllerScrollView {
//    @objc func bfc_child_scrollView() -> UIScrollView? {
//        return nil
//    }
//}
