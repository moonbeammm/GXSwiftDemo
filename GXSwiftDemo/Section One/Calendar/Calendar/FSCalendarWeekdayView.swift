//
//  FSCalendarWeekdayView.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

public class FSCalendarWeekdayView: UIView {
    
    weak var calendar: FSCalendar? {
        didSet {
            configureAppearance()
        }
    }
    
    private var weekdayLabels: [UILabel] = []
    private lazy var contentView: UIView = {
        let view = UIView(frame: .zero)
        self.addSubview(view)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        for _ in 0..<7 {
            let label = UILabel(frame: .zero)
            label.textAlignment = .center
            contentView.addSubview(label)
            weekdayLabels.append(label)
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard let calendar = calendar else { return }
        
        contentView.frame = bounds
        
        let count = weekdayLabels.count
        let contentInset = calendar.appearance.contentInsets.left + calendar.appearance.contentInsets.right
        let interitemSpacing = calendar.appearance.minimumInteritemSpacing * CGFloat(count - 1)
        let contentWidth = contentView.frame.width - contentInset - interitemSpacing
        let width = contentWidth / CGFloat(count)
        
        var x: CGFloat = calendar.appearance.contentInsets.left
        
        for i in 0..<count {
            let label = weekdayLabels[i]
            label.frame = CGRect(x: x, y: 0, width: width, height: contentView.frame.height)
            x += (width + calendar.appearance.minimumInteritemSpacing)
        }
    }
    
    func configureAppearance() {
        let useVeryShortWeekdaySymbols = (calendar?.appearance.caseOptions == .veryShortCase)
        let weekdaySymbols = useVeryShortWeekdaySymbols ? calendar?.gregorian.veryShortStandaloneWeekdaySymbols : calendar?.gregorian.shortStandaloneWeekdaySymbols
        
        for i in 0..<weekdayLabels.count {
            let index = (i + (calendar?.appearance.firstWeekday ?? 1) - 1) % 7
            let label = weekdayLabels[i]
            label.font = calendar?.appearance.weekdayFont
            label.textColor = calendar?.appearance.weekdayTextColor
            label.text = weekdaySymbols?[index]
        }
    }
}
