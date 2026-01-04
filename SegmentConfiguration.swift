//
//  SegmentConfiguration.swift
//  SegmentKit
//

import UIKit

public enum TabAnimationType: Sendable {
    case none
    case whileScrolling
    case end
}

public enum SegmentTabAlignment: Sendable {
    case leading
    case center
    case fillEqually
}

public struct SegmentConfiguration: Sendable {

    public struct Tab: Sendable {
        public var height: CGFloat
        public var fixedWidth: CGFloat?
        public var padding: CGFloat
        public var leadingPadding: CGFloat
        public var trailingPadding: CGFloat
        public var alignment: SegmentTabAlignment

        public var backgroundColor: UIColor
        public var defaultFont: UIFont
        public var selectedFont: UIFont
        public var defaultTextColor: UIColor
        public var selectedTextColor: UIColor

        public init(
            height: CGFloat = 44,
            fixedWidth: CGFloat? = nil,
            padding: CGFloat = 0,
            leadingPadding: CGFloat = 0,
            trailingPadding: CGFloat = 0,
            alignment: SegmentTabAlignment = .leading,
            backgroundColor: UIColor = .clear,
            defaultFont: UIFont = .systemFont(ofSize: 12),
            selectedFont: UIFont = .systemFont(ofSize: 12),
            defaultTextColor: UIColor = .brown,
            selectedTextColor: UIColor = .brown
        ) {
            self.height = height
            self.fixedWidth = fixedWidth
            self.padding = padding
            self.leadingPadding = leadingPadding
            self.trailingPadding = trailingPadding
            self.alignment = alignment
            self.backgroundColor = backgroundColor
            self.defaultFont = defaultFont
            self.selectedFont = selectedFont
            self.defaultTextColor = defaultTextColor
            self.selectedTextColor = selectedTextColor
        }
    }

    public struct Indicator: Sendable {
        public var color: UIColor
        public var height: CGFloat
        public var fixedWidth: CGFloat?
        public var animationDuration: TimeInterval
        public var animationType: TabAnimationType

        public init(
            color: UIColor = .red,
            height: CGFloat = 2,
            fixedWidth: CGFloat? = nil,
            animationDuration: TimeInterval = 0.3,
            animationType: TabAnimationType = .none
        ) {
            self.color = color
            self.height = height
            self.fixedWidth = fixedWidth
            self.animationDuration = animationDuration
            self.animationType = animationType
        }
    }

    public struct Pager: Sendable {
        public var backgroundColor: UIColor
        public var defaultIndex: Int

        public init(
            backgroundColor: UIColor = .white,
            defaultIndex: Int = 0
        ) {
            self.backgroundColor = backgroundColor
            self.defaultIndex = defaultIndex
        }
    }

    public var containerBackgroundColor: UIColor
    public var tab: Tab
    public var indicator: Indicator
    public var pager: Pager

    public init(
        containerBackgroundColor: UIColor = .white,
        tab: Tab = .init(),
        indicator: Indicator = .init(),
        pager: Pager = .init()
    ) {
        self.containerBackgroundColor = containerBackgroundColor
        self.tab = tab
        self.indicator = indicator
        self.pager = pager
    }
}

public extension SegmentConfiguration {
    static let `default` = SegmentConfiguration()
}
