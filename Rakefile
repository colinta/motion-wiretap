# -*- coding: utf-8 -*-
$:.unshift("/Library/RubyMotion/lib")
$:.unshift("lib")
if ENV.fetch('platform', 'ios') == 'ios'
  require 'motion/project/template/ios'
elsif ENV['platform'] == 'osx'
  require 'motion/project/template/osx'
else
  raise "Unsupported platform #{ENV['platform']}"
end

require 'motion-wiretap'


Motion::Project::App.setup do |app|
  # Use `rake config' to see complete project settings.
  app.name = 'motion-wiretap'
  app.specs_dir = "spec/#{app.template}/"
end
