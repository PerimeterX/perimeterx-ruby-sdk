# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'

  RSpec::Core::RakeTask.new(:spec)
  RuboCop::RakeTask.new(:lint)

  task default: :spec
  task test: :spec
rescue LoadError
  # no rspec available
end
