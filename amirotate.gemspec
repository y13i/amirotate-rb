# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amirotate/version'

Gem::Specification.new do |spec|
  spec.name          = "amirotate"
  spec.version       = AMIRotate::VERSION
  spec.authors       = ["y13i"]
  spec.email         = ["email@y13i.com"]

  spec.summary       = %(Back up EC2 instances by Snapshot/AMI.)
  spec.description   = %(Back up EC2 instances by Snapshot/AMI. Capable of managing backup retention period.)
  spec.homepage      = "https://github.com/y13i/amirotate"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "pry"

  spec.add_dependency "aws-sdk", ">= 2.0.40"
  spec.add_dependency "thor"
  spec.add_dependency "thor-aws"
  spec.add_dependency "io-console"
end
