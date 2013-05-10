# Dummy file to trick RSpec into actually running (and reporting 0 specs).
#
# I'm not clear on the best way to test this gem. For now, here is my
# process (and beware, it's not automated!):
#
#   1. Regenerate testbeds with `bin/generate-testbeds`.
#
#   2. Examine directory structure, particularly that `spec/testbeds`
#      is created and that it contains one subdirectory for each gemfile.
#
#   3. Run `rake -T` and ensure that RSpec tests appear for each testbed.
#
#   4. Run `rake rspec` and ensure that RSpec runs twice. Examine the output
#      to ensure that each execution of RSpec includes a different
#      bootstrap to config/application.rb -- one for each testbed.
#
# I know that testing this way is a horrible, horrible idea, but I've come up
# short in thinking of better ways to do this. I'm accepting pull requests.
#
