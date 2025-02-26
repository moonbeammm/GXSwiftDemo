//
//  SheetViewController+Config.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

protocol RenderViewProtocol {
    func render()
    func renderHeight() -> CGFloat
}

protocol SheetContentViewDelegate: AnyObject {
    func preferredHeightChanged(oldHeight: CGFloat, newSize: CGFloat)
}

public class SheetContentViewController: UIViewController {
    internal private(set) lazy var contentView = {
        let t = UIView()
        t.layer.masksToBounds = true
        t.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        t.layer.cornerRadius = 12
        return t
    }()
    
    internal private(set) lazy var childContainerView = {
        let t = UIView()
        return t
    }()
    
    // 业务方自定义视图
    internal private(set) var childViewController: UIViewController
    
    internal private(set) lazy var topBarView = {
        let t = UIView()
        t.isUserInteractionEnabled = true
        return t
    }()
    internal private(set) lazy var indicator = {
        let t = UIView()
        t.layer.cornerRadius = 6 / 2
        t.layer.masksToBounds = true
        return t
    }()
    
    internal private(set) var preferredHeight: CGFloat
    internal weak var delegate: SheetContentViewDelegate?
    
    private var options: SheetOptions
    private var contentTopConstraint: NSLayoutConstraint?
    private var contentBottomConstraint: NSLayoutConstraint?
    
    public init(childViewController: UIViewController, options: SheetOptions) {
        self.options = options
        self.childViewController = childViewController
        self.preferredHeight = 0
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupContentView()
        self.setupChildContainerView()
        self.setupTopBarView()
        self.setupChildViewController()
        self.updatePreferredHeight()

        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    @objc 
    func contentSizeDidChange() {
        self.updatePreferredHeight()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
//        self.updatePreferredHeight()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updatePreferredHeight()
    }

    private func setupContentView() {
        self.view.addSubview(self.contentView)

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.contentView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.contentView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.contentTopConstraint = self.contentView.topAnchor.constraint(equalTo: self.view.topAnchor)
        self.contentTopConstraint?.isActive = true
    }
    
    private func setupTopBarView() {
        guard self.options.pullBarViewHeight > 0 else { return }

        self.contentView.addSubview(self.topBarView)

        self.topBarView.translatesAutoresizingMaskIntoConstraints = false
        self.topBarView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        self.topBarView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.topBarView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true
        self.topBarView.heightAnchor.constraint(equalToConstant: self.options.pullBarViewHeight).isActive = true
        
        self.topBarView.addSubview(self.indicator)

        self.indicator.translatesAutoresizingMaskIntoConstraints = false
        self.indicator.centerXAnchor.constraint(equalTo: self.topBarView.centerXAnchor).isActive = true
        self.indicator.centerYAnchor.constraint(equalTo: self.topBarView.centerYAnchor).isActive = true
        self.indicator.widthAnchor.constraint(equalToConstant: 50).isActive = true
        self.indicator.heightAnchor.constraint(equalToConstant: 6).isActive = true
    }
    
    private func setupChildContainerView() {
        self.contentView.addSubview(self.childContainerView)
        
        self.childContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.childContainerView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        self.childContainerView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.childContainerView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor).isActive = true
        self.childContainerView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: self.options.pullBarViewHeight).isActive = true
    }
    
    private func setupChildViewController() {
        self.childViewController.willMove(toParent: self)
        
        self.addChild(self.childViewController)
        self.childContainerView.addSubview(self.childViewController.view)
        
        self.childViewController.view.translatesAutoresizingMaskIntoConstraints = false
        self.childViewController.view.leadingAnchor.constraint(equalTo: self.childContainerView.leadingAnchor).isActive = true
        self.childViewController.view.trailingAnchor.constraint(equalTo: self.childContainerView.trailingAnchor).isActive = true
        self.childViewController.view.topAnchor.constraint(equalTo: self.childContainerView.topAnchor).isActive = true
        self.contentBottomConstraint = self.childViewController.view.bottomAnchor.constraint(equalTo: self.childContainerView.bottomAnchor)
        self.contentBottomConstraint?.isActive = true
        
        self.childViewController.didMove(toParent: self)
    }
}

extension SheetContentViewController {
    func updatePreferredHeight() {
        
        let width = self.view.bounds.width > 0 ? self.view.bounds.width : UIScreen.main.bounds.width
        let oldPreferredHeight = self.preferredHeight
        
        if let preferHeight = options.preferredHeight?(options.extraHeight) {
            self.preferredHeight = preferHeight
        } else {
            var fittingSize = UIView.layoutFittingCompressedSize;
            fittingSize.width = width;
            
            self.contentTopConstraint?.isActive = false
            UIView.performWithoutAnimation {
                self.contentView.layoutSubviews()
            }
            
            self.preferredHeight = self.contentView.systemLayoutSizeFitting(fittingSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow).height
            self.contentTopConstraint?.isActive = true
            UIView.performWithoutAnimation {
                self.contentView.layoutSubviews()
            }
        }
        
        self.delegate?.preferredHeightChanged(oldHeight: oldPreferredHeight, newSize: self.preferredHeight)
    }
    
}
