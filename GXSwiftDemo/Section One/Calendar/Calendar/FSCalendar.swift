//
//  FSCalendar.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

public enum FSCalendarScope {
    case month
    case week
    var toggle: FSCalendarScope {
        switch self {
        case .month:
            return .week
        case .week:
            return .month
        }
    }
}

public enum FSCalendarPlaceholderType {
    case none
    case fillHeadTail
    case fillSixRows
}

public enum FSCalendarMonthPosition {
    case previous
    case current
    case next
    case notFound
}
    
public protocol FSCalendarDataSource: NSObjectProtocol {
    func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String?
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell?
}

extension FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, titleFor date: Date) -> String? { return nil }
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int { return 0 }
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell? { return nil }
}

public protocol FSCalendarDelegate: NSObjectProtocol {
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at position: FSCalendarMonthPosition) -> Bool?
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at position: FSCalendarMonthPosition)
    func calendar(_ calendar: FSCalendar, shouldDeselect date: Date, at position: FSCalendarMonthPosition) -> Bool?
    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at position: FSCalendarMonthPosition)
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at position: FSCalendarMonthPosition)
    func calendarCurrentPageDidChange(_ calendar: FSCalendar)
}

extension FSCalendarDelegate {
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at position: FSCalendarMonthPosition) -> Bool? { return nil }
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at position: FSCalendarMonthPosition) {}
    func calendar(_ calendar: FSCalendar, shouldDeselect date: Date, at position: FSCalendarMonthPosition) -> Bool? { return nil }
    func calendar(_ calendar: FSCalendar, didDeselect date: Date, at position: FSCalendarMonthPosition) {}
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {}
    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at position: FSCalendarMonthPosition) {}
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {}
}

public class FSCalendar: UIView {
    // MARK: Public
    public weak var delegate: FSCalendarDelegate?
    public weak var dataSource: FSCalendarDataSource?
    
    public var appearance: FSCalendarAppearance
    
    public var currentPage: Date?
    public var currentScope: FSCalendarScope = .month
    
    public var selectedDate: Date?

    public var gregorian: Calendar { formatter.calendar }
    public private(set) lazy var formatter: DateFormatter = {
        var c = Calendar(identifier: .gregorian)
        c.locale = appearance.locale
        c.timeZone = appearance.timeZone
        c.firstWeekday = appearance.firstWeekday
        
        let t = DateFormatter()
        t.dateFormat = appearance.dateFormat
        t.calendar = c
        t.timeZone = appearance.timeZone
        t.locale = appearance.locale
        return t
    }()
    public private(set) lazy var minimumDate: Date = {
        let t = formatter.date(from: appearance.minimumDate) ?? Date()
        return t
    }()
    public private(set) lazy var maximumDate: Date = {
        let t = formatter.date(from: appearance.maximumDate) ?? Date()
        return t
    }()
    public lazy var today: Date? = gregorian.startOfDay(for: Date()) {
        didSet {
            if hasValidateVisibleLayout {
                for cell in visibleCells() {
                    cell.dateIsToday = false
                }
                if let today = today, let indexPath = calculator.indexPath(for: today) {
                    if let cell = collectionView.cellForItem(at: indexPath) as? FSCalendarCell {
                        cell.dateIsToday = true
                    }
                }
                visibleCells().forEach { $0.configureAppearance() }
            }
        }
    }
    
    // MARK: Private

