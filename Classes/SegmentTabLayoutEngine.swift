//
//  SegmentTabLayoutEngine.swift
//  SegmentedPager
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

        guard !tabViews.isEmpty else {
            scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: tab.height)
            return 0
        }

        let availableWidth = scrollView.bounds.width

        // Determine widths
        var widths: [CGFloat] = []
        widths.reserveCapacity(tabViews.count)

        switch tab.alignment {
        case .fillEqually:
            // Equal widths that fill the visible width.
            // Padding is kept, so each tab width is computed from remaining space.
            let count = CGFloat(tabViews.count)
            let totalPadding = tab.leadingPadding
                + tab.trailingPadding
                + tab.padding * max(0, count - 1)

            let remaining = max(0, availableWidth - totalPadding)
            let equalWidth = remaining / max(1, count)
            widths = Array(repeating: equalWidth, count: tabViews.count)

        case .leading, .center:
            for (i, v) in tabViews.enumerated() {
                let w = resolveTabWidth(
                    index: i,
                    tabView: v,
                    config: config,
                    widthForIndex: widthForIndex
                )
                widths.append(w)
            }
        }

        // Compute content width based on widths and padding
        let totalWidths = widths.reduce(0, +)
        let totalInterPadding = tab.padding * CGFloat(max(0, tabViews.count - 1))
        var contentWidth = tab.leadingPadding + totalWidths + totalInterPadding + tab.trailingPadding

        // For center alignment, shift the whole group if it fits
        var startX = tab.leadingPadding
        if tab.alignment == .center, contentWidth < availableWidth {
            startX = (availableWidth - (contentWidth - tab.trailingPadding - tab.leadingPadding)) / 2
            // Explanation:
            // we center the group width (totalWidths + interPadding) inside visible width,
            // then startX becomes left inset. trailingPadding is effectively symmetric.
        }

        // Layout frames
        var x = startX
        for (i, v) in tabViews.enumerated() {
            var frame = v.frame
            frame.origin.y = 0
            frame.size.height = tab.height
            frame.size.width = widths[i]
            frame.origin.x = x
            v.frame = frame

            x += widths[i]
            if i < tabViews.count - 1 {
                x += tab.padding
            }
        }

        // Content size
        if tab.alignment == .fillEqually {
            // Fill equally always fits screen, scrolling not needed
            contentWidth = availableWidth
        } else if tab.alignment == .center, contentWidth < availableWidth {
            contentWidth = availableWidth
        }

        scrollView.contentSize = CGSize(width: max(contentWidth, availableWidth), height: tab.height)
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

        let tabWidthActual = tabView.frame.width

        let width: CGFloat
        if let fixedIndicatorWidth = indicator.fixedWidth {
            width = fixedIndicatorWidth
        } else {
            width = tabWidthActual
        }

        // Center indicator under the tab if needed
        let x = tabView.frame.minX + (tabWidthActual - width) / 2

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
