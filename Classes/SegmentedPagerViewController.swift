//
//  SegmentedPagerViewController.swift
//  SegmentedPager
//

import UIKit

@MainActor
open class SegmentedPagerViewController: UIViewController {

    // MARK: - Public API

    public weak var dataSource: SegmentedPagerViewControllerDataSource?

    public weak var selectionDelegate: SegmentedPagerSelectionDelegate?
    public weak var transitionDelegate: SegmentedPagerTransitionDelegate?
    public weak var sizingDelegate: SegmentedPagerSizingDelegate?

    public var currentIndex: Int {
        state.currentIndex
    }

    public func reloadData() {
        state.markNeedsReload()
        if isViewLoaded {
            view.setNeedsLayout()
        }
    }

    public func select(index: Int, animated: Bool = true) {
        guard index >= 0, index < contentViewControllers.count else { return }
        selectInternal(index: index, animated: animated)
    }

    // MARK: - Dependencies (DIP)

    private let configuration: SegmentConfiguration
    private let layoutEngine: SegmentTabLayingOut
    private let indicatorAnimator: SegmentIndicatorAnimating

    // MARK: - State

    private var state = SegmentState()

    // MARK: - UI

    private let tabScrollView = UIScrollView()
    private let indicatorView = UIView()

    private let pageViewController: UIPageViewController = {
        UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
    }()

    private var tabViews: [UIView] = []
    private var contentViewControllers: [UIViewController] = []

    private var isPagerDragging = false
    private var pendingIndicatorLock = false

    private var dragBaseIndicatorFrame: CGRect = .zero
    private var dragMetrics = SegmentTransitionMetrics()

    // MARK: - Init

    public init(
        configuration: SegmentConfiguration = .default,
        layoutEngine: SegmentTabLayingOut = DefaultSegmentTabLayoutEngine(),
        indicatorAnimator: SegmentIndicatorAnimating = DefaultSegmentIndicatorAnimator()
    ) {
        self.configuration = configuration
        self.layoutEngine = layoutEngine
        self.indicatorAnimator = indicatorAnimator
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        self.configuration = .default
        self.layoutEngine = DefaultSegmentTabLayoutEngine()
        self.indicatorAnimator = DefaultSegmentIndicatorAnimator()
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    open override func loadView() {
        view = UIView()
        view.backgroundColor = configuration.containerBackgroundColor

        setupTabScrollView()
        setupPageViewController()
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        layoutContainers()

        if state.needsReload {
            performReload()
        }

        updateIndicatorPosition(animated: false)
    }

    // MARK: - Setup

    private func setupTabScrollView() {
        tabScrollView.backgroundColor = configuration.tab.backgroundColor
        tabScrollView.showsHorizontalScrollIndicator = false
        tabScrollView.showsVerticalScrollIndicator = false
        tabScrollView.scrollsToTop = false
        tabScrollView.bounces = false

        view.addSubview(tabScrollView)
        tabScrollView.addSubview(indicatorView)

        indicatorView.backgroundColor = configuration.indicator.color
    }

    private func setupPageViewController() {
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)

        pageViewController.dataSource = self
        pageViewController.delegate = self

        for subview in pageViewController.view.subviews {
            if let scrollView = subview as? UIScrollView {
                scrollView.delegate = self
            }
        }

        pageViewController.view.backgroundColor = configuration.pager.backgroundColor
    }

    private func layoutContainers() {
        let safe = view.safeAreaInsets
        let tabHeight = configuration.tab.height

        tabScrollView.frame = CGRect(
            x: 0,
            y: safe.top,
            width: view.bounds.width,
            height: tabHeight
        )

        pageViewController.view.frame = CGRect(
            x: 0,
            y: safe.top + tabHeight,
            width: view.bounds.width,
            height: view.bounds.height - safe.top - safe.bottom - tabHeight
        )
    }

    // MARK: - Reload

