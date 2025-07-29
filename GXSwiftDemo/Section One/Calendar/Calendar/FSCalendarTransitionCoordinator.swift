//
//  FSCalendarTransitionCoordinator.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit
import Foundation

public enum FSCalendarTransitionState {
    case none
    case changing
    case finish
}

class FSCalendarTransitionAttributes: NSObject {
    var sourceBounds: CGRect = .zero
    var targetBounds: CGRect = .zero
    var sourcePage: Date?
    var targetPage: Date?
    var focusedRow: Int = 0
    var focusedDate: Date?
    var targetScope: FSCalendarScope = .month

    func revert() {
        let tempRect = sourceBounds
        sourceBounds = targetBounds
        targetBounds = tempRect

        let tempDate = sourcePage
        sourcePage = targetPage
        targetPage = tempDate

        targetScope = targetScope.toggle
    }
}

class FSCalendarTransitionCoordinator: NSObject {
    var state: FSCalendarTransitionState = .none
    var cachedMonthSize: CGSize = .zero
    var representingScope: FSCalendarScope {
        switch state {
        case .none:
            return calendar?.currentScope ?? .month
        case .changing, .finish:
            return .month
        }
    }
    weak var calendar: FSCalendar?
    var transitionAttributes: FSCalendarTransitionAttributes?

    init(calendar: FSCalendar) {
        super.init()
        self.calendar = calendar
    }
    
    func performBoundingRectTransition(from: Date?, to: Date?, duration: CGFloat) {
        guard let calendar = calendar else { return }
        guard calendar.appearance.adjustsBoundingRectWhenChangingMonths else { return }
        guard calendar.currentScope == .month else { return }
        
        let lastRowCount = calendar.calculator.numberOfRows(inMonth: from)
        let currentRowCount = calendar.calculator.numberOfRows(inMonth: to)
        
        if lastRowCount != currentRowCount {
            let animationDuration = duration
            let bounds = boundingRect(for: .month)
            
            state = .changing
            
            let completion: (Bool) -> Void = { finished in
                DispatchQueue.main.asyncAfter(deadline: .now() + max(0, duration - animationDuration)) { [weak self] in
                    self?.calendar?.needsAdjustingViewFrame = true
                    self?.calendar?.setNeedsLayout()
                    self?.state = .none
                }
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0, options: .allowUserInteraction, animations: { [weak self] in
                self?.boundingRectWillChange(to: bounds, animated: true)
            }, completion: completion)
        }
    }
    
    func performScopeTransition(from fromScope: FSCalendarScope, to toScope: FSCalendarScope, animated: Bool) {
        guard let calendar = calendar else { return }
        if fromScope == toScope {
            calendar.currentScope = toScope
            return
        }
        // Start transition
        state = .finish
        let attr = createTransitionAttributes(targetScope: toScope)
        transitionAttributes = attr
        if toScope == .month {
            prepareWeekToMonthTransition()
        }
        performTransition(to: attr.targetScope, fromProgress: 0, toProgress: 1, animated: animated)
    }
}

extension FSCalendarTransitionCoordinator {
    private func boundingRect(for scope: FSCalendarScope) -> CGRect {
        guard let calendar = calendar else { return .zero }
        
        let contentSize: CGSize
        switch scope {
        case .month:
            if calendar.appearance.adjustsBoundingRectWhenChangingMonths {
                contentSize = calendar.sizeThatFits(calendar.frame.size, scope: scope)
            } else {
                contentSize = cachedMonthSize
            }
        case .week:
            contentSize = calendar.sizeThatFits(calendar.frame.size, scope: scope)
        }
        return CGRect(origin: .zero, size: contentSize)
    }

    private func boundingRectWillChange(to targetBounds: CGRect, animated: Bool) {
        guard let calendar = calendar else { return }
        calendar.contentView.fs_height = targetBounds.height
        calendar.daysContainer.fs_height = targetBounds.height - calendar.appearance.standardHeaderHeight - calendar.appearance.standardWeekdayHeight
        calendar.delegate?.calendar(calendar, boundingRectWillChange: targetBounds, animated: animated)
    }
    
