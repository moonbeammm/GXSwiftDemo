//
//  FSCalendarHeaderView.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

public class FSCalendarHeaderView: UIView {
    private lazy var textLabel: UILabel = {
        let t = UILabel()
        t.textAlignment = .center
        return t
    }()

    weak var calendar: FSCalendar?

    // MARK: - Life cycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textLabel)
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: self.topAnchor),
            textLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            textLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
            textLabel.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setScrollOffset(_ scrollOffset: CGFloat) {
        guard let calendar = calendar else { return }
        var date: Date?
        var text = ""

        switch calendar.transitionCoordinator.representingScope {
        case .month:
            date = calendar.gregorian.date(byAdding: .month, value: Int(scrollOffset), to: calendar.minimumDate)
        case .week:
            if let firstPage = calendar.gregorian.middleDayOfWeek(calendar.minimumDate) {
                date = calendar.gregorian.date(byAdding: .weekOfMonth, value: Int(scrollOffset), to: firstPage)
            }
        }

        if let date = date {
            let current = calendar.gregorian.dateComponents([.month, .year], from: Date())
            let components = calendar.gregorian.dateComponents([.month, .year], from: date)
            let monthString: String? = {
                let monthSymbols = calendar.gregorian.standaloneMonthSymbols
                if let month = components.month, monthSymbols.count == 12 {
                    return monthSymbols[month - 1]
                } else {
                    return nil
                }
            }()
            if let t = monthString {
                if let currentYear = current.year, currentYear != components.year {
                    text = "追更日历·\(currentYear)年\(t)"
                } else {
                    text = "追更日历·\(t)"
                }
            } else {
                text = "追更日历"
            }
        }
        self.textLabel.text = text
    }

    func configureAppearance() {
        guard let appearance = calendar?.appearance else { return }
        self.textLabel.font = appearance.headerTitleFont
        self.textLabel.textColor = appearance.headerTitleColor
        self.textLabel.textAlignment = .center
    }
}
