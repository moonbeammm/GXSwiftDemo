//
//  PopupViewController.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/8/11.
//

import UIKit

class PopupViewController: UIViewController {
    struct PopupItem {
        let title: String
        let subtitle: String
    }
    
    private var items: [PopupItem] = []
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "弹窗列表"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("关闭", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PopupTableViewCell.self, forCellReuseIdentifier: "PopupCell")
        tableView.separatorStyle = .singleLine
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadMockData()
        setupGestures()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(headerView)
        view.addSubview(tableView)
        
        headerView.addSubview(titleLabel)
        headerView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),
            
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 50),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }
    
    private func loadMockData() {
        items = [
            PopupItem(title: "选项 1", subtitle: "这是选项 1 的描述"),
            PopupItem(title: "选项 2", subtitle: "这是选项 2 的描述"),
            PopupItem(title: "选项 3", subtitle: "这是选项 3 的描述"),
            PopupItem(title: "选项 4", subtitle: "这是选项 4 的描述"),
            PopupItem(title: "选项 5", subtitle: "这是选项 5 的描述"),
            PopupItem(title: "选项 6", subtitle: "这是选项 6 的描述"),
            PopupItem(title: "选项 7", subtitle: "这是选项 7 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
            PopupItem(title: "选项 8", subtitle: "这是选项 8 的描述"),
        ]
        tableView.reloadData()
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            // 检查是否应该处理这个手势
            let touchPoint = gesture.location(in: view)
            
            // 如果触摸点在 tableView 区域内，并且 tableView 没有滚动到顶部，则不处理
            if tableView.frame.contains(touchPoint) {
                let tableViewContentOffsetY = tableView.contentOffset.y + tableView.contentInset.top
                if tableViewContentOffsetY > 0 {
                    gesture.isEnabled = false
                    gesture.isEnabled = true
                    return
                }
            }
            
        case .changed:
            // 只允许向下拖拽，并且只有在合适的条件下才响应
            if translation.y > 0 {
                let touchPoint = gesture.location(in: view)
                
                // 如果触摸在 tableView 区域内，检查 tableView 是否已滚动到顶部
                if tableView.frame.contains(touchPoint) {
                    let tableViewContentOffsetY = tableView.contentOffset.y + tableView.contentInset.top
                    if tableViewContentOffsetY <= 0 {
                        // TableView 已经在顶部，可以开始拖拽弹窗
                        view.transform = CGAffineTransform(translationX: 0, y: translation.y)
                    }
                } else {
                    // 触摸在 header 区域，直接响应
                    view.transform = CGAffineTransform(translationX: 0, y: translation.y)
                }
            }
            
        case .ended, .cancelled:
            let dismissThreshold: CGFloat = 100 // 拖拽超过100pt或速度足够大时关闭
            let shouldDismiss = translation.y > dismissThreshold || velocity.y > 500
            
            if shouldDismiss {
                dismissPopup()
            } else {
                // 回弹到原位置
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseOut) {
                    self.view.transform = CGAffineTransform.identity
                }
            }
        default:
            break
        }
    }
    
    @objc private func closeButtonTapped() {
        dismissPopup()
    }
    
    private func dismissPopup() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        }) { _ in
            self.removeFromParent()
            self.view.removeFromSuperview()
        }
    }
    
    func showPopup(in parentViewController: UIViewController) {
        parentViewController.addChild(self)
        parentViewController.view.addSubview(self.view)
        self.didMove(toParent: parentViewController)
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: parentViewController.view.topAnchor),
            self.view.leadingAnchor.constraint(equalTo: parentViewController.view.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: parentViewController.view.trailingAnchor),
            self.view.bottomAnchor.constraint(equalTo: parentViewController.view.bottomAnchor)
        ])
        
        // 从底部滑入的动画
        self.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
        
        UIView.animate(withDuration: 0.3) {
            self.view.transform = CGAffineTransform.identity
        }
    }
}
//extension PopupViewController: UIGestureRecognizerDelegate {
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
//        // 如果触摸点在 tableView 区域内，并且 tableView 没有滚动到顶部，则不接收手势
//        let touchPoint = touch.location(in: view)
//        if tableView.frame.contains(touchPoint) {
//            let tableViewContentOffsetY = tableView.contentOffset.y + tableView.contentInset.top
//            if tableViewContentOffsetY > 0 {
//                return false
//            }
//        }
//        return true
//    }
//    
//    // 控制多个手势识别器是否能够 同时识别（即是否允许它们同时触发并处理手势事件）
//    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        // 允许与底层的 VDDetailScrollManager 的手势同时识别
//        if let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer {
//            // 如果是来自 VDDetailScrollManager 的手势，允许同时识别
//            if otherGestureRecognizer.view != self.view {
//                return true
//            }
//        }
//        
//        // 对于 ScrollView 相关的手势
//        if let scrollView = otherGestureRecognizer.view as? UIScrollView {
//            // 如果是 TableView 的滚动手势，允许同时识别
//            if scrollView == tableView {
//                return true
//            }
//            
//            // 其他 ScrollView 的处理逻辑
//            if scrollView.superview?.isKind(of: UITableView.self) == true ||
//               scrollView.superview?.isKind(of: UICollectionView.self) == true {
//                return true
//            }
//            
//            if let t = NSClassFromString("UITableViewCellContentView"),
//               otherGestureRecognizer.view?.superview?.isKind(of: t) == true {
//                return true
//            }
//        }
//        
//        return false
//    }
//    
//}

extension PopupViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.view == self {
            return false
        }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        let velocity = pan.velocity(in: self.view)
        if abs(velocity.x) > abs(velocity.y) {
            return false
        }
        guard let scrollView = otherGestureRecognizer.view as? UIScrollView else {
                    if let otherPan = otherGestureRecognizer as? UIPanGestureRecognizer {
                        // 如果是来自 VDDetailScrollManager 的手势，允许同时识别
                        if otherGestureRecognizer.view != self.view {
                            return true
                        }
                    }
            return false
        }
        if scrollView.superview?.isKind(of: UITableView.self) == true {
            return false
        }
        if let t = NSClassFromString("UITableViewCellContentView"), otherGestureRecognizer.view?.superview?.isKind(of: t) == true {
            return false
        }
        
        
        return true
    }
    
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension PopupViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PopupCell", for: indexPath) as? PopupTableViewCell else {
            return UITableViewCell()
        }
        
        let item = items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        print("选择了: \(item.title)")
        
        // 可以在这里处理选择事件
        dismissPopup()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - PopupTableViewCell
class PopupTableViewCell: UITableViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with item: PopupViewController.PopupItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}
