# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rack-auth-shared_cookie/version"

Gem::Specification.new do |s|
  s.name        = "rack-auth-shared_cookie"
  s.version     = Rack::Auth::SharedCookie::VERSION
  s.authors     = ["Grant Rodgers"]
  s.email       = ["grantr@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Authenticate with a shared cookie}
  s.description = %q{A rack middleware that enables authentication using a shared cookie across subdomains.}

  s.rubyforge_project = "rack-auth-shared_cookie"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  gem.add_runtime_dependency "rack", ">= 1.0.0"
end
