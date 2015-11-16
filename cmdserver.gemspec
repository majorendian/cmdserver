# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cmdserver/version'

Gem::Specification.new do |spec|
  spec.name          = "cmdserver"
  spec.version       = Cmdserver::VERSION
  spec.authors       = ["Ernest Deák"]
  spec.email         = ["gordon.zar@gmail.com"]

  spec.summary       = %q{Simple, module based command execution server over tcp.}
  spec.description   = %q{
    `cmdserver' is a simple, multi-threaded, module based and extensible command server with a straight forward API.
    Much of the functionality relies on ruby's ability to override module definitions at runtime. This, in turn
    becomes the servers protocol. Read the documentation further details.

    Gem includes a binary with a simple template file for getting started with writting protocol extension modules.
  }
  spec.homepage      = "https://github.com/majorendian/Modular-Tcp-Command-Server"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
      spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "release"
  spec.executables   = spec.files.grep(%r{^release/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", ">= 1.7"
  spec.add_development_dependency "rake", ">= 10.0"
  spec.add_development_dependency "rspec"
end
