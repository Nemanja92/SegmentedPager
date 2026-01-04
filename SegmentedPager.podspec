Pod::Spec.new do |s|
  s.name             = 'SegmentedPager'
  s.version          = '2.0.0'
  s.summary          = 'Segmented tabs + page-style paging controller for iOS.'

  s.description      = <<-DESC
SegmentedPager provides a segmented tab bar synced with a paged content controller.
Useful for building tabbed paging interfaces similar to many popular apps.
  DESC

  s.homepage         = 'https://github.com/Nemanja92/SegmentedPager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nemanja Ignjatović' => 'nemanja92@icloud.com' }

  s.source           = { :git => 'https://github.com/Nemanja92/SegmentedPager.git', :tag => s.version.to_s }

  s.ios.deployment_target = '26.0'
  s.swift_versions    = ['6.0']

  s.source_files      = 'SegmentedPager/Classes/**/*'

  # If you add assets later, you can enable this:
  # s.resource_bundles = {
  #   'SegmentedPager' => ['SegmentedPager/Assets/**/*']
  # }
end
