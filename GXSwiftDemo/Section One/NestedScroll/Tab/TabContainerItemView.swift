//
//  TabContainerItemView.swift
//  GXSwiftDemo
//
//  Created by sgx on 2025/11/17.
//

import UIKit

class TabContainerItemView: BBMPTabItem {
    public lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 13)
        return label
    }()
    
    public init(_ title: String) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = .white
        // 配置子视图
        configSubviews()
        // 填充数据
        titleLabel.text = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public var itemWidth: CGFloat {
        set { }
        get {
            return 100
        }
    }

    override public var isSelected: Bool {
        didSet {
            if isSelected {
                titleLabel.textColor = .red
            } else {
                titleLabel.textColor = .black
            }
        }
    }
    
    func configSubviews() {
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        titleLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        titleLabel.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
}
