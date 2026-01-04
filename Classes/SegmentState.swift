//
//  SegmentState.swift
//  SegmentedPager
//

import Foundation
import CoreGraphics
import UIKit

public enum SegmentScrollDirection: Sendable {
    case left
    case right
}

public struct SegmentTransitionMetrics: Sendable {
    public var leftTabOffsetWidth: CGFloat
    public var rightTabOffsetWidth: CGFloat
    public var leftMinusCurrentWidth: CGFloat
    public var rightMinusCurrentWidth: CGFloat

    public init(
        leftTabOffsetWidth: CGFloat = 0,
        rightTabOffsetWidth: CGFloat = 0,
        leftMinusCurrentWidth: CGFloat = 0,
        rightMinusCurrentWidth: CGFloat = 0
    ) {
        self.leftTabOffsetWidth = leftTabOffsetWidth
        self.rightTabOffsetWidth = rightTabOffsetWidth
        self.leftMinusCurrentWidth = leftMinusCurrentWidth
        self.rightMinusCurrentWidth = rightMinusCurrentWidth
    }
}

public struct SegmentState: Sendable {

    public private(set) var currentIndex: Int
    public private(set) var needsReload: Bool
    public var enableWhileScrollingAnimation: Bool

    public var metrics: SegmentTransitionMetrics

    public init(
        currentIndex: Int = 0,
        needsReload: Bool = true,
        enableWhileScrollingAnimation: Bool = true,
        metrics: SegmentTransitionMetrics = .init()
    ) {
        self.currentIndex = currentIndex
        self.needsReload = needsReload
        self.enableWhileScrollingAnimation = enableWhileScrollingAnimation
        self.metrics = metrics
    }

    public mutating func markNeedsReload() {
        needsReload = true
    }

    public mutating func markReloaded() {
        needsReload = false
    }

    public mutating func setCurrentIndex(_ index: Int) {
        currentIndex = index
    }

    public mutating func setWhileScrollingEnabled(_ enabled: Bool) {
        enableWhileScrollingAnimation = enabled
    }
}

public extension SegmentState {

    /// Computes progress (0..1) based on the internal UIPageViewController scroll view.
    static func progress(scrollView: UIScrollView) -> CGFloat {
        guard scrollView.frame.width > 0 else { return 0 }
        // UIPageViewController's internal scroll view usually has current page centered at width.
        let raw = abs((scrollView.contentOffset.x - scrollView.frame.width) / scrollView.frame.width)
        return min(max(raw, 0), 1)
    }

    /// Determines direction based on contentOffset relative to "center page".
    static func direction(scrollView: UIScrollView) -> SegmentScrollDirection {
        (scrollView.contentOffset.x - scrollView.frame.width) > 0 ? .right : .left
    }
}
