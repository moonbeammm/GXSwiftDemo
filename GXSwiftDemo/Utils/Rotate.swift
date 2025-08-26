//
//  Rotate.swift
//  GXSwiftDemo
//
//  Created by 孙广鑫 on 2025/7/29.
//

import Foundation
import UIKit

class BFCRotate {
    
    class func bfc_rotateToLandscape() {
        visableVC.bfc_rotateToLandscape()
    }
    
    class func bfc_rotateToPortrait() {
        visableVC.bfc_rotateToPortrait()
    }
    
    class func bfc_rotateToOrientation(_ orientation: UIInterfaceOrientation, forceRotate: Bool) {
        visableVC.bfc_rotateToOrientation(orientation, forceRotate: forceRotate)
    }
    
    private class func visableVC(fromVC: UIViewController) -> UIViewController {
        if let navVC = fromVC as? UINavigationController {
            return visableVC(fromVC: navVC.visibleViewController ?? navVC)
        } else if let tabVC = fromVC as? UITabBarController {
            return visableVC(fromVC: tabVC.selectedViewController ?? tabVC)
        } else {
            if let presentedVC = fromVC.presentedViewController {
                return visableVC(fromVC: presentedVC)
            } else {
                return fromVC
            }
        }
    }
    
    class var visableVC: UIViewController {
        guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
            fatalError("No root view controller found")
        }
        return visableVC(fromVC: rootVC)
    }
    
    class func bfc_lockOrientation() {
        // 实现锁定方向逻辑
    }
    
    class func bfc_unlockOrientation() {
        // 实现解锁方向逻辑
    }
}

class BFCRotateDeviceManager {
    static let shared = BFCRotateDeviceManager()
    
    private var hashTable = NSHashTable<UIViewController>.weakObjects()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(_bfc_orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    func addObserver(_ vc: UIViewController) {
        if hashTable.contains(vc) { return }
        hashTable.add(vc)
    }
    
    func removeObserver(_ vc: UIViewController) {
        hashTable.remove(vc)
    }
    
    @objc private func _bfc_orientationDidChange() {
        for obj in hashTable.allObjects {
            if obj.responds(to: #selector(UIViewController._bfc_orientationDidChange)) {
                obj.perform(#selector(UIViewController._bfc_orientationDidChange))
            }
        }
    }
}

extension UIViewController {
    private struct AssociatedKeys {
        static var forceRotate = "bfc_forceRotate"
        static var forceOrientation = "bfc_forceOrientation"
        static var rotating = "bfc_rotating"
        static var fixGravity = "bfc_fixGravity"
    }
    
    var bfc_forceRotate: Bool {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.forceRotate) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.forceRotate, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var bfc_forceOrientation: UIInterfaceOrientationMask {
        get {
            return UIInterfaceOrientationMask(rawValue: (objc_getAssociatedObject(self, &AssociatedKeys.forceOrientation) as? UInt) ?? UIInterfaceOrientationMask.all.rawValue)
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.forceOrientation, newValue.rawValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var bfc_rotating: Bool {
        get {
            return (objc_getAssociatedObject(self, &AssociatedKeys.rotating) as? Bool) ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.rotating, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var bfc_fixGravity: Bool {
        get {
            if let fixGravity = objc_getAssociatedObject(self, &AssociatedKeys.fixGravity) as? Bool {
                return fixGravity
            } else {
                let hit: Bool = true
                objc_setAssociatedObject(self, &AssociatedKeys.fixGravity, hit, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return hit
            }
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.fixGravity, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - Public Methods
    
    var bfc_currentOrientation: UIInterfaceOrientation {
        if #available(iOS 13.0, *) {
            for scene in UIApplication.shared.connectedScenes {
                if let windowScene = scene as? UIWindowScene,
                   windowScene.activationState == .foregroundActive {
                    return windowScene.interfaceOrientation
                }
            }
        }
        return UIApplication.shared.statusBarOrientation
    }
    
    func bfc_openGravity() {
        if bfc_forceRotate { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            if self.bfc_fixGravity {
                self.bfc_rotateToOrientation(self.bfc_currentOrientation, forceRotate: true)
            }
        }
    }
    
    func bfc_rotateToLandscape() {
        let orientation: UIInterfaceOrientation = UIDevice.current.orientation == .landscapeRight ? .landscapeLeft : .landscapeRight
        bfc_rotateToOrientation(orientation, forceRotate: true)
    }
    
    func bfc_rotateToPortrait() {
        bfc_rotateToOrientation(.portrait, forceRotate: true)
    }
    
    func bfc_rotateToOrientation(_ orientation: UIInterfaceOrientation, forceRotate: Bool) {
        assert(Thread.isMainThread, "Method must be invoked in main thread")
        
        if bfc_rotating { return }
        if !isViewLoaded { return }
        if view.window == nil { return }
        
        let orientations = UIInterfaceOrientationMask(rawValue: 1 << orientation.rawValue)
        
        if bfc_fixGravity {
            bfc_forceOrientation = orientations
            bfc_forceRotate = forceRotate
            if !shouldAutorotate { return }
            
            if !supportedInterfaceOrientations.contains(orientations) { return }
        }
        
        print("\(#function) \(orientation.rawValue) \(forceRotate)")
        bfc_rotating = true
        
        var canResponse = false
        
        if #available(iOS 16.0, *) {
            // Fix 16+ effect of YYTextEffectWindow
            UIApplication.shared.windows.forEach { window in
                if let YYTextEffectWindow = NSClassFromString("YYTextEffectWindow"), window.isKind(of: YYTextEffectWindow) {
                    window.isHidden = true
                }
            }
            
            if responds(to: #selector(setNeedsUpdateOfSupportedInterfaceOrientations)) {
                setNeedsUpdateOfSupportedInterfaceOrientations()
                let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: orientations)
                view.window?.windowScene?.requestGeometryUpdate(preferences) { error in
                    print("\(#function) \(String(describing: error))")
                }
                canResponse = true
            }
        }
        
        if !canResponse {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
        }
        
        // Fix gravity
        if bfc_fixGravity {
            BFCRotateDeviceManager.shared.addObserver(self)
        } else {
            bfc_forceRotate = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.bfc_rotating = false
        }
    }
    
    @objc func _bfc_orientationDidChange() {
        if bfc_rotating { return }
        if !isViewLoaded { return }
        if view.window == nil { return }
        
        let orientation = UIDevice.current.orientation
        if !orientation.isValidInterfaceOrientation { return }
        if orientation == .portraitUpsideDown { return }
        if UIInterfaceOrientation(rawValue: orientation.rawValue) == bfc_currentOrientation { return }
        
        bfc_forceRotate = false
        
        // Fix gravity
        if bfc_fixGravity {
            if shouldAutorotate && supportedInterfaceOrientations.contains(UIInterfaceOrientationMask(rawValue: 1 << orientation.rawValue)), let t = UIInterfaceOrientation(rawValue: orientation.rawValue) {
                bfc_rotateToOrientation(t, forceRotate: true)
            } else {
                bfc_forceRotate = true
            }
        }
    }
}
