//
//  FeedPopTransitionAnimator.swift
//  GXSwiftDemo
//
//  Created by Claude on 2025/12/15.
//

import UIKit

/// Pop 返回列表的转场动画
class FeedPopTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Constants

    private enum AnimationConfig {
        static let duration: TimeInterval = 0.25
        static let detailFadeOutDuration: TimeInterval = duration * 0.5
        static let cornerRadius: CGFloat = 16
    }

    // MARK: - Properties

    private let destinationFrame: CGRect
    private weak var destinationCardView: UIView?

    // MARK: - Initialization

    init(destinationFrame: CGRect, destinationImageView: UIView?) {
        self.destinationFrame = destinationFrame
        self.destinationCardView = destinationImageView
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return AnimationConfig.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? VDDetailContainerBlocV3,
              let toVC = transitionContext.viewController(forKey: .to),
              let fromView = fromVC.view,
              let toView = toVC.view else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let detailCurrentFrame = fromView.frame
        let detailCurrentCenter = CGPoint(x: fromView.frame.midX, y: fromView.frame.midY)
        let scaleWidth = destinationFrame.width / detailCurrentFrame.width
        let scaleHeight = destinationFrame.height / detailCurrentFrame.height
        let destinationCenter = CGPoint(x: destinationFrame.midX, y: destinationFrame.midY)

        // 1. 设置列表视图（最底层）
        containerView.insertSubview(toView, at: 0)

        // 2. 创建白色背景容器
        let clipContainer = UIView()
        clipContainer.frame = destinationFrame
        clipContainer.center = detailCurrentCenter
        clipContainer.transform = CGAffineTransform(scaleX: 1.0/scaleWidth, y: 1.0/scaleHeight)
        clipContainer.backgroundColor = .white
        clipContainer.layer.cornerRadius = AnimationConfig.cornerRadius
        clipContainer.clipsToBounds = true
        containerView.addSubview(clipContainer)

        // 3. 创建卡片快照（直接添加到containerView）
        let cardSnapshot = destinationCardView?.snapshotView(afterScreenUpdates: false) ?? UIView()
        cardSnapshot.frame = destinationFrame
        cardSnapshot.center = detailCurrentCenter
        let initialScale = detailCurrentFrame.width / destinationFrame.width
        cardSnapshot.transform = CGAffineTransform(scaleX: initialScale, y: initialScale)
        cardSnapshot.alpha = 0
        cardSnapshot.backgroundColor = .systemGray5
        cardSnapshot.layer.cornerRadius = AnimationConfig.cornerRadius
        cardSnapshot.clipsToBounds = true
        containerView.addSubview(cardSnapshot)

        // 4. 设置详情页（直接添加到containerView）
        fromView.frame = detailCurrentFrame
        fromView.layer.cornerRadius = AnimationConfig.cornerRadius
        fromView.clipsToBounds = true
        containerView.addSubview(fromView)

        // 隐藏原始元素
        fromVC.playerVC.view.isHidden = true
        destinationCardView?.isHidden = true

        // 执行动画
        performScaleAnimation(
            clipContainer: clipContainer,
            cardSnapshot: cardSnapshot,
            detailView: fromView,
            destinationCenter: destinationCenter
        )

        performFadeAnimations(
            detailView: fromView,
            cardSnapshot: cardSnapshot
        ) {
            self.cleanupAfterTransition(
                views: [clipContainer, cardSnapshot, fromView],
                transitionContext: transitionContext
            )
        }
    }

    // MARK: - Private Methods

    private func performScaleAnimation(
        clipContainer: UIView,
        cardSnapshot: UIView,
        detailView: UIView,
        destinationCenter: CGPoint
    ) {
        UIView.animate(withDuration: AnimationConfig.duration) {
            // clipContainer缩小到目标位置
            clipContainer.transform = .identity
            clipContainer.center = destinationCenter

            // cardSnapshot缩小到原始大小（identity）
            cardSnapshot.transform = .identity
            cardSnapshot.center = destinationCenter

            // detailView缩小到卡片大小
            let scaleWidth = self.destinationFrame.width / detailView.bounds.width
            let scaleHeight = self.destinationFrame.height / detailView.bounds.height
            detailView.transform = CGAffineTransform(scaleX: scaleWidth, y: scaleHeight)
            detailView.center = destinationCenter
        }
    }

    private func performFadeAnimations(
        detailView: UIView,
        cardSnapshot: UIView,
        completion: @escaping () -> Void
    ) {
        // 详情页淡出（前50%）
        UIView.animate(withDuration: AnimationConfig.detailFadeOutDuration) {
            detailView.alpha = 0
        }

        // 卡片淡入（整个动画时长）
        UIView.animate(withDuration: AnimationConfig.duration) {
            cardSnapshot.alpha = 1
        } completion: { _ in
            completion()
        }
    }

    private func cleanupAfterTransition(
        views: [UIView],
        transitionContext: UIViewControllerContextTransitioning
    ) {
        // 移除临时视图
        views.forEach { $0.removeFromSuperview() }

        // 显示原始卡片
        destinationCardView?.isHidden = false

        // 完成转场
        let success = !transitionContext.transitionWasCancelled
        transitionContext.completeTransition(success)
    }
}
