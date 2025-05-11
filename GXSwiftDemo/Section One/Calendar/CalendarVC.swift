import UIKit

class CalendarVC: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {
    private var calendar: FSCalendar!
    private var tableView: UITableView!
    private var calendarHeightConstraint: NSLayoutConstraint!
    private var scopeGesture: UIPanGestureRecognizer!

    // MARK: - Life cycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.lightGray

        // Initialize and configure calendar
        let appearance = FSCalendarAppearance()
        appearance.caseOptions = .veryShortCase
        appearance.placeholderType = .fillSixRows
        appearance.adjustsBoundingRectWhenChangingMonths = false
        appearance.locale = .current//Locale(identifier: "zh-CN")
        appearance.firstWeekday = 2 // Monday as the first column
        appearance.pagingEnabled = true
        appearance.scrollEnabled = true
        
        self.calendar = FSCalendar(appearance: appearance)
        self.calendar.delegate = self
        self.calendar.dataSource = self
        
        self.view.addSubview(self.calendar)

        self.calendar.selectDate(Date(), scrollToDate: true)

        self.calendar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.calendar.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
            self.calendar.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.calendar.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
        let height = 24.0 + 44.0 + 300.0
        self.calendarHeightConstraint = self.calendar.heightAnchor.constraint(equalToConstant: height)
        self.calendarHeightConstraint.isActive = true

        // Initialize and configure tableView
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(self.tableView)

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.calendar.bottomAnchor),
            self.tableView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.tableView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])

        // Add gesture recognizer
        // 不设置则不支持scope切换
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        self.view.addGestureRecognizer(panGesture)
        self.scopeGesture = panGesture

        // Ensure tableView's pan gesture fails when scope gesture begins
        self.tableView.panGestureRecognizer.require(toFail: panGesture)
    }

    // MARK: - UIGestureRecognizerDelegate

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            switch self.calendar.currentScope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            @unknown default:
                return false
            }
        }
        return shouldBegin
    }

    // MARK: - FSCalendarDelegate

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at position: FSCalendarMonthPosition) {
        print("did select date \(calendar.formatter.string(from: date))")
        
        if let t = calendar.selectedDate {
            let s = calendar.formatter.string(from: t)
            print("selected dates is \(s)")
        }
        
        if position == .next || position == .previous {
            calendar.changeCurrentPage(to: date, animated: true)
        }
    }
    
    func calendar(_ calendar: FSCalendar, willDisplay cell: FSCalendarCell, for date: Date, at position: FSCalendarMonthPosition) {
        
    }

    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height
        self.view.layoutIfNeeded()
    }

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        if let t = calendar.currentPage {
            print("\(#function) \(calendar.formatter.string(from: t))")
        }
    }

    // MARK: - FSCalendarDataSource

    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let datesWithEvent = ["2025-04-12", "2025-04-14", "2025-04-20", "2025-04-24", "2025-04-27", "2025-04-28"]
        let datesWithEvent1 = ["2025-04-13", "2025-04-15", "2025-04-21", "2025-04-26"]
        if datesWithEvent.contains(calendar.formatter.string(from: date)) {
            return 1
        } else if datesWithEvent1.contains(calendar.formatter.string(from: date)) {
            return 2
        } else {
            return 0
        }
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.contentView.backgroundColor = .red
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedScope: FSCalendarScope = self.calendar.currentScope == .month ? .week : .month
        self.calendar.changeScope(to: selectedScope, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
}
