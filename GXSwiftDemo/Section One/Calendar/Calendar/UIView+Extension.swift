//
//  UIView+Extension.swift
//  GXSwiftCalendar
//
//  Created by 孙广鑫 on 2025/4/24.
//

import UIKit

extension UIView {
    var fs_width: CGFloat {
        get {
            return self.frame.width
        }
        set {
            self.frame = CGRect(x: self.fs_left, y: self.fs_top, width: newValue, height: self.fs_height)
        }
    }

    var fs_height: CGFloat {
        get {
            return self.frame.height
        }
        set {
            self.frame = CGRect(x: self.fs_left, y: self.fs_top, width: self.fs_width, height: newValue)
        }
    }

    var fs_top: CGFloat {
        get {
            return self.frame.minY
        }
        set {
            self.frame = CGRect(x: self.fs_left, y: newValue, width: self.fs_width, height: self.fs_height)
        }
    }

    var fs_bottom: CGFloat {
        get {
            return self.frame.maxY
        }
        set {
            self.fs_top = newValue - self.fs_height
        }
    }

    var fs_left: CGFloat {
        get {
            return self.frame.minX
        }
        set {
            self.frame = CGRect(x: newValue, y: self.fs_top, width: self.fs_width, height: self.fs_height)
        }
    }

    var fs_right: CGFloat {
        get {
            return self.frame.maxX
        }
        set {
            self.fs_left = newValue - self.fs_width
        }
    }
}
