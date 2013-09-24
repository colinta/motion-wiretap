# -*- encoding: utf-8 -*-
require File.expand_path('../lib/motion-wiretap/version.rb', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = 'motion-wiretap'
  gem.version       = MotionWiretap::Version

  gem.authors = ['Colin T.A. Gray']
  gem.email   = ['colinta@gmail.com']
  gem.summary     = %{It's like ReactiveCocoa, but in RubyMotion}
  gem.description = <<-DESC
ReactiveCocoa is an amazing system, and RubyMotion could benefit from the
lessons learned there!

Motion-Wiretap is, essentially, a wrapper for Key-Value coding and observation.
It exposes a +Wiretap+ class that you can use as a signal, or add listeners to
it.

Extensions are provided to listen to an +Array+ of +Wiretap+ objects, and the
`UIKit`/`AppKit` classes are augmented to provide actions as events (gestures,
mouse events, value changes).
DESC

  gem.homepage    = 'https://github.com/colinta/motion-wiretap'

  gem.files        = Dir.glob('lib/**/*.rb') + ['README.md', 'motion-wiretap.gemspec']
  gem.test_files   = gem.files.grep(%r{^spec/})

  gem.require_paths = ['lib']
end