require 'testbeds'
require "testbeds/rake/dsl"
extend Testbeds::Rake::DSL
if testbed = Testbeds.current
  namespace "testbed:current" do
    load testbed.rakefile if File.file?(testbed.rakefile)
  end
end
