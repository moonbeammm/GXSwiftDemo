//
//  FSCalendarCell.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

public class FSCalendarCell: UICollectionViewCell {
    var container: UIView = {
        let t = UIView()
        return t
    }()
    var titleLabel: UILabel = {
        let t = UILabel(frame: .zero)
        t.textAlignment = .center
        t.textColor = .black
        return t
    }()
    var eventIndicator: UIView = {
        let t = UIView()
        t.backgroundColor = .clear
        t.isHidden = true
        return t
    }()
    
    weak var calendar: FSCalendar? {
        didSet {
            if calendar != oldValue {
                configureAppearance()
            }
        }
    }

    var monthPosition: FSCalendarMonthPosition = .notFound
    var dateIsToday: Bool = false
    var placeholder: Bool = false
    var weekend: Bool = false
    var numberOfEvents: Int = 0
    
    var eventIndicatorWidth: NSLayoutConstraint?
    var eventIndicatorHeight: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(eventIndicator)
        
        container.translatesAutoresizingMaskIntoConstraints = false
        container.leftAnchor.constraint(equalTo: contentView.leftAnchor).isActive = true
        container.rightAnchor.constraint(equalTo: contentView.rightAnchor).isActive = true
        container.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 4).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        
        eventIndicator.translatesAutoresizingMaskIntoConstraints = false
        eventIndicator.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8).isActive = true
        eventIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
        eventIndicatorWidth = eventIndicator.widthAnchor.constraint(equalToConstant: 3.0)
        eventIndicatorWidth?.isActive = true
        eventIndicatorHeight = eventIndicator.heightAnchor.constraint(equalToConstant: 3.0)
        eventIndicatorHeight?.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func performSelecting() {
        configureAppearance()
    }

    func configureAppearance() {
        container.backgroundColor = cellBgColor
        container.layer.borderColor = cellBorderColor?.cgColor
        container.layer.cornerRadius = calendar?.appearance.borderRadius ?? 0
        container.layer.borderWidth = isSelected ? calendar?.appearance.borderWidth ?? 0 : 0
        container.layer.masksToBounds = true
        
        titleLabel.textColor = titleLabelColor
        titleLabel.font = calendar?.appearance.titleFont
    
        eventIndicator.isHidden = numberOfEvents == 0
        eventIndicator.backgroundColor = colorsForEvents
        eventIndicator.layer.cornerRadius = (calendar?.appearance.diameterOfEvents ?? 0) / 2
        if eventIndicatorWidth?.constant != calendar?.appearance.diameterOfEvents {
            eventIndicatorWidth?.constant = calendar?.appearance.diameterOfEvents ?? 0
            eventIndicatorWidth?.isActive = true
        }
        if eventIndicatorHeight?.constant != calendar?.appearance.diameterOfEvents {
            eventIndicatorHeight?.constant = calendar?.appearance.diameterOfEvents ?? 0
            eventIndicatorHeight?.isActive = true
        }
    }
    
    private var cellBorderColor: UIColor? {
        guard let appearance = calendar?.appearance else { return nil }
        return isSelected ? appearance.selectionBorderColor : appearance.normalBorderColor
    }

    private var cellBgColor: UIColor? {
        if isSelected {
            if dateIsToday, let t = calendar?.appearance.todaySelectionCellBgColor {
                return t
            } else if let t = calendar?.appearance.selectionCellBgColor {
                return t
            }
        }
        if dateIsToday, let t = calendar?.appearance.todayCellBgColor {
            return t
        }
        if placeholder {
            return calendar?.appearance.placeHolderCellBgColor
        }
        if weekend, let t = calendar?.appearance.weekendCellBgColor {
            return t
        }
        if calendar?.transitionCoordinator.representingScope == .week, let t = calendar?.appearance.weekNormalCellBgColor {
            return t
        }
        return calendar?.appearance.monthNormalCellBgColor
    }

    private var titleLabelColor: UIColor? {
        if isSelected {
            if dateIsToday, let t = calendar?.appearance.todaySelectionTitleColor {
                return t
            } else {
                return calendar?.appearance.selectionTitleColor
            }
        }
        if dateIsToday, let t = calendar?.appearance.todayTitleColor {
            return t
        }
        if placeholder {
            return calendar?.appearance.placeholderTitleColor
        }
        if weekend {
            return calendar?.appearance.weekendTitleColor
        }
        return calendar?.appearance.normalTitleColor
    }

    private var colorsForEvents: UIColor? {
        if isSelected {
            if dateIsToday, let t = calendar?.appearance.todaySelectionEventColor {
                return t
            } else if let t = calendar?.appearance.selectionEventColor {
                return t
            }
        }
        if numberOfEvents > 1, let t = calendar?.appearance.normalEventsColor {
            return t
        }
        return calendar?.appearance.normalEventColor
    }
}

public class FSCalendarBlankCell: UICollectionViewCell {
    func configureAppearance() {
        
    }
}
