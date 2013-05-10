require "bundler/gem_tasks"

# in Rakefile
require 'testbeds/rake'
require 'rspec/core/rake_task'

each_testbed do |testbed| # namespace 'testbed:rails-3.2'
  desc "run rspec tests in #{testbed.name}"
  task :rspec do
    ENV['BUNDLE_GEMFILE'] = testbed.gemfile
    RSpec::Core::RakeTask.new("_rspec") do |t|
      opts = testbed.dependencies.collect { |dep| ['-r', dep] }.flatten
      t.rspec_opts = opts
    end
    Rake::Task["_rspec"].invoke
  end
end

desc 'run rspec tests in each testbed consecutively'
task :rspec do
  each_testbed do |testbed|
    raise unless system "rake #{testbed.namespace}:rspec"
  end
end
