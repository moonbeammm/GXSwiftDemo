//
//  FeedNavigationTransitionDelegate.swift
//  GXSwiftDemo
//
//  Created by Claude on 2025/12/15.
//

import UIKit

class FeedNavigationTransitionDelegate: NSObject, UINavigationControllerDelegate {

    // MARK: - Properties

    // 用于转场动画的卡片信息
    var selectedCardFrame: CGRect = .zero
    weak var selectedCardImageView: UIView?

    // MARK: - UINavigationControllerDelegate

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        switch operation {
        case .push:
            // Push 到详情页
            return FeedPushTransitionAnimator(
                originFrame: selectedCardFrame,
                originImageView: selectedCardImageView
            )
        case .pop:
            // Pop 返回列表
            return FeedPopTransitionAnimator(
                destinationFrame: selectedCardFrame,
                destinationImageView: selectedCardImageView
            )
        default:
            return nil
        }
    }
}
