# SegmentedPager

SegmentedPager is a modern UIKit paging component for iOS 26+, written in Swift 6.

It combines a fully customizable segmented tab bar with a page-style content pager, keeping tab selection, indicator position, and swipe gestures perfectly in sync. The indicator can animate while scrolling, not just after the page transition finishes, making it suitable for polished, gesture-driven interfaces.

SegmentedPager is designed for developers who need more control than UISegmentedControl or UIPageViewController alone can provide, while still staying fully UIKit-based and compatible with modern Swift concurrency rules.

[![Version](https://img.shields.io/cocoapods/v/SegmentedPager.svg?style=flat)](https://cocoapods.org/pods/SegmentedPager)
[![License](https://img.shields.io/cocoapods/l/SegmentedPager.svg?style=flat)](https://cocoapods.org/pods/SegmentedPager)
[![Platform](https://img.shields.io/cocoapods/p/SegmentedPager.svg?style=flat)](https://cocoapods.org/pods/SegmentedPager)

## Key features

• Fully customizable tab layout (leading, centered, or equally filled)
• Page-style paging powered by UIPageViewController
• Indicator animation while scrolling or on page settle
• Dynamic tab widths based on content or fixed sizing
• Clean data source and delegate APIs
• UIKit-first design, no SwiftUI dependency
• Swift 6 and iOS 26 concurrency-safe (MainActor-correct)

## Requirements

iOS 26.0  
Swift 6.0  

## Installation

SegmentedPager is available via CocoaPods.

```ruby
pod 'SegmentedPager'
```

## Configuration overview

SegmentedPager is configured through `SegmentConfiguration`.

• `tab.alignment`  
Controls how tabs are laid out. Use `.leading` for left-aligned tabs, `.center` to center the group when it fits, or `.fillEqually` to distribute tabs evenly across the available width.

• `tab.fixedWidth`  
Forces all tabs to use the same width. When `nil`, widths are resolved from the delegate or intrinsic content size.

• `indicator.fixedWidth`  
Overrides the indicator width. When `nil`, the indicator matches the active tab width.

• `indicator.animationType`  
Controls how the indicator moves. Use `.none`, `.end` to animate after paging completes, or `.whileScrolling` to follow the swipe gesture in real time.

• `pager.defaultIndex`  
Sets the initially selected page.

## When to use SegmentedPager

Use SegmentedPager when you need a tabbed paging interface with more flexibility than UISegmentedControl.

It is a good fit when tab widths are dynamic, when the indicator should follow the swipe gesture in real time, or when paging content is backed by view controllers.

SegmentedPager keeps UIKit APIs familiar while handling layout, indicator animation, and page synchronization for you.

## Migration note

SegmentedPager is the successor to the deprecated `SegmentViewController` library.

If you are migrating from `SegmentViewController`, the overall usage pattern remains the same, with improved layout behavior, cleaner APIs, and full Swift 6 compatibility.
