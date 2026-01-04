//
//  SegmentIndicatorAnimator.swift
//  SegmentedPager
//

import UIKit

public protocol SegmentIndicatorAnimating {
    func indicatorFrame(
        baseFrame: CGRect,
        direction: SegmentScrollDirection,
        progress: CGFloat,
        metrics: SegmentTransitionMetrics
    ) -> CGRect
}

/// Default behavior matches the original:
/// - while swiping, indicator moves and stretches towards target tab.
public final class DefaultSegmentIndicatorAnimator: SegmentIndicatorAnimating {

    public init() {}

    public func indicatorFrame(
        baseFrame: CGRect,
        direction: SegmentScrollDirection,
        progress: CGFloat,
        metrics: SegmentTransitionMetrics
    ) -> CGRect {

        let p = min(max(progress, 0), 1)

        var frame = baseFrame
        var xOffset: CGFloat = 0
        var widthDelta: CGFloat = 0

        switch direction {
        case .right:
            xOffset = metrics.rightTabOffsetWidth * p
            widthDelta = metrics.rightMinusCurrentWidth * p
        case .left:
            xOffset = -metrics.leftTabOffsetWidth * p
            widthDelta = metrics.leftMinusCurrentWidth * p
        }

        frame.origin.x += xOffset
        frame.size.width += widthDelta
        return frame
    }
}
