require './lib/perimeterx/version'

Gem::Specification.new do |gem|
  gem.name        = "perimeter_x"
  gem.summary     = "PerimeterX ruby implmentation"
  gem.description = "PerimeterX ruby module to monitor and block traffic according to PerimeterX risk score"
  gem.licenses    = ['MIT']
  gem.homepage    = "https://www.perimeterx.com"
  gem.version     = PerimeterX::VERSION

  gem.authors     = ["Nitzan Goldfeder"]
  gem.email       = "nitzan@perimeterx.com"

  gem.require_paths  = ["lib"]
  gem.files          = `git ls-files`.split("\n")


  gem.extra_rdoc_files = ["readme.md", "changelog.md"]
  gem.rdoc_options     = ["--line-numbers", "--inline-source", "--title", "PerimeterX"]

  gem.required_ruby_version = '>= 2.3'
end
