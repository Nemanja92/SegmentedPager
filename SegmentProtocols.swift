//
//  SegmentProtocols.swift
//  SegmentedPager
//

import UIKit

// MARK: - Data Source

public protocol SegmentedPagerViewControllerDataSource: AnyObject {

    /// Number of tabs / pages.
    func numberOfSegments(in controller: SegmentedPagerViewController) -> Int

    /// Tab view for a given index (title label, custom view, etc).
    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, tabViewAt index: Int) -> UIView

    /// Page content for a given index.
    ///
    /// Provide a UIViewController when possible. This keeps child containment correct.
    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, viewControllerAt index: Int) -> UIViewController
}

// MARK: - Delegate (ISP-friendly)

public protocol SegmentedPagerSelectionDelegate: AnyObject {
    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, didSelect index: Int, from previousIndex: Int)
}

public protocol SegmentedPagerTransitionDelegate: AnyObject {
    /// Called while user is swiping between pages when animationType == .whileScrolling.
    func segmentedPagerViewController(
        _ controller: SegmentedPagerViewController,
        willTransitionTo index: Int,
        from fromIndex: Int,
        progress: CGFloat
    )
}

public protocol SegmentedPagerSizingDelegate: AnyObject {
    /// Return 0 to use the tab view's intrinsicContentSize.width (or fixedWidth if configured).
    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, widthForTabAt index: Int) -> CGFloat
}

/// Convenience umbrella type for users who want one delegate object.
/// (You can still conform to just one of the smaller protocols.)
public typealias SegmentedPagerViewControllerDelegate =
    SegmentedPagerSelectionDelegate & SegmentedPagerTransitionDelegate & SegmentedPagerSizingDelegate

// MARK: - Default implementations (so users implement only what they need)

public extension SegmentedPagerTransitionDelegate {
    func segmentedPagerViewController(
        _ controller: SegmentedPagerViewController,
        willTransitionTo index: Int,
        from fromIndex: Int,
        progress: CGFloat
    ) { /* default no-op */ }
}

public extension SegmentedPagerSizingDelegate {
    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, widthForTabAt index: Int) -> CGFloat { 0 }
}