    private func performTransition(to targetScope: FSCalendarScope, fromProgress: CGFloat, toProgress: CGFloat, animated: Bool) {
        guard let attr = transitionAttributes else { return }
        guard let calendar = calendar else { return }
        
        calendar.currentScope = targetScope
        if targetScope == .week, let t = attr.targetPage {
            calendar.currentPage = t
        }
        
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: { [weak self] in
                self?.performAlphaAnimation(withProgress: toProgress)
                self?.calendar?.collectionView.fs_top = self?.calculateOffset(forProgress: toProgress) ?? 0
                self?.boundingRectWillChange(to: attr.targetBounds, animated: true)
            }, completion: { _ in
                self.performTransitionCompletion(animated: true)
            })
        } else {
            performTransitionCompletion(animated: animated)
            boundingRectWillChange(to: attr.targetBounds, animated: animated)
        }
    }
    
    private func performTransitionCompletion(animated: Bool) {
        guard let calendar = calendar else { return }
        switch transitionAttributes?.targetScope {
        case .week:
            calendar.needsAdjustingViewFrame = true
            calendar.collectionView.reloadData()
        case .month:
            calendar.needsAdjustingViewFrame = true
        default:
            break
        }
        state = .none
        transitionAttributes = nil
        
        calendar.reloadData()
        calendar.setNeedsLayout()
        calendar.layoutIfNeeded()
    }
    
    private func performAlphaAnimation(withProgress progress: CGFloat) {
        guard let calendar = calendar, let transition = transitionAttributes else { return }
        let opacity: CGFloat = transition.targetScope == .week ? max(1 - progress * 1.1, 0) : progress
        let visibleCells = calendar.visibleCells()

        var surroundingCells: [FSCalendarCell] = []
        var focusedCells: [FSCalendarCell] = []
        for cell in visibleCells {
            let focused: Bool = {
                if calendar.collectionView.bounds.contains(cell.center) == false {
                    return false
                }
                guard let indexPath = calendar.collectionView.indexPath(for: cell) else { return false }
                let row = calendar.calculator.coordinate(for: indexPath).row
                return row == transition.focusedRow
            }()
            if focused {
                focusedCells.append(cell)
            } else {
                surroundingCells.append(cell)
            }
        }
        
        surroundingCells.forEach { cell in
            print("sgx opacity \(opacity) cell.alpha \(cell.alpha) title: \(cell.titleLabel.text)")
            if let targetColor = cell.cellBgColor(.month) {
                cell.container.backgroundColor = targetColor
            }
            cell.alpha = opacity
        }
        focusedCells.forEach { cell in
            guard let currentColor = cell.cellBgColor(transition.targetScope.toggle),
                  let targetColor = cell.cellBgColor(transition.targetScope) else {
                return
            }
            cell.container.backgroundColor = UIColor.interpolate(from: currentColor, to: targetColor, with: progress)
        }
    }
    
    private func performPathAnimation(withProgress progress: CGFloat) {
        guard let transitionAttributes = transitionAttributes else { return }
        let targetHeight = transitionAttributes.targetBounds.height
        let sourceHeight = transitionAttributes.sourceBounds.height
        let currentHeight = sourceHeight - (sourceHeight - targetHeight) * progress
        let currentBounds = CGRect(x: 0, y: 0, width: transitionAttributes.targetBounds.width, height: currentHeight)
        calendar?.collectionView.fs_top = calculateOffset(forProgress: progress)
        boundingRectWillChange(to: currentBounds, animated: false)
        if transitionAttributes.targetScope == .month {
            calendar?.contentView.fs_height = targetHeight
        }
    }

    private func calculateOffset(forProgress progress: CGFloat) -> CGFloat {
        guard let calendar = calendar,
              let indexPath = calendar.calculator.indexPath(for: transitionAttributes?.focusedDate, scope: .month),
              let frame = calendar.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.frame else {
            return 0
        }
        let ratio: CGFloat = transitionAttributes?.targetScope == .week ? progress : (1 - progress)
        let offset = (-frame.origin.y + calendar.appearance.contentInsets.top) * ratio
        return offset
    }
    
    private func prepareWeekToMonthTransition() {
        if let t = transitionAttributes?.targetPage {
            calendar?.currentPage = t
        }
        if let t = transitionAttributes?.targetBounds.height {
            calendar?.contentView.fs_height = t
        }
        calendar?.needsAdjustingViewFrame = true
//        calendar?.collectionView.collectionViewLayout.invalidateLayout()
        CATransaction.begin()
        CATransaction.setDisableActions(false)
        
        

        
        
        calendar?.collectionView.reloadData()
        calendar?.layoutIfNeeded()
        
        let visibleCells = calendar?.visibleCells() ?? []

        var surroundingCells: [FSCalendarCell] = []
        var focusedCells: [FSCalendarCell] = []
        for cell in visibleCells {
            let focused: Bool = {
                if calendar?.collectionView.bounds.contains(cell.center) == false {
                    return false
                }
                guard let indexPath = calendar?.collectionView.indexPath(for: cell) else { return false }
                let row = calendar?.calculator.coordinate(for: indexPath).row
                return row == transitionAttributes?.focusedRow
            }()
            if focused {
                focusedCells.append(cell)
            } else {
                surroundingCells.append(cell)
            }
        }
        
        surroundingCells.forEach { cell in
            cell.alpha = 0.0
        }
        
        CATransaction.commit()
//
        calendar?.collectionView.fs_top = calculateOffset(forProgress: 0)
    }
}

