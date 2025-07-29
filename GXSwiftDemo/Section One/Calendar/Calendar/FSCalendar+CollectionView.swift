//
//  FSCalendar+CollectionView.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

extension FSCalendar {
    public func registerClass(_ cellClass: AnyClass, forCellReuseIdentifier identifier: String) {
        guard !identifier.isEmpty else {
            fatalError("This identifier must not be nil and must not be an empty string.")
        }
        guard cellClass is FSCalendarCell.Type else {
            fatalError("The cell class must be a subclass of FSCalendarCell.")
        }
        guard identifier != String(describing: FSCalendarBlankCell.self) else {
            fatalError("Do not use \(identifier) as the cell reuse identifier.")
        }
        collectionView.register(cellClass, forCellWithReuseIdentifier: identifier)
    }
    
    public func dequeueReusableCell(withIdentifier identifier: String, for date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell? {
        guard !identifier.isEmpty else {
            fatalError("This identifier must not be nil and must not be an empty string.")
        }
        guard let indexPath = calculator.indexPath(for: date, at: position) else {
            fatalError("Attempting to dequeue a cell with invalid date.")
        }
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? FSCalendarCell else {
            fatalError("Failed to dequeue a cell with identifier \(identifier).")
        }
        return cell
    }
}

extension FSCalendar {
    public func cellForDate(_ date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell? {
        guard let indexPath = calculator.indexPath(for: date, at: position) else {
            return nil
        }
        return collectionView.cellForItem(at: indexPath) as? FSCalendarCell
    }
    
    public func dateForCell(_ cell: FSCalendarCell) -> Date? {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return nil
        }
        return calculator.date(for: indexPath)
    }
    
    public func monthPositionForCell(_ cell: FSCalendarCell) -> FSCalendarMonthPosition? {
        guard let indexPath = collectionView.indexPath(for: cell) else {
            return nil
        }
        return calculator.monthPosition(for: indexPath)
    }
    
    public func visibleCells() -> [FSCalendarCell] {
        return collectionView.visibleCells.compactMap { $0 as? FSCalendarCell }
    }
}

extension FSCalendar: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let monthPosition = calculator.monthPosition(for: indexPath)
        if appearance.placeholderType == .none && monthPosition != .current {
            return false
        }
        guard let date = calculator.date(for: indexPath) else { return false }
        
        return isDateInRange(date) && (delegate?.calendar(self, shouldSelect: date, at: monthPosition) ?? true)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let new = calculator.date(for: indexPath) else { return }
        
        let monthPosition = calculator.monthPosition(for: indexPath)
        var cell: FSCalendarCell?
        
        if monthPosition == .current {
            cell = collectionView.cellForItem(at: indexPath) as? FSCalendarCell
        } else {
            cell = self.cellForDate(new, at: .current)
            if let cell = cell, let cellIndexPath = collectionView.indexPath(for: cell) {
                collectionView.selectItem(at: cellIndexPath, animated: false, scrollPosition: [])
            }
        }
        
        if let cell = cell, selectedDate != new {
            cell.isSelected = true
            cell.performSelecting()
        }
        
        selectedDate = new
        delegate?.calendar(self, didSelect: new, at: monthPosition)
        selectCounterpartDate(new)
    }
    
    public func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        let monthPosition = calculator.monthPosition(for: indexPath)
        if appearance.placeholderType == .none && monthPosition != .current {
            return false
        }
        guard let date = calculator.date(for: indexPath) else { return false }
        return isDateInRange(date) && (delegate?.calendar(self, shouldDeselect: date, at: monthPosition) ?? true)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let selected = calculator.date(for: indexPath) else { return }
        let monthPosition = calculator.monthPosition(for: indexPath)
        var cell: FSCalendarCell?

        if monthPosition == .current {
            cell = collectionView.cellForItem(at: indexPath) as? FSCalendarCell
        } else {
            cell = self.cellForDate(selected, at: .current)
            if let cell = cell, let cellIndexPath = collectionView.indexPath(for: cell) {
                collectionView.deselectItem(at: cellIndexPath, animated: false)
            }
        }

        cell?.isSelected = false
        cell?.configureAppearance()

        selectedDate = nil
        delegate?.calendar(self, didDeselect: selected, at: monthPosition)
        deselectCounterpartDate(selected)
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let calendarCell = cell as? FSCalendarCell else {
            return
        }
        guard let date = calculator.date(for: indexPath) else {
            return
        }
        let monthPosition = calculator.monthPosition(for: indexPath)
        delegate?.calendar(self, willDisplay: calendarCell, for: date, at: monthPosition)
    }
}

extension FSCalendar: UICollectionViewDataSource {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return calculator.numberOfSections
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch transitionCoordinator.representingScope {
        case .month:
            return 42
        case .week:
            return 7
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let monthPosition = calculator.monthPosition(for: indexPath)
        
        switch appearance.placeholderType {
        case .none:
            if transitionCoordinator.representingScope == .month && monthPosition != .current {
                return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FSCalendarBlankCell.self), for: indexPath)
            }
        case .fillHeadTail:
            if transitionCoordinator.representingScope == .month {
                if indexPath.item >= 7 * calculator.numberOfRows(inSection: indexPath.section) {
                    return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FSCalendarBlankCell.self), for: indexPath)
                }
            }
        case .fillSixRows:
            break
        }
        var cell: FSCalendarCell?
        if let date = calculator.date(for: indexPath), let t = dataSource?.calendar(self, cellFor: date, at: monthPosition) {
            cell = t
        } else {
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FSCalendarCell.self), for: indexPath) as? FSCalendarCell
        }
        guard let cell = cell else {
            return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: FSCalendarCell.self), for: indexPath)
        }
        reloadData(for: cell, at: indexPath)
        return cell
    }
    
    private func reloadData(for cell: FSCalendarCell, at indexPath: IndexPath) {
        cell.calendar = self
        guard let date = calculator.date(for: indexPath) else { return }
        
        if let numberOfEvents = dataSource?.calendar(self, numberOfEventsFor: date) {
            cell.numberOfEvents = numberOfEvents
        }
        if let title = dataSource?.calendar(self, titleFor: date) {
            cell.titleLabel.text = title
        } else {
            cell.titleLabel.text = "\(gregorian.component(.day, from: date))"
        }
        
        cell.isSelected = selectedDate == date
        if let t = self.today {
            cell.dateIsToday = gregorian.isDate(date, inSameDayAs: t)
        }
        cell.weekend = gregorian.isDateInWeekend(date)
        cell.monthPosition = calculator.monthPosition(for: indexPath)
        
        switch transitionCoordinator.representingScope {
        case .month:
            cell.placeholder = (cell.monthPosition == .previous || cell.monthPosition == .next) || !isDateInRange(date)
            if cell.placeholder {
                cell.isSelected = cell.isSelected && appearance.pagingEnabled
                cell.dateIsToday = cell.dateIsToday && appearance.pagingEnabled
            }
        case .week:
            cell.placeholder = !isDateInRange(date)
        }
        
        if let transition = transitionCoordinator.transitionAttributes,
           transition.targetScope == .month {
            let row = calculator.coordinate(for: indexPath).row
            let focused = row == transition.focusedRow
            cell.alpha = focused ? 1.0 : 0.0
            print("sgx cell.alpha \(cell.alpha) title: \(cell.titleLabel.text)")
        }
        
        // Synchronize selection state with the collection view
        if cell.isSelected {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        } else {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        cell.configureAppearance()
    }
}
