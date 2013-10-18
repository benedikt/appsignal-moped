# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'appsignal/moped/version'

Gem::Specification.new do |s|
  s.name          = 'appsignal-moped'
  s.version       = Appsignal::Moped::VERSION
  s.platform      = Gem::Platform::RUBY
  s.authors       = ['Steven Weller']
  s.email         = %w{steven@80beans.com}
  s.homepage      = 'https://github.com/appsignal/appsignal-moped'
  s.summary       = 'Add instrument calls to mongodb queries made with moped'\
                    '(or mongoid). For use with Appsignal.'
  s.description   = 'Log your moped queries with ActiveSupport::Notifications'\
                    '.instrument calls'
  s.files         = Dir.glob("lib/**/*") + %w(README.md)

  s.require_path  = 'lib'

  s.add_dependency 'appsignal'
  s.add_dependency 'moped', '~>1.0'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec', '~>2.12.0'
  s.add_development_dependency 'pry'
end
