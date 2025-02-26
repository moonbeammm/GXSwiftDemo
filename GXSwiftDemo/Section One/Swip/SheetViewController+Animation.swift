//
//  SheetViewController+Animation.swift
//  GXSwiftDemo
//
//  Created by sgx on 2024/5/9.
//

import UIKit

extension SheetViewController {
    public func dismiss(withDuration: CGFloat) {
        UIView.animate(
            withDuration: withDuration,
            delay: 0,
            usingSpringWithDamping: self.options.transitionDampening,
            initialSpringVelocity: self.options.transitionVelocity,
            options: self.options.transitionAnimationOptions,
            animations: {[weak self] in
                self?.contentViewController.view.transform = CGAffineTransform(translationX: 0, y: self?.contentViewController.view.bounds.height ?? 0)
                self?.view.backgroundColor = UIColor.clear
                self?.maskView.alpha = 0
            }, completion: {[weak self] complete in
                self?.dismiss(animated: false)
                
            })
    }
    
    public func dismiss(animated: Bool) {
        willDismiss()
        if animated {
            self.animateOut { [weak self] in
                self?.didDismiss()
            }
        } else {
            self.view.removeFromSuperview()
            self.removeFromParent()
            self.didDismiss()
        }
    }
    
    public func animateIn(toView: UIView, inParentVC: UIViewController, size: SheetSize? = nil, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        willShow()
        
        self.willMove(toParent: inParentVC)
        inParentVC.addChild(self)
        toView.addSubview(self.view)
        self.didMove(toParent: inParentVC)
        
        self.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.view.topAnchor.constraint(equalTo: toView.topAnchor),
            self.view.bottomAnchor.constraint(equalTo: toView.bottomAnchor),
            self.view.leadingAnchor.constraint(equalTo: toView.leadingAnchor),
            self.view.trailingAnchor.constraint(equalTo: toView.trailingAnchor)
        ])
        self.animateIn(size: size, duration: duration, completion: completion)
    }
    
    public func animateIn(size: SheetSize? = nil, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        guard self.view.superview != nil, let contentView = self.contentViewController.view else {
            assert(false, "self.view.superview cant be nil!")
            return
        }
        self.view.superview?.layoutIfNeeded()
        self.contentViewController.updatePreferredHeight()
        self.resize(to: size ?? self.sizes.first ?? self.currentSize, animated: false)
        contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
        self.maskView.alpha = 0
        self.updateOrderedSizes()
        
        UIView.animate(
            withDuration: duration,
            animations: { [weak self] in
                contentView.transform = .identity
                self?.maskView.alpha = 1
            },
            completion: {[weak self] _ in
                completion?()
                self?.didShow()
            }
        )
    }
    
    public func animateOut(duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        guard let contentView = self.contentViewController.view else {
            assert(false, "self.contentViewController.view cant be nil!")
            return
        }
        UIView.animate(
            withDuration: duration,
            delay: 0,
            usingSpringWithDamping: self.options.transitionDampening,
            initialSpringVelocity: self.options.transitionVelocity,
            options: self.options.transitionAnimationOptions,
            animations: {[weak self] in
                contentView.transform = CGAffineTransform(translationX: 0, y: contentView.bounds.height)
                self?.maskView.alpha = 0
            },
            completion: {[weak self] _ in
                self?.view.removeFromSuperview()
                self?.removeFromParent()
                completion?()
            }
        )
    }
    
    public func updateHeight(withDuration: CGFloat, newHeight: CGFloat, complete: (() -> Void)? = nil) {
        startFrameAnimation()
        UIView.animate(
            withDuration: withDuration,
            delay: 0,
            usingSpringWithDamping: self.options.transitionDampening,
            initialSpringVelocity: self.options.transitionVelocity,
            options: self.options.transitionAnimationOptions,
            animations: {[weak self] in
                self?.contentViewController.view.transform = CGAffineTransform.identity
                self?.contentViewHeightConstraint?.constant = newHeight
                self?.maskView.alpha = 1
                self?.view.layoutIfNeeded()
            }, completion: {[weak self] _ in
                complete?()
                self?.stopFrameAnimation()
            })
    }
}
