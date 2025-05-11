//
//  FSCalendarCalculator.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

struct FSCalendarCoordinate {
    var row: Int = 0
    var column: Int = 0
}

class FSCalendarCalculator: NSObject {
    weak var calendar: FSCalendar?

    var numberOfMonths: Int = 0
    var months: [NSNumber: Date] = [:]
    var monthHeads: [NSNumber: Date] = [:]

    var numberOfWeeks: Int = 0
    var weeks: [NSNumber: Date] = [:]
    var rowCounts: [Date: NSNumber] = [:]
    
    init(calendar: FSCalendar) {
        super.init()
        self.calendar = calendar

        self.months = [:]
        self.monthHeads = [:]
        self.weeks = [:]
        self.rowCounts = [:]
        
        addObserver()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
}

extension FSCalendarCalculator {
    var numberOfSections: Int {
        guard let calendar = calendar else { return 0 }
        switch calendar.transitionCoordinator.representingScope {
        case .month:
            return numberOfMonths
        case .week:
            return numberOfWeeks
        }
    }
    
    func reloadSections() {
        guard let calendar = calendar else { return }
        
        if let from = calendar.gregorian.firstDayOfMonth(calendar.minimumDate) {
            self.numberOfMonths = calendar.gregorian.dateComponents([.month], from: from, to: calendar.maximumDate).month ?? 0 + 1
        }
        if let from = calendar.gregorian.firstDayOfWeek(calendar.minimumDate) {
            self.numberOfWeeks = calendar.gregorian.dateComponents([.weekOfYear], from: from, to: calendar.maximumDate).weekOfYear ?? 0 + 1
        }
        clearCaches()
    }
    
    func monthPosition(for indexPath: IndexPath?) -> FSCalendarMonthPosition {
        guard let indexPath = indexPath else { return .notFound }
        guard let calendar = calendar else { return .notFound }
        
        if calendar.transitionCoordinator.representingScope == .week {
            return .current
        }
        guard let date = date(for: indexPath),
              let page = page(for: indexPath.section) else {
            return.notFound
        }
        let comparison = calendar.gregorian.compare(date, to: page, toGranularity: .month)
        switch comparison {
        case .orderedAscending:
            return .previous
        case .orderedSame:
            return .current
        case .orderedDescending:
            return .next
        }
    }
    
    func indexPath(for date: Date?, at position: FSCalendarMonthPosition = .current, scope: FSCalendarScope? = nil) -> IndexPath? {
        guard let calendar = calendar else { return nil }
        let scope = scope ?? calendar.transitionCoordinator.representingScope
        
        var item = 0
        var section = 0
        
        switch scope {
        case .month:
            guard let date = date,
                  let from = calendar.gregorian.firstDayOfMonth(calendar.minimumDate),
                  let to = calendar.gregorian.firstDayOfMonth(date) else { return nil }
            section = calendar.gregorian.dateComponents([.month], from: from, to: to).month ?? 0
            if position == .previous {
                section += 1
            } else if position == .next {
                section -= 1
            }
            guard let head = monthHead(for: section) else { return nil }
            item = calendar.gregorian.dateComponents([.day], from: head, to: date).day ?? 0
            
        case .week:
            guard let date = date,
                  let from = calendar.gregorian.firstDayOfWeek(calendar.minimumDate),
                  let to = calendar.gregorian.firstDayOfWeek(date) else { return nil }
            section = calendar.gregorian.dateComponents([.weekOfYear], from: from, to: to).weekOfYear ?? 0
            item = ((calendar.gregorian.component(.weekday, from: date) - calendar.gregorian.firstWeekday) + 7) % 7
        }
        
        if item < 0 || section < 0 {
            return nil
        }
        return IndexPath(item: item, section: section)
    }

    func date(for indexPath: IndexPath?, scope: FSCalendarScope? = nil) -> Date? {
        guard let calendar = calendar else { return nil }
        let scope = scope ?? calendar.transitionCoordinator.representingScope
        
        switch scope {
        case .month:
            guard let indexPath = indexPath, let month = monthHead(for: indexPath.section) else { return nil }
            let date = calendar.gregorian.date(byAdding: .day, value: indexPath.item, to: month)
            return date
        case .week:
            guard let indexPath = indexPath, let week = week(for: indexPath.section) else { return nil }
            let date = calendar.gregorian.date(byAdding: .day, value: indexPath.item, to: week)
            return date
        }
    }

