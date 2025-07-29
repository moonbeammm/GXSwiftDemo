//
//  FSCalendarCollectionView.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

class FSCalendarCollectionViewLayout: UICollectionViewLayout {
    weak var calendar: FSCalendar?
    
    private var widths: [CGFloat] = []
    private var heights: [CGFloat] = []
    private var lefts: [CGFloat] = []
    private var tops: [CGFloat] = []

    private var estimatedItemSize: CGSize = .zero
    private var contentSize: CGSize = .zero
    private var collectionViewSize: CGSize = .zero
    private var numberOfSections: Int = 0

    private var itemAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNotifications(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc private func didReceiveNotifications(_ notification: Notification) {
        if notification.name == UIApplication.didReceiveMemoryWarningNotification {
            itemAttributes.removeAll()
        }
    }

    override func prepare() {
        guard let collectionView = collectionView else { return }
        guard let calendar = calendar else { return }
        guard collectionViewSize != collectionView.frame.size ||
              numberOfSections != collectionView.numberOfSections else { return }

        collectionViewSize = collectionView.frame.size
        itemAttributes.removeAll()

        estimatedItemSize = {
            let columnCount = 7.0
            let contentInset = calendar.appearance.contentInsets.left - calendar.appearance.contentInsets.right
            let interitemSpacing = calendar.appearance.minimumInteritemSpacing * CGFloat(columnCount - 1)
            let width = (collectionView.bounds.width - contentInset - interitemSpacing) / columnCount
            
            let height: CGFloat = {
                switch calendar.transitionCoordinator.representingScope {
                case .month:
                    let rowCount = 6.0
                    let lineSpacing = calendar.appearance.minimumLineSpacing * CGFloat(rowCount - 1)
                    let height = (collectionView.bounds.height - contentInset - lineSpacing) / rowCount
                    return height
                case .week:
                    return collectionView.bounds.height - contentInset
                }
            }()
            return CGSize(width: width, height: height)
        }()

        // Calculate item widths and lefts
        widths = {
            let columnCount = 7
            let contentInset = calendar.appearance.contentInsets.left + calendar.appearance.contentInsets.right
            let interitemSpacing = calendar.appearance.minimumInteritemSpacing * CGFloat(columnCount - 1)
            let contentWidth = collectionView.bounds.width - contentInset - interitemSpacing
            let t = FSCalendarSliceCake(cake: contentWidth, count: columnCount)
            return t
        }()
        // Calculate every item lefts
        lefts = {
            var lefts: [CGFloat] = [calendar.appearance.contentInsets.left]
            for i in 1..<7 {
                lefts.append(lefts[i - 1] + widths[i - 1] + calendar.appearance.minimumInteritemSpacing)
            }
            return lefts
        }()
        // Calculate item heights and tops
        heights = {
            let rowCount = calendar.transitionCoordinator.representingScope == .week ? 1 : 6
            let contentInset = calendar.appearance.contentInsets.top + calendar.appearance.contentInsets.bottom
            let lineSpacing = calendar.appearance.minimumLineSpacing * CGFloat(rowCount - 1)
            let contentHeight = collectionView.bounds.height - contentInset - lineSpacing
            let t = FSCalendarSliceCake(cake: contentHeight, count: rowCount)
            return t
        }()
        // calculate every item tops
        tops = {
            let rowCount = calendar.transitionCoordinator.representingScope == .week ? 1 : 6
            var tops: [CGFloat] = [calendar.appearance.contentInsets.top]
            for i in 1..<rowCount {
                tops.append(tops[i - 1] + heights[i - 1] + calendar.appearance.minimumLineSpacing)
            }
            return tops
        }()

        // Calculate content size
        numberOfSections = collectionView.numberOfSections
        contentSize = CGSize(width: collectionView.bounds.width * CGFloat(numberOfSections), height: collectionView.bounds.height)

        calendar.adjustMonthPosition()
    }

    override var collectionViewContentSize: CGSize {
        return contentSize
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }
        guard let calendar = calendar else { return nil }

        let clippedRect = rect.intersection(CGRect(origin: .zero, size: contentSize))
        guard !clippedRect.isEmpty else { return nil }

        var layoutAttributes: [UICollectionViewLayoutAttributes] = []

        let startColumn: Int = {
            let startSection = Int(clippedRect.origin.x / collectionView.bounds.width)
            let remainder = clippedRect.origin.x.truncatingRemainder(dividingBy: collectionView.bounds.width)
            let max = max(0, remainder - calendar.appearance.contentInsets.left)
            let widthDelta = min(max, collectionView.bounds.width - calendar.appearance.contentInsets.left)
            let countDelta = Int(floor(widthDelta / estimatedItemSize.width))
            return startSection * 7 + countDelta
        }()

        let endColumn: Int = {
            let section = clippedRect.maxX / collectionView.bounds.width
            let remainder = section.truncatingRemainder(dividingBy: 1)
            if remainder <= max(100 * .ulpOfOne * abs(remainder), .leastNonzeroMagnitude) {
                return Int(floor(section)) * 7 - 1
            } else {
                let remainder = clippedRect.maxX.truncatingRemainder(dividingBy: collectionView.bounds.width)
                let max = max(0, remainder - calendar.appearance.contentInsets.left)
                let widthDelta = min(max, collectionView.bounds.width - calendar.appearance.contentInsets.left)
                let countDelta = Int(ceil(widthDelta / estimatedItemSize.width))
                return Int(floor(section)) * 7 + countDelta - 1
            }
        }()

        let numberOfRows = calendar.transitionCoordinator.representingScope == .month ? 6 : 1

        for column in startColumn...endColumn {
            for row in 0..<numberOfRows {
                let section = column / 7
                let item = column % 7 + row * 7
                let indexPath = IndexPath(item: item, section: section)
                if let attributes = layoutAttributesForItem(at: indexPath) {
                    layoutAttributes.append(attributes)
                }
            }
        }
        return layoutAttributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let calendar = calendar else { return nil }
        guard let collectionView = collectionView else { return nil }

        let coordinate = calendar.calculator.coordinate(for: indexPath)
        let column = coordinate.column
        let row = coordinate.row
        let numberOfRows = calendar.calculator.numberOfRows(inSection: indexPath.section)

        if let attributes = itemAttributes[indexPath] {
            return attributes
        }

        let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        let frame: CGRect = {
            guard row < heights.count, column < widths.count else {
                return .zero
            }
            let width = widths[column]
            let height = heights[row]
            let x = lefts[column] + CGFloat(indexPath.section) * collectionView.bounds.width
            let y = calculateRowOffset(row: row, totalRows: numberOfRows)
            return CGRect(x: x, y: y, width: width, height: height)
        }()
        attributes.frame = frame
        itemAttributes[indexPath] = attributes
        return attributes
    }
    
