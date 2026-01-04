import UIKit
import SegmentedPager

@MainActor
final class ViewController: UIViewController {

    // MARK: - Model

    private struct Page {
        let title: String
        let viewController: UIViewController
        let tabLabel: UILabel
        let tabWidth: CGFloat
    }

    private let tabFont = UIFont.systemFont(ofSize: 13, weight: .regular)
    private let selectedColor: UIColor = .label
    private let unselectedColor: UIColor = .secondaryLabel

    private lazy var pages: [Page] = makePages()

    // MARK: - SegmentedPager

    private lazy var segmentedPagerVC: SegmentedPagerViewController = {
        var config = SegmentConfiguration.default
        config.tab.alignment = .fillEqually
        config.tab.padding = 10
        config.tab.leadingPadding = 10
        config.tab.trailingPadding = 10
        config.pager.defaultIndex = 0

        config.indicator.color = .red
        config.indicator.animationType = .whileScrolling
        config.indicator.animationDuration = 0.3

        let vc = SegmentedPagerViewController(configuration: config)
        vc.dataSource = self
        vc.selectionDelegate = self
        vc.transitionDelegate = self
        vc.sizingDelegate = self
        return vc
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        addChild(segmentedPagerVC)
        view.addSubview(segmentedPagerVC.view)
        segmentedPagerVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentedPagerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segmentedPagerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segmentedPagerVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            segmentedPagerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        segmentedPagerVC.didMove(toParent: self)

        segmentedPagerVC.reloadData()
        updateTabColors(selectedIndex: segmentedPagerVC.currentIndex, previousIndex: nil)
    }

    // MARK: - Setup

    private func makePages() -> [Page] {
        let count = 4

        return (0..<count).map { index in
            let title = titleForIndex(index)
            let color = pageColor(for: index)

            let vc = PageViewController(
                text: title,
                backgroundColor: color
            )

            let label = UILabel()
            label.text = title
            label.font = tabFont
            label.textAlignment = .center

            let width = (title as NSString)
                .size(withAttributes: [.font: tabFont])
                .width
                .rounded(.up) + 2

            return Page(
                title: title,
                viewController: vc,
                tabLabel: label,
                tabWidth: width
            )
        }
    }

    private func titleForIndex(_ index: Int) -> String {
        "Tab \(index + 1)"
    }
    
    private let pageColors: [UIColor] = [
        .systemRed,
        .systemBlue,
        .systemGreen,
        .systemOrange,
        .systemPurple,
        .systemTeal
    ]

    private func pageColor(for index: Int) -> UIColor {
        pageColors[index % pageColors.count]
    }

    private func updateTabColors(selectedIndex: Int, previousIndex: Int?) {
        if let prev = previousIndex, pages.indices.contains(prev) {
            pages[prev].tabLabel.textColor = unselectedColor
        }
        if pages.indices.contains(selectedIndex) {
            pages[selectedIndex].tabLabel.textColor = selectedColor
        }
    }
}

// MARK: - DataSource

extension ViewController: @MainActor SegmentedPagerViewControllerDataSource {

    func numberOfSegments(in controller: SegmentedPagerViewController) -> Int {
        pages.count
    }

    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, tabViewAt index: Int) -> UIView {
        // Initial coloring when library asks for tab view
        pages[index].tabLabel.textColor = (index == controller.currentIndex) ? selectedColor : unselectedColor
        return pages[index].tabLabel
    }

    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, viewControllerAt index: Int) -> UIViewController {
        pages[index].viewController
    }
}

// MARK: - Selection

extension ViewController: @MainActor SegmentedPagerSelectionDelegate {

    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, didSelect index: Int, from previousIndex: Int) {
        updateTabColors(selectedIndex: index, previousIndex: previousIndex)
    }
}

// MARK: - Sizing

extension ViewController: @MainActor SegmentedPagerSizingDelegate {

    func segmentedPagerViewController(_ controller: SegmentedPagerViewController, widthForTabAt index: Int) -> CGFloat {
        pages[index].tabWidth
    }
}

// MARK: - Transition (optional)

extension ViewController: @MainActor SegmentedPagerTransitionDelegate {

    func segmentedPagerViewController(
        _ controller: SegmentedPagerViewController,
        willTransitionTo index: Int,
        from fromIndex: Int,
        progress: CGFloat
    ) {
        // no-op
    }
}