extension UIColor {
    /// 根据系数（0~1）在两个颜色之间插值
    static func interpolate(from startColor: UIColor, to endColor: UIColor, with ratio: CGFloat) -> UIColor {
        var startRed: CGFloat = 0, startGreen: CGFloat = 0, startBlue: CGFloat = 0, startAlpha: CGFloat = 0
        var endRed: CGFloat = 0, endGreen: CGFloat = 0, endBlue: CGFloat = 0, endAlpha: CGFloat = 0
        
        // 获取颜色的 RGBA 分量
        startColor.getRed(&startRed, green: &startGreen, blue: &startBlue, alpha: &startAlpha)
        endColor.getRed(&endRed, green: &endGreen, blue: &endBlue, alpha: &endAlpha)
        
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        if startAlpha < 0.01 {
            red = endRed
            green = endGreen
            blue = endBlue
            alpha = startAlpha + (endAlpha - startAlpha) * ratio
        } else if endAlpha < 0.01 {
            red = startRed
            green = startGreen
            blue = startBlue
            alpha = startAlpha + (endAlpha - startAlpha) * ratio
        } else {
            // 计算插值后的颜色分量
            red = startRed + (endRed - startRed) * ratio
            green = startGreen + (endGreen - startGreen) * ratio
            blue = startBlue + (endBlue - startBlue) * ratio
            alpha = startAlpha + (endAlpha - startAlpha) * ratio
        }

        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension FSCalendarTransitionCoordinator {
    private func createTransitionAttributes(targetScope: FSCalendarScope) -> FSCalendarTransitionAttributes {
        guard let calendar = calendar else { return FSCalendarTransitionAttributes() }
        let attributes = FSCalendarTransitionAttributes()
        attributes.sourceBounds = calendar.bounds
        attributes.sourcePage = calendar.currentPage
        attributes.targetScope = targetScope
        attributes.focusedDate = {
            let candidates: [Date] = {
                var dates: [Date] = []
                if let select = calendar.selectedDate {
                    dates.append(select)
                }
                if let today = calendar.today {
                    dates.append(today)
                }
                if targetScope == .week, let t = calendar.currentPage {
                    dates.append(t)
                } else {
                    if let t = calendar.currentPage, let newDate = calendar.gregorian.date(byAdding: .day, value: 3, to: t) {
                        dates.append(newDate)
                    }
                }
                return dates
            }()
            let visibleCandidates = candidates.filter { date in
                guard let indexPath = calendar.calculator.indexPath(for: date, scope: targetScope.toggle),
                      let currentSection = calendar.calculator.indexPath(for: calendar.currentPage, scope: targetScope.toggle)?.section else {
                    return false
                }
                return indexPath.section == currentSection
            }
            return visibleCandidates.first
        }()
        attributes.focusedRow = {
            guard let focusedDate = attributes.focusedDate,
                  let indexPath = calendar.calculator.indexPath(for: focusedDate, scope: .month) else {
                return 0
            }
            return calendar.calculator.coordinate(for: indexPath).row
        }()
        attributes.targetPage = {
            guard let focusedDate = attributes.focusedDate else { return nil }
            return targetScope == .month
                ? calendar.gregorian.firstDayOfMonth(focusedDate)
                : calendar.gregorian.middleDayOfWeek(focusedDate)
        }()
        attributes.targetBounds = boundingRect(for: attributes.targetScope)
        return attributes
    }
}

// MARK: Gesture

extension FSCalendarTransitionCoordinator {
    func handleScopeGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            scopeTransitionDidBegin(sender)
        case .changed:
            scopeTransitionDidUpdate(sender)
        case .ended, .cancelled, .failed:
            scopeTransitionDidEnd(sender)
        default:
            break
        }
    }
    