    lazy var contentView: UIView = {
        let t = UIView()
        t.backgroundColor = .clear
        t.clipsToBounds = true
        return t
    }()
    public lazy var calendarHeaderView: FSCalendarHeaderView = {
        let t = FSCalendarHeaderView()
        t.calendar = self
        return t
    }()
    public lazy var calendarWeekdayView: FSCalendarWeekdayView = {
        let t = FSCalendarWeekdayView()
        t.calendar = self
        return t
    }()
    lazy var daysContainer: UIView = {
        let t = UIView()
        t.backgroundColor = .clear
        t.clipsToBounds = true
        return t
    }()
    lazy var collectionViewLayout: FSCalendarCollectionViewLayout = {
        let t = FSCalendarCollectionViewLayout()
        t.calendar = self
        return t
    }()
    lazy var collectionView: FSCalendarCollectionView = {
        let t = FSCalendarCollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
        t.dataSource = self
        t.delegate = self
        t.innerDelegate = self
        t.backgroundColor = .clear
        t.isPagingEnabled = appearance.pagingEnabled
        t.showsHorizontalScrollIndicator = false
        t.showsVerticalScrollIndicator = false
        t.clipsToBounds = true
        t.scrollsToTop = false
        t.allowsSelection = appearance.allowsSelection
        t.contentInset = .zero
        t.isPrefetchingEnabled = false
        t.isScrollEnabled = appearance.scrollEnabled
        t.contentInsetAdjustmentBehavior = .never
        t.register(FSCalendarCell.self, forCellWithReuseIdentifier: String(describing: FSCalendarCell.self))
        t.register(FSCalendarBlankCell.self, forCellWithReuseIdentifier: String(describing: FSCalendarBlankCell.self))
        return t
    }()
    
    lazy var transitionCoordinator: FSCalendarTransitionCoordinator = {
        let t = FSCalendarTransitionCoordinator(calendar: self)
        return t
    }()
    lazy var calculator: FSCalendarCalculator = {
        let t = FSCalendarCalculator(calendar: self)
        return t
    }()

    private var _preferredRowHeight: CGFloat = .infinity
    var preferredRowHeight: CGFloat {
        set {
            _preferredRowHeight = newValue
        }
        get {
            if _preferredRowHeight == .infinity {
                let headerHeight = appearance.standardHeaderHeight
                let weekdayHeight = appearance.standardWeekdayHeight
                let contentHeight = transitionCoordinator.cachedMonthSize.height - headerHeight - weekdayHeight
                let contentInset: CGFloat = appearance.contentInsets.top + appearance.contentInsets.bottom
                let rowCounts = 6.0
                let lineSpacing = appearance.minimumLineSpacing * (rowCounts - 1.0)
                _preferredRowHeight = (contentHeight - contentInset - lineSpacing) / rowCounts
            }
            return _preferredRowHeight
        }
    }
    
    internal var needsAdjustingViewFrame: Bool = true
    private var didLayoutOperations: [Operation] = []
    
