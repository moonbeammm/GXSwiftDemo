//
//  WaterfallFlowLayout.swift
//  GXSwiftDemo
//
//  Created by Claude on 2025/12/15.
//

import UIKit

protocol WaterfallFlowLayoutDelegate: AnyObject {
    func waterfallFlowLayout(_ layout: WaterfallFlowLayout, heightForItemAt indexPath: IndexPath, itemWidth: CGFloat) -> CGFloat
}

class WaterfallFlowLayout: UICollectionViewLayout {

    // MARK: - Properties

    weak var delegate: WaterfallFlowLayoutDelegate?

    var columnCount: Int = 2 {
        didSet { invalidateLayout() }
    }

    var columnSpacing: CGFloat = 8 {
        didSet { invalidateLayout() }
    }

    var rowSpacing: CGFloat = 8 {
        didSet { invalidateLayout() }
    }

    var sectionInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }

    // 缓存布局属性
    private var attributesCache: [UICollectionViewLayoutAttributes] = []
    private var contentHeight: CGFloat = 0
    private var columnHeights: [CGFloat] = []

    // MARK: - Layout Calculation

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        // 重置缓存
        attributesCache.removeAll()
        contentHeight = 0
        columnHeights = Array(repeating: sectionInset.top, count: columnCount)

        // 计算列宽
        let totalWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right
        let totalSpacing = CGFloat(columnCount - 1) * columnSpacing
        let itemWidth = (totalWidth - totalSpacing) / CGFloat(columnCount)

        // 计算每个 item 的布局属性
        let itemCount = collectionView.numberOfItems(inSection: 0)
        for item in 0..<itemCount {
            let indexPath = IndexPath(item: item, section: 0)

            // 找到最短的列
            let shortestColumnIndex = columnHeights.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
            let xOffset = sectionInset.left + (itemWidth + columnSpacing) * CGFloat(shortestColumnIndex)
            let yOffset = columnHeights[shortestColumnIndex]

            // 获取高度
            let itemHeight = delegate?.waterfallFlowLayout(self, heightForItemAt: indexPath, itemWidth: itemWidth) ?? 100

            // 创建布局属性
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            attributes.frame = CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight)
            attributesCache.append(attributes)

            // 更新列高度
            columnHeights[shortestColumnIndex] += itemHeight + rowSpacing
        }

        // 计算总高度
        contentHeight = (columnHeights.max() ?? 0) - rowSpacing + sectionInset.bottom
    }

    override var collectionViewContentSize: CGSize {
        guard let collectionView = collectionView else {
            return .zero
        }
        return CGSize(width: collectionView.bounds.width, height: contentHeight)
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return attributesCache.filter { $0.frame.intersects(rect) }
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return attributesCache[safe: indexPath.item]
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let collectionView = collectionView else { return false }
        return newBounds.width != collectionView.bounds.width
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
