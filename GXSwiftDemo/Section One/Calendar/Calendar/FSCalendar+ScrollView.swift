//
//  FSCalendar+ScrollView.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

extension FSCalendar: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.window != nil else { return }
        if hasValidateVisibleLayout {
            let scrollOffset = scrollView.contentOffset.x / scrollView.fs_width
            calendarHeaderView.setScrollOffset(scrollOffset)
        }
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard appearance.pagingEnabled, collectionView.isScrollEnabled else { return }
        
        let targetOffset = targetContentOffset.pointee.x
        let contentSize = scrollView.fs_width
        let sections = lrint(Double(targetOffset / contentSize))
        var targetPage: Date?
        
        switch currentScope {
        case .month:
            if let minimumPage = gregorian.firstDayOfMonth(minimumDate) {
                targetPage = gregorian.date(byAdding: .month, value: sections, to: minimumPage)
            }
        case .week:
            if let minimumPage = gregorian.firstDayOfWeek(minimumDate) {
                targetPage = gregorian.date(byAdding: .weekOfYear, value: sections, to: minimumPage)
            }
        }
        
        if let targetPage = targetPage, isDateInDifferentPage(targetPage) {
            let lastPage = currentPage
            currentPage = targetPage
            
            delegate?.calendarCurrentPageDidChange(self)
            
            if appearance.placeholderType != .fillSixRows, let lastPage = lastPage, let currentPage = currentPage {
                transitionCoordinator.performBoundingRectTransition(from: lastPage, to: currentPage, duration: 0.25)
            }
        }
    }
}