    func numberOfRows(inMonth month: Date?) -> Int {
        guard let calendar = calendar else { return 0 }
        guard calendar.appearance.placeholderType != .fillSixRows else { return 6 }
        
        if let month = month, let rowCount = rowCounts[month] {
            return rowCount.intValue
        } else {
            guard let month = month, let firstDayOfMonth = calendar.gregorian.firstDayOfMonth(month) else { return 0 }
            let weekdayOfFirstDay = calendar.gregorian.component(.weekday, from: firstDayOfMonth)
            let numberOfDaysInMonth = calendar.gregorian.numberOfDaysInMonth(month)
            let numberOfPlaceholdersForPrev = ((weekdayOfFirstDay - calendar.gregorian.firstWeekday) + 7) % 7
            let headDayCount = numberOfDaysInMonth + numberOfPlaceholdersForPrev
            let numberOfRows = (headDayCount / 7) + (headDayCount % 7 > 0 ? 1 : 0)
            rowCounts[month] = NSNumber(value: numberOfRows)
            return numberOfRows
        }
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        guard let calendar = calendar else { return 0 }
        
        if calendar.transitionCoordinator.representingScope == .week {
            return 1
        }
        guard let month = month(for: section) else {
            return 0
        }
        return numberOfRows(inMonth: month)
    }
}

// MARK: Helper

func FSCalendarSliceCake(cake: CGFloat, count: Int) -> [CGFloat] {
    var total = cake
    var pieces = [CGFloat](repeating: 0, count: count)
    for i in 0..<count {
        let remains = count - i
        let piece = round(total / CGFloat(remains) * 2) * 0.5
        total -= piece
        pieces[i] = piece
    }
    return pieces
}

extension FSCalendarCalculator {
    func coordinate(for indexPath: IndexPath) -> FSCalendarCoordinate {
        var coordinate = FSCalendarCoordinate()
        coordinate.row = indexPath.item / 7
        coordinate.column = indexPath.item % 7
        return coordinate
    }
    
    func safeDate(for date: Date) -> Date {
        guard let calendar = calendar else { return date }
        if calendar.gregorian.compare(date, to: calendar.minimumDate, toGranularity: .day) == .orderedAscending {
            return calendar.minimumDate
        } else if calendar.gregorian.compare(date, to: calendar.maximumDate, toGranularity: .day) == .orderedDescending {
            return calendar.maximumDate
        }
        return date
    }
}

// MARK: Observer

extension FSCalendarCalculator {
    func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveNotifications(_:)), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
    }
    
    @objc func didReceiveNotifications(_ notification: Notification) {
        if notification.name == UIApplication.didReceiveMemoryWarningNotification {
            clearCaches()
        }
    }
}

// MARK: - Private

extension FSCalendarCalculator {
    private func page(for section: Int) -> Date? {
        guard let calendar = calendar else { return nil }
        let scope = calendar.transitionCoordinator.representingScope
        
        switch scope {
        case .week:
            return calendar.gregorian.middleDayOfWeek(week(for: section))
        case .month:
            return month(for: section)
        }
    }

    private func month(for section: Int) -> Date? {
        guard let calendar = calendar else { return nil }
        
        let key = NSNumber(value: section)
        if let month = months[key] {
            return month
        } else {
            guard let firstDayOfMonth = calendar.gregorian.firstDayOfMonth(calendar.minimumDate) else { return nil }
            guard let month = calendar.gregorian.date(byAdding: .month, value: section, to: firstDayOfMonth) else { return nil }
            let numberOfHeadPlaceholders = numberOfHeadPlaceholders(for: month)
            guard let monthHead = calendar.gregorian.date(byAdding: .day, value: -numberOfHeadPlaceholders, to: month) else { return nil }
            months[key] = month
            monthHeads[key] = monthHead
            return month
        }
    }
    
    /**
     661 value    Foundation.Date    2025-01-26 16:00:00 UTC
     662 value    Foundation.Date    2025-02-23 16:00:00 UTC
     664 value    Foundation.Date    2025-03-30 16:00:00 UTC
     664 value    Foundation.Date    2025-04-27 16:00:00 UTC
     */
    private func monthHead(for section: Int) -> Date? {
        guard let calendar = calendar else { return nil }
        let key = NSNumber(value: section)
        if let monthHead = monthHeads[key] {
            return monthHead
        } else {
            guard let firstDayOfMonth = calendar.gregorian.firstDayOfMonth(calendar.minimumDate),
                  let month = calendar.gregorian.date(byAdding: .month, value: section, to: firstDayOfMonth) else {
                return nil
            }
            let numberOfHeadPlaceholders = numberOfHeadPlaceholders(for: month)
            guard let monthHead = calendar.gregorian.date(byAdding: .day, value: -numberOfHeadPlaceholders, to: month) else {
                return nil
            }
            months[key] = month
            monthHeads[key] = monthHead
            return monthHead
        }
    }

    private func week(for section: Int) -> Date? {
        guard let calendar = calendar else { return nil }
        let key = NSNumber(value: section)
        if let week = weeks[key] {
            return week
        } else {
            guard let firstDayOfWeek = calendar.gregorian.firstDayOfWeek(calendar.minimumDate),
                  let week = calendar.gregorian.date(byAdding: .weekOfYear, value: section, to: firstDayOfWeek) else {
                return nil
            }
            weeks[key] = week
            return week
        }
    }
    
    private func numberOfHeadPlaceholders(for month: Date) -> Int {
        guard let calendar = calendar else { return 0 }

        let currentWeekday = calendar.gregorian.component(.weekday, from: month)
        var number = ((currentWeekday - calendar.gregorian.firstWeekday) + 7) % 7
        if number == 0 {
            number = (7 * (calendar.appearance.placeholderType == .fillSixRows ? 1 : 0))
        }
        return number
    }
    
    private func clearCaches() {
        months.removeAll()
        monthHeads.removeAll()
        weeks.removeAll()
        rowCounts.removeAll()
    }
}
