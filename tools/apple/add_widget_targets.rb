#!/usr/bin/env ruby
# frozen_string_literal: true

# Adds the two WidgetKit extensions (the khatma widget and the actions
# widget) to the Flutter Runner project of one platform, from the sources in
# apple/. Run once per platform; running it again does nothing.
#
#   gem install xcodeproj
#   ruby tools/apple/add_widget_targets.rb ios
#   ruby tools/apple/add_widget_targets.rb macos
#
# Xcode is not needed to run it (CI builds both platforms to check it).

require 'xcodeproj'

# The project file holds the Arabic display names.
Encoding.default_external = Encoding::UTF_8

platform = ARGV[0]
abort 'usage: add_widget_targets.rb ios|macos' unless %w[ios macos].include?(platform)
ios = platform == 'ios'

root = File.expand_path('../..', __dir__)
project = Xcodeproj::Project.open(File.join(root, platform, 'Runner.xcodeproj'))
runner = project.targets.find { |t| t.name == 'Runner' } or abort 'no Runner target'

EXTENSIONS = {
  'TibyanWidget' => 'الختمة',
  'TibyanActions' => 'تبيان: اختصارات'
}.freeze
BUNDLE_BASE = 'app.tibyan.tibyan'
DEPLOYMENT = ios ? '17.0' : '14.0'

apple = project.main_group['Apple'] || project.main_group.new_group('Apple', '../apple')
shared = apple['Shared'] || apple.new_group('Shared', 'Shared')
store = shared.files.find { |f| f.path == 'WidgetStore.swift' } || shared.new_reference('WidgetStore.swift')
xcconfig = apple.files.find { |f| f.path == "Widget-#{platform}.xcconfig" } ||
           apple.new_reference("Widget-#{platform}.xcconfig")
apple.files.find { |f| f.path == "Widget-#{platform}.entitlements" } ||
  apple.new_reference("Widget-#{platform}.entitlements")
apple.files.find { |f| f.path == 'Extension-Info.plist' } || apple.new_reference('Extension-Info.plist')

embed = runner.copy_files_build_phases.find { |p| p.name == 'Embed Foundation Extensions' } ||
        runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins

EXTENSIONS.each do |name, display|
  next if project.targets.any? { |t| t.name == name }

  target = project.new_target(:app_extension, name, ios ? :ios : :osx, DEPLOYMENT, nil, :swift)
  group = apple.new_group(name, name)
  source = group.new_reference("#{name}.swift")
  target.add_file_references([source, store])
  target.add_system_framework(%w[WidgetKit SwiftUI AppIntents])

  target.build_configurations.each do |config|
    s = config.build_settings
    config.base_configuration_reference = xcconfig
    s['PRODUCT_BUNDLE_IDENTIFIER'] = "#{BUNDLE_BASE}.#{name}"
    s['PRODUCT_NAME'] = '$(TARGET_NAME)'
    s['INFOPLIST_FILE'] = '../apple/Extension-Info.plist'
    s['GENERATE_INFOPLIST_FILE'] = 'NO'
    s['CODE_SIGN_ENTITLEMENTS'] = "../apple/Widget-#{platform}.entitlements"
    s['CODE_SIGN_STYLE'] = 'Automatic'
    s['TIBYAN_WIDGET_NAME'] = display
    s['SWIFT_VERSION'] = '5.0'
    s['SKIP_INSTALL'] = 'YES'
    s['APPLICATION_EXTENSION_API_ONLY'] = 'YES'
    s['CURRENT_PROJECT_VERSION'] = '1'
    s['LD_RUNPATH_SEARCH_PATHS'] = [
      '$(inherited)',
      ios ? '@executable_path/Frameworks' : '@executable_path/../Frameworks',
      '@executable_path/../../Frameworks'
    ]
    if ios
      s['SDKROOT'] = 'iphoneos'
      s['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT
      s['TARGETED_DEVICE_FAMILY'] = '1,2'
    else
      s['SDKROOT'] = 'macosx'
      s['MACOSX_DEPLOYMENT_TARGET'] = DEPLOYMENT
      s['CODE_SIGN_IDENTITY'] = '-'
    end
  end

  runner.add_dependency(target)
  file = embed.add_file_reference(target.product_reference, true)
  file.settings = { 'ATTRIBUTES' => %w[RemoveHeadersOnCopy] }
end

# Flutter's "Thin Binary" script must run after the extensions are embedded,
# or Xcode reports a build cycle.
thin = runner.build_phases.find { |p| p.respond_to?(:name) && p.name == 'Thin Binary' }
if thin && runner.build_phases.index(embed) > runner.build_phases.index(thin)
  runner.build_phases.delete(embed)
  runner.build_phases.insert(runner.build_phases.index(thin), embed)
end

if ios
  # The app joins the same App Group.
  ref = project.main_group['Runner']&.files&.find { |f| f.path == 'Runner.entitlements' } ||
        project.main_group['Runner']&.new_reference('Runner.entitlements')
  runner.build_configurations.each do |c|
    c.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  end
  warn 'Runner.entitlements not added to the Runner group' unless ref
end

project.save
puts "#{platform}: #{project.targets.map(&:name).join(', ')}"
