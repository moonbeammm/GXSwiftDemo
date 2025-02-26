//
//  CellComponent.swift
//  SpaceX Launch
//
//  Created by Puer on 2023/11/3.
//

import Carbon
import Combine
import UIKit

// MARK: - CellComponent

struct CellComponent: IdentifiableComponent {
    let item: GXHeader

    var id: String { item.title }

    func renderContent() -> ContentView {
        ContentView()
    }

    func render(in content: ContentView) {
        content.item = item
    }

    func referenceSize(in bounds: CGRect) -> CGSize? {
        .init(width: bounds.width, height: 52)
    }
}

// MARK: Component.ContentView

extension CellComponent {
    final class ContentView: UIView {
        // MARK: Lifecycle

        override init(frame: CGRect) {
            super.init(frame: frame)

            backgroundColor = .white
            layer.cornerRadius = 12
            layer.shadowOffset = .init(width: 0, height: 1)
            layer.shadowRadius = 4
            layer.shadowOpacity = 0.3
            layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor

            addSubview(nameLabel)
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
                nameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
                nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
            ])
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: Internal

        var item: GXHeader? {
            didSet {
                nameLabel.text = "Mission \(item?.title ?? "--")"
            }
        }

        // MARK: Private

        private lazy var nameLabel: UILabel = {
            let label = UILabel()
            label.font = .preferredFont(forTextStyle: .subheadline)
            label.textColor = .darkText
            label.numberOfLines = 3

            return label
        }()
    }
}
