//
//  FeedPushTransitionAnimator.swift
//  GXSwiftDemo
//
//  Created by Claude on 2025/12/15.
//

import UIKit

/// Push 到详情页的转场动画
class FeedPushTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    // MARK: - Constants

    private enum AnimationConfig {
        static let duration: TimeInterval = 0.25
        static let cardFadeOutDuration: TimeInterval = duration * 0.5
        static let cornerRadius: CGFloat = 16
        static let dimAlpha: CGFloat = 0.5
    }

    // MARK: - Properties

    private let originFrame: CGRect
    private weak var originCardView: UIView?

    // MARK: - Initialization

    init(originFrame: CGRect, originImageView: UIView?) {
        self.originFrame = originFrame
        self.originCardView = originImageView
        super.init()
    }

    // MARK: - UIViewControllerAnimatedTransitioning

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return AnimationConfig.duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to) as? VDDetailContainerBlocV3,
              let fromView = fromVC.view,
              let toView = toVC.view else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)
        let scaleWith = originFrame.width / finalFrame.width
        let scaleHeight = originFrame.height / finalFrame.height

        let originCenter = CGPoint(x: originFrame.midX, y: originFrame.midY)

        // 1. 添加列表视图（最底层）
        containerView.addSubview(fromView)

        // 2. 创建黑色蒙层（覆盖列表）
        let dimView = UIView(frame: fromView.bounds)
        dimView.backgroundColor = .black
        dimView.alpha = 0
        containerView.addSubview(dimView)

        // 3. 创建白色背景容器（提供白色背景和圆角）
        let clipContainer = UIView()
        clipContainer.frame = finalFrame
        clipContainer.center = originCenter
        clipContainer.transform = CGAffineTransform(scaleX: scaleWith, y: scaleHeight)
        clipContainer.backgroundColor = .white
        clipContainer.layer.cornerRadius = AnimationConfig.cornerRadius
        clipContainer.clipsToBounds = true
        containerView.addSubview(clipContainer)

        // 4. 创建卡片快照
        let cardSnapshot = originCardView?.snapshotView(afterScreenUpdates: false) ?? UIView()
        cardSnapshot.frame = originFrame
        containerView.addSubview(cardSnapshot)
        
        // 5. 设置详情页
        toView.alpha = 0.0
        clipContainer.addSubview(toView)

        // 隐藏原始卡片
        originCardView?.isHidden = true

        // 执行动画
        performScaleAnimation(
            dimView: dimView,
            clipContainer: clipContainer,
            cardSnapshot: cardSnapshot,
            detailView: toView,
            finalFrame: finalFrame
        )

        performFadeAnimations(
            cardSnapshot: cardSnapshot,
            detailView: toView
        ) {
            self.cleanupAfterTransition(
                views: [dimView, clipContainer, cardSnapshot],
                detailView: toView,
                finalFrame: finalFrame,
                transitionContext: transitionContext
            )
        }
    }

    // MARK: - Private Methods

    private func performScaleAnimation(
        dimView: UIView,
        clipContainer: UIView,
        cardSnapshot: UIView,
        detailView: UIView,
        finalFrame: CGRect
    ) {
        // 计算等比例缩放因子（基于宽度）
        let scale = finalFrame.width / originFrame.width
        let finalCenter = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
        let finalFrameHeight = finalFrame.height
        let finalCardSnapshotHeight = finalFrame.width / (originFrame.width / originFrame.height)
        
        UIView.animate(withDuration: AnimationConfig.duration) {
            dimView.alpha = AnimationConfig.dimAlpha
            
            clipContainer.transform = .identity
            clipContainer.center = finalCenter

            cardSnapshot.transform = CGAffineTransform(scaleX: scale, y: scale)
            cardSnapshot.center = CGPoint(x: finalCenter.x,
                                          y: finalCenter.y - (finalFrameHeight - finalCardSnapshotHeight) / 2.0)
        }
    }

    private func performFadeAnimations(
        cardSnapshot: UIView,
        detailView: UIView,
        completion: @escaping () -> Void
    ) {
        // 卡片淡出（前50%）
        UIView.animate(withDuration: AnimationConfig.duration * 0.5,
                       delay: AnimationConfig.duration * 0.2,
                       options: .curveEaseOut) {
            cardSnapshot.alpha = 0
        }

        // 详情页淡入（整个动画时长）
        UIView.animate(withDuration: AnimationConfig.duration,
                       delay: 0,
                       options: .curveEaseIn) {
            detailView.alpha = 1.0
        } completion: { _ in
            completion()
        }
    }

    private func cleanupAfterTransition(
        views: [UIView],
        detailView: UIView,
        finalFrame: CGRect,
        transitionContext: UIViewControllerContextTransitioning
    ) {
        let containerView = transitionContext.containerView

        // 移除临时视图
        views.forEach { $0.removeFromSuperview() }

        containerView.addSubview(detailView)
        detailView.frame = finalFrame

        // 显示原始卡片
        originCardView?.isHidden = false

        // 完成转场
        let success = !transitionContext.transitionWasCancelled
        transitionContext.completeTransition(success)
    }
}
