//
//  SegmentTabLayoutEngine.swift
//  SegmentKit
//

import UIKit

public protocol SegmentTabLayingOut {
    func layoutTabs(
        tabViews: [UIView],
        in scrollView: UIScrollView,
        config: SegmentConfiguration,
        widthForIndex: (Int) -> CGFloat
    ) -> CGFloat

    func indicatorFrame(
        for index: Int,
        tabViews: [UIView],
        in scrollView: UIScrollView,
        config: SegmentConfiguration,
        widthForIndex: (Int) -> CGFloat
    ) -> CGRect

    func transitionMetrics(
        for index: Int,
        tabViews: [UIView],
        config: SegmentConfiguration
    ) -> SegmentTransitionMetrics
}

public final class DefaultSegmentTabLayoutEngine: SegmentTabLayingOut {

    public init() {}

    public func layoutTabs(
        tabViews: [UIView],
        in scrollView: UIScrollView,
        config: SegmentConfiguration,
        widthForIndex: (Int) -> CGFloat
    ) -> CGFloat {

        let tab = config.tab

        var contentWidth: CGFloat = 0
        var previous: UIView?

        for (i, v) in tabViews.enumerated() {
            var frame = v.frame
            frame.origin.y = 0
            frame.size.height = tab.height

            let resolvedWidth = resolveTabWidth(
                index: i,
                tabView: v,
                config: config,
                widthForIndex: widthForIndex
            )
            frame.size.width = resolvedWidth

            if previous == nil {
                frame.origin.x = tab.leadingPadding
                contentWidth = tab.leadingPadding + resolvedWidth
            } else {
                frame.origin.x = (previous?.frame.maxX ?? 0) + tab.padding
                contentWidth += tab.padding + resolvedWidth
                if i == tabViews.count - 1 {
                    contentWidth += tab.trailingPadding
                }
            }

            v.frame = frame
            previous = v
        }
        
        // Center tabs if total width is smaller than visible width
        if contentWidth < scrollView.bounds.width {
            let extraLeft = (scrollView.bounds.width - contentWidth) / 2
            for v in tabViews {
                var f = v.frame
                f.origin.x += extraLeft
                v.frame = f
            }
            // contentWidth becomes full width visually
            scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: tab.height)
        } else {
            scrollView.contentSize = CGSize(width: contentWidth, height: tab.height)
        }
        return contentWidth
    }

    public func indicatorFrame(
        for index: Int,
        tabViews: [UIView],
        in scrollView: UIScrollView,
        config: SegmentConfiguration,
        widthForIndex: (Int) -> CGFloat
    ) -> CGRect {

        guard index >= 0, index < tabViews.count else { return .zero }

        let tab = config.tab
        let indicator = config.indicator

        let tabView = tabViews[index]
        let tabWidthResolved = resolveTabWidth(
            index: index,
            tabView: tabView,
            config: config,
            widthForIndex: widthForIndex
        )

        let width: CGFloat
        if let fixedIndicatorWidth = indicator.fixedWidth {
            width = fixedIndicatorWidth
        } else {
            width = tabWidthResolved
        }

        // align indicator under the tab view (centered if indicator width differs)
        let x = tabView.frame.minX + (tabWidthResolved - width) / 2

        return CGRect(
            x: x,
            y: tab.height - indicator.height,
            width: width,
            height: indicator.height
        )
    }

    public func transitionMetrics(
        for index: Int,
        tabViews: [UIView],
        config: SegmentConfiguration
    ) -> SegmentTransitionMetrics {

        guard index >= 0, index < tabViews.count else { return .init() }

        let tab = config.tab

        let current = tabViews[index]
        let prev: UIView? = index > 0 ? tabViews[index - 1] : nil
        let next: UIView? = index < tabViews.count - 1 ? tabViews[index + 1] : nil

        var m = SegmentTransitionMetrics()

        if index == 0 {
            guard let next else { return m }
            m.leftTabOffsetWidth = tab.leadingPadding
            m.rightTabOffsetWidth = next.frame.minX - current.frame.minX
            m.leftMinusCurrentWidth = 0
            m.rightMinusCurrentWidth = next.frame.width - current.frame.width
            return m
        }

        if index == tabViews.count - 1 {
            guard let prev else { return m }
            m.leftTabOffsetWidth = current.frame.minX - prev.frame.minX
            m.rightTabOffsetWidth = tab.trailingPadding
            m.leftMinusCurrentWidth = prev.frame.width - current.frame.width
            m.rightMinusCurrentWidth = 0
            return m
        }

        guard let prev, let next else { return m }
        m.leftTabOffsetWidth = current.frame.minX - prev.frame.minX
        m.rightTabOffsetWidth = next.frame.minX - current.frame.minX
        m.leftMinusCurrentWidth = prev.frame.width - current.frame.width
        m.rightMinusCurrentWidth = next.frame.width - current.frame.width
        return m
    }

    // MARK: - Helpers

    private func resolveTabWidth(
        index: Int,
        tabView: UIView,
        config: SegmentConfiguration,
        widthForIndex: (Int) -> CGFloat
    ) -> CGFloat {

        if let fixed = config.tab.fixedWidth {
            return fixed
        }

        let delegateWidth = widthForIndex(index)
        if delegateWidth > 0 {
            return delegateWidth
        }

        // fallback to intrinsic if possible
        let intrinsic = tabView.intrinsicContentSize.width
        if intrinsic > 0 && intrinsic.isFinite {
            return intrinsic
        }

        // last resort
        return 0
    }
}
