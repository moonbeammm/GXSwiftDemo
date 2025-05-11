//
//  FSCalendarAppearance.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

public enum FSCalendarCellState: Int {
    case normal
    case selected
    case placeholder
    case disabled
    case today
    case weekend
    case todaySelected
}

public enum FSCalendarCaseOptions: Int {
    case defaultCase // 周视图显示为“周一”、“周二”。。。
    case veryShortCase // 周视图显示为“一”、“二”。。。
}

public class FSCalendarAppearance: NSObject {
    // 日历配置
    public var scrollEnabled: Bool = true
    public var pagingEnabled: Bool = true
    public var allowsSelection: Bool = true
    public var firstWeekday: Int = 2
    public var locale: Locale = .current
    public var timeZone: TimeZone = .current
    public var dateFormat: String = "yyyy-MM-dd"
    public var minimumDate: String = "1970-01-01"
    public var maximumDate: String = "2099-12-31"
    /// 切换月份时日历高度是否自适应
    public var adjustsBoundingRectWhenChangingMonths: Bool = false
    public var placeholderType: FSCalendarPlaceholderType = .fillSixRows
    public var defaultScope: FSCalendarScope = .month
    public var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 12, right: 12)
    // 日历标题配置
    public var standardHeaderHeight: CGFloat = 44.0
    public var headerTitleFont: UIFont = UIFont.boldSystemFont(ofSize: 17.0)
    public var headerTitleColor: UIColor = .black
    // 周列表配置
    public var standardWeekdayHeight: CGFloat = 24.0
    public var weekdayFont: UIFont = UIFont.systemFont(ofSize: 12.0)
    public var weekdayTextColor: UIColor = .gray
    // cell配置
    public var minimumLineSpacing: CGFloat = 4.0
    public var minimumInteritemSpacing: CGFloat = 4.0
    // cell标题配置
    public var titleFont: UIFont = UIFont.systemFont(ofSize: 11.0)
    public var normalTitleColor: UIColor = .black
    public var selectionTitleColor: UIColor = .black
    public var todayTitleColor: UIColor?
    public var todaySelectionTitleColor: UIColor? = .white
    public var placeholderTitleColor: UIColor = .gray
    public var weekendTitleColor: UIColor = .black
    // cell背景色配置
    public var weekNormalCellBgColor: UIColor = .clear
    public var monthNormalCellBgColor: UIColor = .white
    public var selectionCellBgColor: UIColor?
    public var todayCellBgColor: UIColor?
    public var todaySelectionCellBgColor: UIColor? = .systemPink
    public var placeHolderCellBgColor: UIColor = .clear
    public var weekendCellBgColor: UIColor?
    // cell border配置
    public var normalBorderColor: UIColor = .clear
    public var selectionBorderColor: UIColor = .systemPink
    public var borderRadius: CGFloat = 8.0
    public var borderWidth: CGFloat = 1.0
    // 事件红点配置
    public var diameterOfEvents: CGFloat = 3.0
    public var normalEventColor: UIColor = .blue
    public var normalEventsColor: UIColor? = .purple
    public var selectionEventColor: UIColor?
    public var todaySelectionEventColor: UIColor? = .white
    
    public var caseOptions: FSCalendarCaseOptions = .veryShortCase
}
