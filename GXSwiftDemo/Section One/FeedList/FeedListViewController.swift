//
//  FeedListViewController.swift
//  GXSwiftDemo
//
//  Created by Claude on 2025/12/15.
//

import UIKit

// MARK: - 卡片数据模型
struct FeedCardModel {
    let imageColor: UIColor  // 模拟封面图
    let title: String
    let author: String
    let likes: String

    // 随机生成卡片高度（模拟瀑布流效果）
    var imageHeight: CGFloat {
        return CGFloat.random(in: 200...300)
    }
}

// MARK: - 列表页 ViewController
class FeedListViewController: UIViewController {

    // MARK: - Properties

    private var feedData: [FeedCardModel] = []

    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallFlowLayout()
        layout.delegate = self
        layout.columnCount = 2
        layout.columnSpacing = 8
        layout.rowSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.delegate = self
        cv.dataSource = self
        cv.register(FeedCardCell.self, forCellWithReuseIdentifier: FeedCardCell.identifier)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    // 用于转场动画的选中卡片信息
    var selectedCardFrame: CGRect = .zero
    weak var selectedCardView: UIView?

    // 自定义导航转场代理
    private let navigationTransitionDelegate = FeedNavigationTransitionDelegate()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMockData()

        // 设置导航控制器代理
        navigationController?.delegate = navigationTransitionDelegate
    }

    // MARK: - Setup

    private func setupUI() {
        title = "发现"
        view.backgroundColor = .systemBackground

        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadMockData() {
        let colors: [UIColor] = [
            .systemPink, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemTeal, .systemIndigo, .systemRed
        ]

        feedData = (0..<30).map { index in
            FeedCardModel(
                imageColor: colors[index % colors.count],
                title: "精选内容 \(index + 1)",
                author: "用户\(index + 1)",
                likes: "\(Int.random(in: 100...9999))"
            )
        }

        collectionView.reloadData()
    }

    // MARK: - Navigation

    private func navigateToDetail(from cell: FeedCardCell, at indexPath: IndexPath) {
        // 记录选中卡片的信息用于转场动画
        guard let window = view.window else { return }
        selectedCardFrame = cell.convert(cell.bounds, to: window)
        selectedCardView = cell

        // 将卡片信息传递给转场代理
        navigationTransitionDelegate.selectedCardFrame = selectedCardFrame
        navigationTransitionDelegate.selectedCardImageView = cell

        let detailVC = VDDetailContainerBlocV3()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension FeedListViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return feedData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedCardCell.identifier, for: indexPath) as! FeedCardCell
        cell.configure(with: feedData[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? FeedCardCell else { return }
        navigateToDetail(from: cell, at: indexPath)
    }
}

// MARK: - WaterfallFlowLayout Delegate
extension FeedListViewController: WaterfallFlowLayoutDelegate {
    func waterfallFlowLayout(_ layout: WaterfallFlowLayout, heightForItemAt indexPath: IndexPath, itemWidth: CGFloat) -> CGFloat {
        let model = feedData[indexPath.item]
        let imageHeight = model.imageHeight
        let textHeight: CGFloat = 60 // 标题 + 作者信息高度
        return imageHeight + textHeight
    }
}
