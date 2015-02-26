# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/slack_notification/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-slack_notification"
  spec.version       = Capistrano::SlackNotification::VERSION
  spec.authors       = ["linyows"]
  spec.email         = ["linyows@gmail.com"]
  spec.summary       = %q{Notify Capistrano deployment to Slack.}
  spec.description   = %q{Notify Capistrano deployment to Slack.}
  spec.homepage      = "https://github.com/linyows/capistrano-slack_notification"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 0.9"
  spec.add_dependency "capistrano", "> 3.1"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
