require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'ci/reporter/rake/rspec'
require 'cucumber'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new :spec
Cucumber::Rake::Task.new :features

task :jenkins => ['ci:setup:rspec', :spec] do
  Cucumber::Rake::Task.new do |t|
    t.cucumber_opts = "--tags ~@wip --format progress --format junit --out features/reports"
  end.runner.run


end

task default: [:spec, :features]