    private func performReload() {
        guard let dataSource else {
            assertionFailure("SegmentedPagerViewController requires a dataSource")
            state.markReloaded()
            return
        }

        tabViews.forEach { $0.removeFromSuperview() }
        tabViews.removeAll()
        contentViewControllers.removeAll()

        let count = dataSource.numberOfSegments(in: self)
        guard count > 0 else {
            state.markReloaded()
            return
        }

        for index in 0..<count {
            let tabView = dataSource.segmentedPagerViewController(self, tabViewAt: index)
            tabView.tag = index
            tabView.isUserInteractionEnabled = true
            tabView.addGestureRecognizer(
                UITapGestureRecognizer(
                    target: self,
                    action: #selector(handleTabTap(_:))
                )
            )

            tabScrollView.addSubview(tabView)
            tabViews.append(tabView)

            let vc = dataSource.segmentedPagerViewController(self, viewControllerAt: index)
            contentViewControllers.append(vc)
        }

        _ = layoutEngine.layoutTabs(
            tabViews: tabViews,
            in: tabScrollView,
            config: configuration,
            widthForIndex: { [weak self] idx in
                guard let self else { return 0 }
                return self.sizingDelegate?.segmentedPagerViewController(self, widthForTabAt: idx) ?? 0
            }
        )

        state.setCurrentIndex(min(configuration.pager.defaultIndex, count - 1))
        state.metrics = layoutEngine.transitionMetrics(
            for: state.currentIndex,
            tabViews: tabViews,
            config: configuration
        )

        pageViewController.setViewControllers(
            [contentViewControllers[state.currentIndex]],
            direction: .forward,
            animated: false,
            completion: nil
        )

        state.markReloaded()
    }

    // MARK: - Selection

    @objc
    private func handleTabTap(_ recognizer: UITapGestureRecognizer) {
        guard let view = recognizer.view else { return }
        select(index: view.tag, animated: true)
    }

    private func selectInternal(index: Int, animated: Bool) {
        let previous = state.currentIndex
        guard index != previous else { return }

        let direction: UIPageViewController.NavigationDirection =
            index > previous ? .forward : .reverse

        pageViewController.setViewControllers(
            [contentViewControllers[index]],
            direction: direction,
            animated: animated,
            completion: nil
        )

        state.setCurrentIndex(index)
        state.metrics = layoutEngine.transitionMetrics(
            for: index,
            tabViews: tabViews,
            config: configuration
        )

        updateIndicatorPosition(animated: animated)

        selectionDelegate?.segmentedPagerViewController(self, didSelect: index, from: previous)
    }

    private func updateIndicatorPosition(animated: Bool) {
        let frame = layoutEngine.indicatorFrame(
            for: state.currentIndex,
            tabViews: tabViews,
            in: tabScrollView,
            config: configuration,
            widthForIndex: { [weak self] idx in
                guard let self else { return 0 }
                return self.sizingDelegate?.segmentedPagerViewController(self, widthForTabAt: idx) ?? 0
            }
        )

        if animated && configuration.indicator.animationDuration > 0 {
            UIView.animate(withDuration: configuration.indicator.animationDuration) {
                self.indicatorView.frame = frame
            }
        } else {
            indicatorView.frame = frame
        }

        // Avoid tab bar scrolling while user is actively swiping pages
        if !isPagerDragging {
            centerTab(at: state.currentIndex)
        }
    }

    private func centerTab(at index: Int) {
        guard index >= 0, index < tabViews.count else { return }

        let tab = tabViews[index]
        var rect = tab.frame
        rect.origin.x = max(0, rect.midX - tabScrollView.bounds.width / 2)
        rect.size.width = tabScrollView.bounds.width

        tabScrollView.scrollRectToVisible(rect, animated: true)
    }

    private func lockIndicatorToResolvedPage(animated: Bool) {
        guard
            let visibleVC = pageViewController.viewControllers?.first,
            let resolvedIndex = contentViewControllers.firstIndex(of: visibleVC)
        else {
            // fallback to state index if something is off
            updateIndicatorPosition(animated: animated)
            return
        }

        // Update state to what page VC actually shows
        let previous = state.currentIndex
        state.setCurrentIndex(resolvedIndex)
        state.metrics = layoutEngine.transitionMetrics(
            for: resolvedIndex,
            tabViews: tabViews,
            config: configuration
        )

        updateIndicatorPosition(animated: animated)

        // Optional: only notify if changed (usually already handled in didFinishAnimating)
        if resolvedIndex != previous {
            selectionDelegate?.segmentedPagerViewController(self, didSelect: resolvedIndex, from: previous)
        }
    }
}

