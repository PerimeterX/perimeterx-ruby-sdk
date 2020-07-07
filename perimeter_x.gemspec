# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'perimeterx/version'

Gem::Specification.new do |gem|
  gem.name        = "perimeter_x"
  gem.summary     = "PerimeterX ruby implmentation"
  gem.description = "PerimeterX ruby module to monitor and block traffic according to PerimeterX risk score"
  gem.licenses    = ['MIT']
  gem.homepage    = "https://www.perimeterx.com"
  gem.version     = PxModule::VERSION

  gem.authors     = ["Nitzan Goldfeder"]
  gem.email       = "nitzan@perimeterx.com"

  gem.require_paths  = ["lib"]
  gem.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|gem|features)/})
  end

  gem.bindir        = "exe"
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.require_paths = ["lib"]
  gem.add_development_dependency "bundler", ">= 2.1"
  gem.add_development_dependency "rake", ">= 12.3"

  gem.extra_rdoc_files = ["readme.md", "changelog.md"]
  gem.rdoc_options     = ["--line-numbers", "--inline-source", "--title", "PerimeterX"]

  gem.required_ruby_version = '>= 2.3'

  gem.add_dependency('concurrent-ruby', '~> 1.0', '>= 1.0.5')
  gem.add_dependency('typhoeus', '~> 1.1', '>= 1.1.2')
  gem.add_dependency('mustache', '~> 1.0', '>= 1.0.3')
  gem.add_dependency('activesupport', '>= 5.2.4.3')

  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'mocha', '~> 1.2', '>= 1.2.1'
end