    public init(appearance: FSCalendarAppearance = FSCalendarAppearance()) {
        self.appearance = appearance
        super.init(frame: .zero)
        self.backgroundColor = .clear
        configSubviews()
        invalidateLayout()
        
        currentPage = gregorian.firstDayOfMonth(today)
        calculator.reloadSections()
        changeScope(to: appearance.defaultScope)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public var bounds: CGRect {
        didSet {
            if !bounds.isEmpty && transitionCoordinator.state == .none {
                invalidateViewFrames()
            }
        }
    }

    override public var frame: CGRect {
        didSet {
            if !frame.isEmpty && transitionCoordinator.state == .none {
                invalidateViewFrames()
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        
        if needsAdjustingViewFrame {
            needsAdjustingViewFrame = false
            
            if transitionCoordinator.cachedMonthSize == .zero {
                transitionCoordinator.cachedMonthSize = self.frame.size
            }
            
            contentView.frame = self.bounds
            let headerHeight = appearance.standardHeaderHeight
            let weekdayHeight = appearance.standardWeekdayHeight
            var rowHeight = preferredRowHeight
            rowHeight = floor(rowHeight * 2) * 0.5 // Round to nearest multiple of 0.5
            
            calendarHeaderView.isHidden = headerHeight < 1.0
            calendarHeaderView.frame = CGRect(x: 0, y: 0, width: self.fs_width, height: headerHeight)
            calendarWeekdayView.isHidden = weekdayHeight < 1.0
            calendarWeekdayView.frame = CGRect(x: 0, y: calendarHeaderView.fs_bottom, width: contentView.fs_width, height: weekdayHeight)
            
            let contentInset = appearance.contentInsets.top + appearance.contentInsets.bottom
            
            switch transitionCoordinator.representingScope {
            case .month:
                let rowCounts = 6.0
                let lineSpacing = appearance.minimumLineSpacing * (rowCounts - 1.0)
                let contentHeight = rowHeight * rowCounts + contentInset + lineSpacing
                daysContainer.frame = CGRect(x: 0, y: headerHeight + weekdayHeight, width: self.fs_width, height: contentHeight)
                collectionView.frame = CGRect(x: 0, y: 0, width: daysContainer.fs_width, height: contentHeight)
            case .week:
                let contentHeight = rowHeight + contentInset
                daysContainer.frame = CGRect(x: 0, y: headerHeight + weekdayHeight, width: self.fs_width, height: contentHeight)
                collectionView.frame = CGRect(x: 0, y: 0, width: daysContainer.fs_width, height: contentHeight)
            }
            collectionView.fs_height = floor((collectionView.fs_height) * 2) * 0.5
        }
    }
}

extension FSCalendar {
    public func reloadData() {
        collectionView.reloadData()
    }

    public func changeScope(to scope: FSCalendarScope, animated: Bool = false) {
        guard transitionCoordinator.state == .none else { return }
        
        performEnsuringValidLayout {
            self.transitionCoordinator.performScopeTransition(from: self.currentScope, to: scope, animated: animated)
        }
    }

    public func selectDate(_ date: Date?, scrollToDate: Bool = true, at monthPosition: FSCalendarMonthPosition = .current) {
        guard collectionView.allowsSelection, let date = date else { return }
        
        let targetDate = gregorian.startOfDay(for: date)
        guard let targetIndexPath = calculator.indexPath(for: targetDate) else { return }
                
        if monthPosition == .previous || monthPosition == .next {
            // 业务方实现了，并且不允许，则return
            if let t = delegate?.calendar(self, shouldSelect: targetDate, at: monthPosition), t == false {
                return
            } else {
                if isDateSelected(targetDate) {
                    delegate?.calendar(self, didSelect: targetDate, at: monthPosition)
                } else {
                    if let selectedDate = selectedDate {
                        deselectDate(selectedDate)
                    }
                    collectionView.selectItem(at: targetIndexPath, animated: true, scrollPosition: [])
                    collectionView(collectionView, didSelectItemAt: targetIndexPath)
                }
            }
        } else if !isDateSelected(targetDate) {
            if let selectedDate = selectedDate {
                deselectDate(selectedDate)
            }
            collectionView.selectItem(at: targetIndexPath, animated: false, scrollPosition: [])
            if let cell = collectionView.cellForItem(at: targetIndexPath) as? FSCalendarCell {
                cell.performSelecting()
            }

            selectedDate = targetDate
            selectCounterpartDate(targetDate)
        } else if !(collectionView.indexPathsForSelectedItems?.contains(targetIndexPath) ?? false) {
            collectionView.selectItem(at: targetIndexPath, animated: false, scrollPosition: [])
        }
        
        if scrollToDate {
            scrollToPage(for: targetDate, animated: true)
        }
    }
    
    public func deselectDate(_ date: Date) {
        let date = gregorian.startOfDay(for: date)
        selectedDate = nil
        deselectCounterpartDate(date)
        if let indexPath = calculator.indexPath(for: date),
           collectionView.indexPathsForSelectedItems?.contains(indexPath) == true {
            collectionView.deselectItem(at: indexPath, animated: true)
            if let cell = collectionView.cellForItem(at: indexPath) as? FSCalendarCell {
                cell.isSelected = false
                cell.configureAppearance()
            }
        }
    }
    
    public func changeCurrentPage(to page: Date, animated: Bool) {
        if isDateInDifferentPage(page) {
            let startOfDay = gregorian.startOfDay(for: page)
            if isPageInRange(startOfDay) {
                scrollToPage(for: startOfDay, animated: animated)
            }
        }
    }
}

extension FSCalendar: FSCalendarCollectionViewInternalDelegate {
    func collectionViewDidFinishLayoutSubviews(_ collectionView: FSCalendarCollectionView) {
        executePendingOperationsIfNeeded()
    }
    
    func executePendingOperationsIfNeeded() {
        var operations: [Operation]? = nil
        if !didLayoutOperations.isEmpty {
            operations = didLayoutOperations
            didLayoutOperations.removeAll()
        }
        operations?.forEach { $0.start() }
    }
}

extension FSCalendar {
    private func invalidateLayout() {
        preferredRowHeight = .infinity
        needsAdjustingViewFrame = true
        setNeedsLayout()
    }
    
    private func invalidateViewFrames() {
        needsAdjustingViewFrame = true
        preferredRowHeight = .infinity
        setNeedsLayout()
    }
}

extension FSCalendar {
    private func configSubviews() {
        addSubview(contentView)
        
        contentView.addSubview(daysContainer)
        daysContainer.addSubview(collectionView)
        
        contentView.addSubview(calendarHeaderView)
        contentView.addSubview(calendarWeekdayView)
    }
    
    func configureAppearance() {
        visibleCells().forEach { $0.configureAppearance() }
        calendarHeaderView.configureAppearance()
        calendarWeekdayView.configureAppearance()
    }
}

extension FSCalendar {
    var hasValidateVisibleLayout: Bool {
        return collectionView.superview != nil &&
        !(collectionView.frame.isEmpty) &&
        !(collectionViewLayout.collectionViewContentSize == .zero)
    }

    func adjustMonthPosition() {
        let targetPage = appearance.pagingEnabled ? currentPage : (currentPage ?? selectedDate)
        scrollToPage(for: targetPage, animated: false)
    }
    
    func isDateInRange(_ date: Date) -> Bool {
        var flag = true
        flag = flag && (gregorian.dateComponents([.day], from: date, to: minimumDate).day ?? 0) <= 0
        flag = flag && (gregorian.dateComponents([.day], from: date, to: maximumDate).day ?? 0) >= 0
        return flag
    }

    func isPageInRange(_ page: Date) -> Bool {
        var flag = true
        switch transitionCoordinator.representingScope {
        case .month:
            guard let firstDayOfMinMonth = gregorian.firstDayOfMonth(minimumDate),
                  let lastDayOfMaxMonth = gregorian.lastDayOfMonth(maximumDate) else {
                return false
            }
            let c1 = gregorian.dateComponents([.day], from: firstDayOfMinMonth, to: page).day ?? 0
            flag = flag && (c1 >= 0)
            if !flag { break }
            let c2 = gregorian.dateComponents([.day], from: page, to: lastDayOfMaxMonth).day ?? 0
            flag = flag && (c2 >= 0)
        case .week:
            guard let firstDayOfMinWeek = gregorian.firstDayOfWeek(minimumDate),
                  let lastDayOfMaxWeek = gregorian.lastDayOfWeek(maximumDate) else {
                return false
            }
            let c1 = gregorian.dateComponents([.day], from: firstDayOfMinWeek, to: page).day ?? 0
            flag = flag && (c1 >= 0)
            if !flag { break }
            let c2 = gregorian.dateComponents([.day], from: page, to: lastDayOfMaxWeek).day ?? 0
            flag = flag && (c2 >= 0)
        }
        return flag
    }

    func isDateSelected(_ date: Date) -> Bool {
        if selectedDate == date {
            return true
        } else if let indexPath = calculator.indexPath(for: date), let indexPaths = collectionView.indexPathsForSelectedItems {
            return indexPaths.contains(indexPath)
        } else {
            return false
        }
    }
}

extension FSCalendar {
    func adjustBoundingRectIfNecessary() {
        guard appearance.placeholderType != .fillSixRows else { return }
        guard appearance.adjustsBoundingRectWhenChangingMonths else { return }
        performEnsuringValidLayout { [weak self] in
            self?.transitionCoordinator.performBoundingRectTransition(from: nil, to: self?.currentPage, duration: 0)
        }
    }

    func performEnsuringValidLayout(_ block: @escaping () -> Void) {
        if collectionView.visibleCells.count > 0 {
            block()
        } else {
            setNeedsLayout()
            didLayoutOperations.append(BlockOperation(block: block))
        }
    }
}

extension FSCalendar {
    func selectCounterpartDate(_ date: Date) {
        guard appearance.placeholderType != .none else { return }
        guard currentScope != .week else { return }
        
        let numberOfDays = gregorian.numberOfDaysInMonth(date)
        let day = gregorian.component(.day, from: date)
        var cell: FSCalendarCell?
        
        if day < numberOfDays / 2 + 1 {
            cell = cellForDate(date, at: .next)
        } else {
            cell = cellForDate(date, at: .previous)
        }
        
        if let cell = cell {
            cell.isSelected = true
            cell.configureAppearance()
        }
    }

    func deselectCounterpartDate(_ date: Date) {
        guard appearance.placeholderType != .none else { return }
        guard currentScope != .week else { return }
        
        let numberOfDays = gregorian.numberOfDaysInMonth(date)
        let day = gregorian.component(.day, from: date)
        var cell: FSCalendarCell?
        
        if day < numberOfDays / 2 + 1 {
            cell = cellForDate(date, at: .next)
        } else {
            cell = cellForDate(date, at: .previous)
        }
        
        if let cell = cell {
            cell.isSelected = false
            if let indexPath = collectionView.indexPath(for: cell) {
                collectionView.deselectItem(at: indexPath, animated: false)
            }
            cell.configureAppearance()
        }
    }
}

extension FSCalendar {
    func isDateInDifferentPage(_ date: Date) -> Bool {
        guard let currentPage = currentPage else {
            return false
        }
        switch currentScope {
        case .month:
            return !gregorian.isDate(date, equalTo: currentPage, toGranularity: .month)
        case .week:
            return !gregorian.isDate(date, equalTo: currentPage, toGranularity: .weekOfYear)
        }
    }
    func sizeThatFits(_ size: CGSize, scope: FSCalendarScope) -> CGSize {
        let headerHeight = appearance.standardHeaderHeight
        let weekdayHeight = appearance.standardWeekdayHeight
        let rowHeight = preferredRowHeight
        let contentInset = appearance.contentInsets.top + appearance.contentInsets.bottom

        switch scope {
        case .month:
            let rowCounts = CGFloat(calculator.numberOfRows(inMonth: currentPage))
            let lineSpacing = appearance.minimumLineSpacing * (rowCounts - 1.0)
            let height = weekdayHeight + headerHeight + rowCounts * rowHeight + contentInset + lineSpacing
            return CGSize(width: size.width, height: height)
        case .week:
            let height = weekdayHeight + headerHeight + rowHeight + contentInset
            return CGSize(width: size.width, height: height)
        }
    }
}

extension FSCalendar {
    func scrollToDate(_ date: Date, animated: Bool = false) {
        let animated = animated && collectionView.isScrollEnabled // No animation if scrollEnabled is false
        
        let safeDate = calculator.safeDate(for: date)
        guard let indexPath = calculator.indexPath(for: safeDate, at: .current) else {
            return
        }
        let scrollOffset = indexPath.section
        collectionView.setContentOffset(CGPoint(x: CGFloat(scrollOffset) * collectionView.fs_width, y: 0), animated: animated)
        
        if !animated {
            calendarHeaderView.setScrollOffset(CGFloat(scrollOffset))
        }
    }

    func scrollToPage(for date: Date?, animated: Bool) {
        guard let date = date else { return }
        guard isDateInRange(date) else {
            let safeDate = calculator.safeDate(for: date)
            scrollToPage(for: safeDate, animated: animated)
            return
        }
        
        if isDateInDifferentPage(date) {
            let lastPage = currentPage
            switch transitionCoordinator.representingScope {
            case .month:
                currentPage = gregorian.firstDayOfMonth(date)
            case .week:
                currentPage = gregorian.firstDayOfWeek(date)
            @unknown default:
                break
            }
            
            if hasValidateVisibleLayout {
                delegate?.calendarCurrentPageDidChange(self)
                if appearance.placeholderType != .fillSixRows, transitionCoordinator.state == .none, let lastPage = lastPage, let currentPage = currentPage {
                    transitionCoordinator.performBoundingRectTransition(from: lastPage, to: currentPage, duration: 0.33)
                }
            }
        }
        if let currentPage = currentPage {
            scrollToDate(currentPage, animated: animated)
        }
    }
}