// MARK: - UIPageViewController

extension SegmentedPagerViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard
            let index = contentViewControllers.firstIndex(of: viewController),
            index > 0
        else { return nil }
        return contentViewControllers[index - 1]
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard
            let index = contentViewControllers.firstIndex(of: viewController),
            index < contentViewControllers.count - 1
        else { return nil }
        return contentViewControllers[index + 1]
    }

    public func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard
            completed,
            let current = pageViewController.viewControllers?.first,
            let index = contentViewControllers.firstIndex(of: current),
            let prev = previousViewControllers.first,
            let prevIndex = contentViewControllers.firstIndex(of: prev)
        else { return }

        state.setCurrentIndex(index)
        state.metrics = layoutEngine.transitionMetrics(
            for: index,
            tabViews: tabViews,
            config: configuration
        )

        updateIndicatorPosition(animated: true)
        selectionDelegate?.segmentedPagerViewController(self, didSelect: index, from: prevIndex)

        // Final authority: page transition completed => lock indicator exactly to final page
        if configuration.indicator.animationType == .whileScrolling {
            isPagerDragging = false
            state.setWhileScrollingEnabled(false)

            // Even if scroll delegates didn't fire as expected, ensure correct indicator
            pendingIndicatorLock = false
            lockIndicatorToResolvedPage(animated: true)
        }
    }
}

// MARK: - Scroll (indicator while scrolling)

extension SegmentedPagerViewController: UIScrollViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard configuration.indicator.animationType == .whileScrolling else { return }

        isPagerDragging = true
        pendingIndicatorLock = true
        state.setWhileScrollingEnabled(true)

        // Snapshot once for smooth animation
        dragBaseIndicatorFrame = layoutEngine.indicatorFrame(
            for: state.currentIndex,
            tabViews: tabViews,
            in: tabScrollView,
            config: configuration,
            widthForIndex: { [weak self] idx in
                guard let self else { return 0 }
                return self.sizingDelegate?.segmentedPagerViewController(self, widthForTabAt: idx) ?? 0
            }
        )
        dragMetrics = state.metrics
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard
            configuration.indicator.animationType == .whileScrolling,
            isPagerDragging,
            state.enableWhileScrollingAnimation
        else { return }

        let progress = SegmentState.progress(scrollView: scrollView)
        let direction = SegmentState.direction(scrollView: scrollView)

        indicatorView.frame = indicatorAnimator.indicatorFrame(
            baseFrame: dragBaseIndicatorFrame,
            direction: direction,
            progress: progress,
            metrics: dragMetrics
        )

        let targetIndex: Int = {
            switch direction {
            case .right: return min(state.currentIndex + 1, tabViews.count - 1)
            case .left: return max(state.currentIndex - 1, 0)
            }
        }()

        transitionDelegate?.segmentedPagerViewController(
            self,
            willTransitionTo: targetIndex,
            from: state.currentIndex,
            progress: progress
        )
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard configuration.indicator.animationType == .whileScrolling else { return }

        if !decelerate {
            // No deceleration => transition resolves immediately.
            isPagerDragging = false
            state.setWhileScrollingEnabled(false)

            // Lock indicator to whatever page is visible now
            if pendingIndicatorLock {
                pendingIndicatorLock = false
                lockIndicatorToResolvedPage(animated: true)
            }
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard configuration.indicator.animationType == .whileScrolling else { return }

        // Deceleration finished => page should be resolved.
        isPagerDragging = false
        state.setWhileScrollingEnabled(false)

        if pendingIndicatorLock {
            pendingIndicatorLock = false
            lockIndicatorToResolvedPage(animated: true)
        }
    }
}
