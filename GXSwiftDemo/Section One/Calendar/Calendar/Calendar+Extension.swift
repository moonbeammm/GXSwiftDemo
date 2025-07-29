//
//  Calendar+Extension.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import Foundation

public extension Calendar {
    private static var componentsKey: UInt8 = 0
    var privateComponents: DateComponents {
        get {
            if let components = objc_getAssociatedObject(self, &Calendar.componentsKey) as? DateComponents {
                return components
            }
            let components = DateComponents()
            objc_setAssociatedObject(self, &Calendar.componentsKey, components, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return components
        }
    }
    /// 返回传入日期所在月份的1号
    func firstDayOfMonth(_ month: Date?) -> Date? {
        guard let month = month else { return nil }
        var components = self.dateComponents([.year, .month, .day, .hour], from: month)
        components.day = 1
        return self.date(from: components)
    }

    func lastDayOfMonth(_ month: Date?) -> Date? {
        guard let month = month else { return nil }
        var components = self.dateComponents([.year, .month, .day, .hour], from: month)
        components.month = (components.month ?? 0) + 1
        components.day = 0
        return self.date(from: components)
    }
    /// 返回传入日期所在周的第一天
    func firstDayOfWeek(_ week: Date?) -> Date? {
        guard let week = week else { return nil }
        let weekdayComponents = self.dateComponents([.weekday], from: week)
        var components = self.privateComponents
        guard let weekday = weekdayComponents.weekday else { return nil }
        components.day = -(weekday - self.firstWeekday)
        components.day = ((components.day ?? 0) - 7) % 7
        guard var firstDayOfWeek = self.date(byAdding: components, to: week) else { return nil }
        firstDayOfWeek = self.startOfDay(for: firstDayOfWeek)
        components.day = Int.max
        return firstDayOfWeek
    }

    func lastDayOfWeek(_ week: Date?) -> Date? {
        guard let week = week else { return nil }
        let weekdayComponents = self.dateComponents([.weekday], from: week)
        var components = self.privateComponents
        guard let weekday = weekdayComponents.weekday else { return nil }
        components.day = -(weekday - self.firstWeekday)
        components.day = ((components.day ?? 0) - 7) % 7 + 6
        guard var lastDayOfWeek = self.date(byAdding: components, to: week) else { return nil }
        lastDayOfWeek = self.startOfDay(for: lastDayOfWeek)
        components.day = Int.max
        return lastDayOfWeek
    }

    func middleDayOfWeek(_ week: Date?) -> Date? {
        guard let week = week else { return nil }
        let weekdayComponents = self.dateComponents([.weekday], from: week)
        var componentsToSubtract = self.privateComponents
        guard let weekday = weekdayComponents.weekday else { return nil }
        componentsToSubtract.day = -(weekday - self.firstWeekday) + 3
        if weekday < self.firstWeekday {
            componentsToSubtract.day = (componentsToSubtract.day ?? 0) - 7
        }
        guard var middleDayOfWeek = self.date(byAdding: componentsToSubtract, to: week) else { return nil }
        let components = self.dateComponents([.year, .month, .day, .hour], from: middleDayOfWeek)
        if let t = self.date(from: components) {
            middleDayOfWeek = t
            componentsToSubtract.day = Int.max
            return middleDayOfWeek
        } else {
            return nil
        }
    }

    func numberOfDaysInMonth(_ month: Date?) -> Int {
        guard let month = month else { return 0 }
        let days = self.range(of: .day, in: .month, for: month)
        return days?.count ?? 0
    }
}
