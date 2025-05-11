//
//  CollectionViewDiffable.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/3/28.
//

import UIKit

class CustomCollectionViewCell: UICollectionViewCell {
    static let reuseIdentifier = "CustomCollectionViewCell"

    let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}

class CollectionViewDiffableVC: UIViewController {

    enum Section {
        case header
        case item
        case footer
    }

    class Item: Hashable {
        static func == (lhs: CollectionViewDiffableVC.Item, rhs: CollectionViewDiffableVC.Item) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            return hasher.combine(id.hashValue)
        }
        
        var id: Int
        var title: String = ""
        init(id: Int, title: String) {
            self.id = id
            self.title = title
        }
    }

    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
    var updateButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureDataSource()
        applyInitialSnapshots()
        configureUpdateButton()
    }

    private func configureCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.bounds.width, height: 50)
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.register(CustomCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Item>(collectionView: collectionView) { (collectionView, indexPath, item) -> UICollectionViewCell? in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
            if let cell = cell as? CustomCollectionViewCell {
                cell.contentView.backgroundColor = .systemBlue
                cell.configure(with: item.title)
            }
            return cell
        }
    }
    
    private var items: [Item]?

    private func applyInitialSnapshots() {
//        let items = (1...20).map {
//            Item(id: $0, title: "Item \($0)")
//        }
//        self.items = items
//        updateData(newItems: items, animation: false)
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.header, .item, .footer])
        snapshot.appendItems([Item(id: 1, title: "Item \(1)"),
                              Item(id: 2, title: "Item \(2)")], toSection: .header)
//        snapshot.appendSections([.item])
        snapshot.appendItems([Item(id: 3, title: "Item \(3)"),
                              Item(id: 4, title: "Item \(4)")], toSection: .item)
//        snapshot.appendSections([.header])
        snapshot.appendItems([Item(id: 5, title: "Item \(5)"),
                              Item(id: 6, title: "Item \(6)")], toSection: .header)
//        snapshot.appendSections([.footer])
        snapshot.appendItems([Item(id: 7, title: "Item \(7)"),
                              Item(id: 8, title: "Item \(8)")], toSection: .footer)
        dataSource.apply(snapshot, animatingDifferences: true)
    }

    private func configureUpdateButton() {
        updateButton = UIButton(type: .system)
        updateButton.backgroundColor = .systemGreen
        updateButton.setTitle("Update Data", for: .normal)
        updateButton.addTarget(self, action: #selector(updateButtonTapped), for: .touchUpInside)
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(updateButton)
        
        NSLayoutConstraint.activate([
            updateButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            updateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func updateButtonTapped() {
        guard var items = items else { return }
//        items.first?.id = 100
//        items.first?.title = "Updated Item"
        items.insert(Item(id: 100, title: "Item 100"), at: 2)
        items.removeAll { item in
            item.id == 4
        }
        updateData(newItems: items, animation: true)
    }

    func updateData(newItems: [Item], animation: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.header])
        snapshot.appendItems(newItems)
        dataSource.apply(snapshot, animatingDifferences: animation)
    }
}
