//
//  TabContainerViewController.swift
//  GXSwiftDemo
//
//  Created by sgx on 2025/11/17.
//

import UIKit

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
    
    var extraTabView: UIView = {
        let t = UIView()
        t.backgroundColor = .yellow.withAlphaComponent(0.5)
        
        let label = UILabel()
        label.text = "广告"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        t.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: t.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: t.centerYAnchor)
        ])
        
        return t
    }()
    lazy var tabContainerVC: BBMPTabController = {
        let t = BBMPTabController()
        t.view.backgroundColor = .blue
        t.bfc_tabView.backgroundColor = .white
        t.bfc_tabItemView.indicator.backgroundColor = .systemPink
        t.delegate = self
        t.dataSource = self
        return t
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
        return extraTabView
    }
    
    func bfc_extraTabViewConfig(in tabController: BBMPTabController) -> BBMPExtraTabConfig? {
        let t = BBMPExtraTabConfig()
        t.topMargin = extraBarTopMargin
        t.height = 80
        t.animation = true
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
