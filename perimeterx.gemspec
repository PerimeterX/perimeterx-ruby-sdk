require 'perimeterx/version'

Gem::Specification.new do |gem|
  gem.name        = "perimeter_x"
  gem.summary     = "TODO: summary"
  gem.description = "TODO: description"
  gem.licenses    = ['MIT']
  gem.homepage    = "https://www.perimeterx.com"
  gem.version     = PerimeterX::VERSION

  gem.authors     = ["Nitzan Goldfeder"]
  gem.email       = "nitzan@perimeterx.com"

  gem.require_paths  = ["lib"]
  gem.files          = `git ls-files`.split("\n")


  gem.extra_rdoc_files = ["readme.md", "changelog.md"]
  gem.rdoc_options     = ["--line-numbers", "--inline-source", "--title", "PerimeterX"]

  gem.required_ruby_version = '>= 2.4'
end