    private func calculateRowOffset(row: Int, totalRows: Int) -> CGFloat {
        guard let calendar = calendar else { return 0 }
        guard let collectionView = collectionView else { return 0 }

        if calendar.appearance.adjustsBoundingRectWhenChangingMonths {
            return tops[row]
        }

        let height = heights[row]
        switch totalRows {
        case 4, 5:
            let contentInset = calendar.appearance.contentInsets.top + calendar.appearance.contentInsets.bottom
            let lineSpacing = calendar.appearance.minimumLineSpacing * CGFloat(totalRows - 1)
            let contentHeight = collectionView.bounds.height - contentInset - lineSpacing
            let rowSpan = contentHeight / CGFloat(totalRows)
            return (CGFloat(row) + 0.5) * rowSpan - height * 0.5 + calendar.appearance.contentInsets.top
        case 6:
            return tops[row]
        default:
            return tops[row]
        }
    }

    override var flipsHorizontallyInOppositeLayoutDirection: Bool {
        return true
    }
}

protocol FSCalendarCollectionViewInternalDelegate: NSObjectProtocol {
    func collectionViewDidFinishLayoutSubviews(_ collectionView: FSCalendarCollectionView)
}

class FSCalendarCollectionView: UICollectionView {
    weak var innerDelegate: FSCalendarCollectionViewInternalDelegate?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        innerDelegate?.collectionViewDidFinishLayoutSubviews(self)
    }
}