    private func scopeTransitionDidBegin(_ panGesture: UIPanGestureRecognizer) {
        guard state == .none, let calendar = calendar else { return }

        let velocity = panGesture.velocity(in: panGesture.view)
//        print("sgx >> update \(velocity)")
        if calendar.currentScope == .month && velocity.y >= 0 {
            return
        }
        if calendar.currentScope == .week && velocity.y <= 0 {
            return
        }
        
        state = .changing

        transitionAttributes = createTransitionAttributes(targetScope: calendar.currentScope.toggle)

        if transitionAttributes?.targetScope == .month {
            prepareWeekToMonthTransition()
        }
    }

    private func scopeTransitionDidUpdate(_ panGesture: UIPanGestureRecognizer) {
        guard state == .changing else { return }

        let translation = panGesture.translation(in: panGesture.view).y
        
        let velocity = panGesture.velocity(in: panGesture.view)
//        print("sgx >> update \(velocity)")
        
        if calendar?.currentScope == .month && translation >= 0 {
            return
        }
        if calendar?.currentScope == .week && translation <= 0 {
            return
        }
        
        let progress: CGFloat = {
            let maxTranslation = abs((transitionAttributes?.targetBounds.height ?? 0) - (transitionAttributes?.sourceBounds.height ?? 0))
            let clampedTranslation = max(0, min(maxTranslation, abs(translation)))
            return clampedTranslation / maxTranslation
        }()
        
//        print("sgx >> update \(progress) \(translation)")
        performAlphaAnimation(withProgress: progress)
        performPathAnimation(withProgress: progress)
    }
    
    private func scopeTransitionDidEnd(_ panGesture: UIPanGestureRecognizer) {
        guard state == .changing, let transition = transitionAttributes else { return }
        
        state = .finish

        let translation = panGesture.translation(in: panGesture.view).y
        let velocity = panGesture.velocity(in: panGesture.view).y
        
        let maxTranslation = transition.targetBounds.height - transition.sourceBounds.height
        let progress: CGFloat = {
            let clampedTranslation = max(0, min(maxTranslation, translation))
            return clampedTranslation / maxTranslation
        }()
//        print("sgx >> end \(velocity) \(translation) \(maxTranslation)")
//        if velocity * translation < 0 {
//            transitionAttributes?.revert()
//        }
        if abs(translation) < 40 ||
           (calendar?.currentScope == .month && velocity >= 0) || // 当前为月态，但是手势结束的时候用户是往下滑的，则revert
           (calendar?.currentScope == .week && velocity <= 0) {   // 当前为周态，但是手势结束的时候用户是往上滑的，则revert
            transition.revert()
        }
        performTransition(to: transition.targetScope, fromProgress: progress, toProgress: 1.0, animated: true)
    }
    
    private func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard state == .none, let calendar = calendar else { return false }

        if let panGesture = gestureRecognizer as? UIPanGestureRecognizer,
           (gestureRecognizer.value(forKey: "_targets") as? [NSObject])?.contains(where: { $0 == calendar }) == true {
            let velocity = panGesture.velocity(in: gestureRecognizer.view)
            var shouldStart = calendar.currentScope == .week ? velocity.y >= 0 : velocity.y <= 0
            if !shouldStart {
                return false
            }
            shouldStart = abs(velocity.x) <= abs(velocity.y)
            if shouldStart {
                calendar.collectionView.panGestureRecognizer.isEnabled = false
                calendar.collectionView.panGestureRecognizer.isEnabled = true
            }
            return shouldStart
        }
        return true
    }
    
    private func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return otherGestureRecognizer == calendar?.collectionView.panGestureRecognizer && calendar?.collectionView.isDecelerating == true
    }
}
