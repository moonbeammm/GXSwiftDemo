//
//  TabContainerVC.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/7/16.
//

import UIKit

class TabContainerVC: UIViewController {
    struct Item {
        let title: String
        let color: UIColor
    }
    
    private var items: [Item] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: view.frame.width, height: 150)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(NestedCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    public init() {
        super.init(nibName:nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadMockData()
    }
}

extension TabContainerVC {
    private func setupView() {
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadMockData() {
        // Create mock data
        let colors: [UIColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemYellow, .systemPink, .systemTeal
        ]
        
        items = (1...20).map { index in
            Item(
                title: "Item \(index)",
                color: colors.randomElement() ?? .systemGray
            )
        }
        
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension TabContainerVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "cell",
            for: indexPath
        ) as? NestedCell else {
            return UICollectionViewCell()
        }
        
        let item = items[indexPath.row]
        cell.configure(with: item.title, color: item.color)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        print("Selected: \(item.title)")
    }
}
extension TabContainerVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // print("\(PanConstant.tag) on pan gesture did scroll \(scrollView.contentOffset.y)")
    }
}
