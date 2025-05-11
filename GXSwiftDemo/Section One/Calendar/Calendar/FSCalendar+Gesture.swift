//
//  FSCalendar+Gesture.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/27.
//

import UIKit

extension FSCalendar {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc public func handleScopeGesture(_ sender: UIPanGestureRecognizer) {
        transitionCoordinator.handleScopeGesture(sender)
    }
}
