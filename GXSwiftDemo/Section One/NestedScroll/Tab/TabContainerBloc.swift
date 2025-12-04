//
//  TabContainerViewController.swift
//  GXSwiftDemo
//
//  Created by sgx on 2025/11/17.
//

import UIKit

// MARK: - CustomExtraTabView

/// 自定义ExtraTab视图，支持动态切换上下/左右布局
class CustomExtraTabView: UIView {

    // MARK: - UI Components

    private let topLabel: UILabel = {
        let label = UILabel()
        label.text = "广告标题"
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let bottomLabel: UILabel = {
        let label = UILabel()
        label.text = "广告内容详情"
        label.textColor = .white.withAlphaComponent(0.8)
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Layout State

    enum LayoutMode {
        case vertical    // 上下排列
        case horizontal  // 左右排列
    }

    private var currentMode: LayoutMode = .vertical
    private var verticalConstraints: [NSLayoutConstraint] = []
    private var horizontalConstraints: [NSLayoutConstraint] = []

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        activateVerticalLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupConstraints()
        activateVerticalLayout()
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .systemPurple.withAlphaComponent(0.8)

        addSubview(topLabel)
        addSubview(bottomLabel)
    }

    private func setupConstraints() {
        // 上下排列约束
        verticalConstraints = [
            topLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            topLabel.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -4),
            topLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            topLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            bottomLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 4),
            bottomLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            bottomLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ]

        // 左右排列约束
        horizontalConstraints = [
            topLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 20),
            topLabel.trailingAnchor.constraint(equalTo: centerXAnchor, constant: -8),
            topLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),

            bottomLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 20),
            bottomLabel.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 8),
            bottomLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ]
    }

    // MARK: - Public Methods

    /// 切换为收起状态（左右排列）
    func collapse(animated: Bool = true) {
        guard currentMode != .horizontal else { return }
        currentMode = .horizontal

        NSLayoutConstraint.deactivate(verticalConstraints)
        NSLayoutConstraint.activate(horizontalConstraints)

//        if animated {
//            UIView.animate(withDuration: 0.25) {
//                self.layoutIfNeeded()
//            }
//        } else {
//            layoutIfNeeded()
//        }
    }

    /// 切换为展开状态（上下排列）
    func expand(animated: Bool = true) {
        guard currentMode != .vertical else { return }
        currentMode = .vertical

        NSLayoutConstraint.deactivate(horizontalConstraints)
        NSLayoutConstraint.activate(verticalConstraints)

//        if animated {
//            UIView.animate(withDuration: 0.25) {
//                self.layoutIfNeeded()
//            }
//        } else {
//            layoutIfNeeded()
//        }
    }

    // MARK: - Private Methods

    private func activateVerticalLayout() {
        NSLayoutConstraint.activate(verticalConstraints)
    }
}

// MARK: - TabContainerBloc

class TabContainerBloc: NSObject {
    var extraBarTopMargin: CGFloat = 0
    
    var firstItemView: TabContainerItemView = {
       let t = TabContainerItemView("简介")
        return t
    }()
    var firstTabVC: UIViewController = {
        let t = ListViewController()
        t.view.backgroundColor = .blue
        return t
    }()
    var secondItemView: TabContainerItemView = {
       let t = TabContainerItemView("评论")
        return t
    }()
    var secondTabVC: UIViewController = {
        let t = ListViewController()
        t.view.backgroundColor = .gray
        return t
    }()
    
    var extraTabView: CustomExtraTabView?

    func createExtraTabView() -> CustomExtraTabView {
        let view = CustomExtraTabView()
        return view
    }
    lazy var tabContainerVC: BBMPTabController = {
        let t = BBMPTabController()
        t.view.backgroundColor = .blue
        t.bfc_tabView.backgroundColor = .white
        t.bfc_tabItemView.indicator.backgroundColor = .systemPink
        t.delegate = self
        t.dataSource = self

        t.bfc_tabView.addSubview(tabGradientLayer)
        tabGradientLayer.translatesAutoresizingMaskIntoConstraints = false
        tabGradientLayer.topAnchor.constraint(equalTo: t.bfc_tabView.topAnchor).isActive = true
        tabGradientLayer.leftAnchor.constraint(equalTo: t.bfc_tabView.leftAnchor).isActive = true
        tabGradientLayer.rightAnchor.constraint(equalTo: t.bfc_tabView.rightAnchor).isActive = true
        tabGradientLayer.heightAnchor.constraint(equalToConstant: 20).isActive = true

        return t
    }()

