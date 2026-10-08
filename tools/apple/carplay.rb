#!/usr/bin/env ruby
# frozen_string_literal: true

# CarPlay (audio) for the iOS app. See docs/CARPLAY.md.
#
#   gem install xcodeproj
#   ruby tools/apple/carplay.rb add       # CarPlaySceneDelegate.swift in the Runner target (done, in the repo)
#   ruby tools/apple/carplay.rb status
#   ruby tools/apple/carplay.rb enable    # once Apple granted com.apple.developer.carplay-audio
#   ruby tools/apple/carplay.rb enable --multiple-scenes
#   ruby tools/apple/carplay.rb disable
#
# The scene (Info.plist) and its code are always built; CarPlay only shows
# the app when it is signed with the entitlement. `enable` copies the
# entitlement from ios/Runner/CarPlay.entitlements.disabled into
# ios/Runner/Runner.entitlements; `disable` takes it out again. Neither
# matters to the unsigned CI build (`flutter build ios --no-codesign`).
#
# --multiple-scenes also sets UIApplicationSupportsMultipleScenes to true,
# as Apple's CarPlay sample does; try it only if the CarPlay scene does not
# connect with the default (false). It lets iPad open several windows.
#
# Xcode is not needed to run it.

require 'xcodeproj'

Encoding.default_external = Encoding::UTF_8

ROOT = File.expand_path('../..', __dir__)
RUNNER = File.join(ROOT, 'ios', 'Runner')
ENTITLEMENTS = File.join(RUNNER, 'Runner.entitlements')
DISABLED = File.join(RUNNER, 'CarPlay.entitlements.disabled')
INFO = File.join(RUNNER, 'Info.plist')
SOURCE = 'CarPlaySceneDelegate.swift'

def carplay_keys
  File.read(DISABLED).scan(%r{<key>(com\.apple\.developer\.carplay-[a-z-]+)</key>}).flatten
end

def enabled_keys
  text = File.read(ENTITLEMENTS)
  carplay_keys.select { |k| text.include?("<key>#{k}</key>") }
end

def add
  project = Xcodeproj::Project.open(File.join(ROOT, 'ios', 'Runner.xcodeproj'))
  runner = project.targets.find { |t| t.name == 'Runner' } or abort 'no Runner target'
  group = project.main_group['Runner'] or abort 'no Runner group'
  ref = group.files.find { |f| f.path == SOURCE } || group.new_reference(SOURCE)
  unless runner.source_build_phase.files_references.include?(ref)
    runner.source_build_phase.add_file_reference(ref, true)
  end
  # Keep the inactive entitlement visible next to the active one.
  group.files.find { |f| f.path == File.basename(DISABLED) } ||
    group.new_reference(File.basename(DISABLED)).tap { |f| f.last_known_file_type = 'text.plist.xml' }
  project.save
  puts "Runner: #{SOURCE} compiled"
end

def enable(multiple_scenes)
  text = File.read(ENTITLEMENTS)
  missing = carplay_keys - enabled_keys
  unless missing.empty?
    lines = missing.map { |k| "\t<key>#{k}</key>\n\t<true/>\n" }.join
    text = text.sub(%r{</dict>\s*</plist>\s*\z}) { "#{lines}</dict>\n</plist>\n" }
    File.write(ENTITLEMENTS, text)
  end
  if multiple_scenes
    info = File.read(INFO)
    info = info.sub(%r{(<key>UIApplicationSupportsMultipleScenes</key>\s*)<false/>}, '\1<true/>')
    File.write(INFO, info)
  end
  status
end

def disable
  text = File.read(ENTITLEMENTS)
  carplay_keys.each do |k|
    text = text.sub(%r{[ \t]*<key>#{Regexp.escape(k)}</key>\s*<true/>\n?}, '')
  end
  File.write(ENTITLEMENTS, text)
  info = File.read(INFO)
  File.write(INFO, info.sub(%r{(<key>UIApplicationSupportsMultipleScenes</key>\s*)<true/>}, '\1<false/>'))
  status
end

def status
  keys = enabled_keys
  multi = File.read(INFO)[%r{<key>UIApplicationSupportsMultipleScenes</key>\s*<(true|false)/>}, 1]
  puts "entitlement: #{keys.empty? ? 'off' : keys.join(', ')}"
  puts "UIApplicationSupportsMultipleScenes: #{multi}"
end

case ARGV[0]
when 'add' then add
when 'enable' then enable(ARGV.include?('--multiple-scenes'))
when 'disable' then disable
when 'status' then status
else abort 'usage: carplay.rb add | status | enable [--multiple-scenes] | disable'
end