    // tab bar渐变遮罩
    private lazy var tabGradientLayer: VKGradientView = {
        // 颜色 #AF193C
        let color = UIColor(red: 0xAF/255.0, green: 0x19/255.0, blue: 0x3C/255.0, alpha: 1.0)
        // 从95%透明度到0%透明度
        let colors = [
            color.withAlphaComponent(0.95).cgColor,  // 顶部 95%
            color.withAlphaComponent(0.0).cgColor,    // 中间 0%
        ]
        // 渐变位置：从最上方(0.0)到中间(0.5)
        let locations = [0.0, 1.0]
        
        // 垂直渐变：从上到下
        let startPoint = CGPoint(x: 0, y: 0.0)  // 顶部中心
        let endPoint = CGPoint(x: 0, y: 1.0)    // 中间位置
        let gradient = VKGradientView(colors: colors, start: startPoint, end: endPoint, locations: locations)




        return gradient
    }()
}

extension TabContainerBloc: BBMPTabControllerDelegate, BBMPTabControllerDataSource {
    func bfc_numbersOfViewController(in tabController: BBMPTabController) -> Int {
        2
    }

    
    func bfc_viewController(at index: Int, in tabController: BBMPTabController) -> UIViewController? {
        if index == 0 {
            return firstTabVC
        } else {
            return secondTabVC
        }
    }
    
    func bfc_tabItem(at index: Int, in tabController: BBMPTabController) -> BBMPTabItem {
        if index == 0 {
            return firstItemView
        } else {
            return secondItemView
        }
    }
    
    func bfc_tabRightView(in tabController: BBMPTabController) -> UIView? {
        return nil
    }
    
    func bfc_extraTabView(in tabController: BBMPTabController) -> UIView? {
        extraTabView = createExtraTabView()
        return extraTabView
    }
    
    func bfc_extraTabViewConfig(in tabController: BBMPTabController) -> BBMPExtraTabConfig? {
        let t = BBMPExtraTabConfig()
        t.topMargin = extraBarTopMargin
        t.height = 80
        t.animation = true

        // ✅ 设置动画回调
        t.onWillCollapse = { [weak self] duration in
            print("📤 ExtraTab 即将收起，动画时长: \(duration)s")
            // 触发CustomExtraTabView的布局切换（左右排列）
            self?.extraTabView?.collapse(animated: true)
        }

        t.onDidCollapse = { finished in
            print("✅ ExtraTab 收起完成，finished: \(finished)")
        }

        t.onWillExpand = { [weak self] duration in
            print("📥 ExtraTab 即将展开，动画时长: \(duration)s")
            // 触发CustomExtraTabView的布局切换（上下排列）
            self?.extraTabView?.expand(animated: true)
        }

        t.onDidExpand = { finished in
            print("✅ ExtraTab 展开完成，finished: \(finished)")
        }

        // ✅ 可选：监听动画进度
        t.onAnimationProgress = { progress, isCollapsing in
            let action = isCollapsing ? "收起" : "展开"
            print("📊 ExtraTab \(action)进度: \(Int(progress * 100))%")
            // 业务逻辑：比如根据进度调整透明度
            // self.extraTabView?.alpha = isCollapsing ? (1.0 - progress) : progress
        }

        return t
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
    
    /// 在reload的时候会默认定位到指定下标
    func bfc_defaultSelectIndex(in tabController: BBMPTabController) -> Int {
        return 0
    }
    
    func bfc_tabConfig(in tabController: BBMPTabController) -> BBMPTabConfig? {
        let t = BBMPTabConfig.defaultConfig()
        t.indicatorConfig.width = 18.0
        t.indicatorConfig.height = 4.0
        t.indicatorConfig.cornerRadius = 2.0
        t.indicatorConfig.bottomMargin = 4.5
        return t
    }
}
