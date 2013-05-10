# Testbeds

It's not very easy to test your gem in many different environments. Take
for example Rails: how can you know that your gem, tested in a Rails 3.2 app,
will work in Rails 4.0, without regenerating the entire app? And after doing
so, how will you ensure backward compatibility to 3.2 going forward?

Those are the sorts of problems this gem is meant to help with.

## 1. Pull in the gem (duh)

First, add this gem to your project's list of development dependencies:

    # in my-gem.gemspec
    gem.add_development_dependency 'testbeds'

Then install it, of course.

## 2. Create Gemfiles (yes, more than one)

Add a Gemfile for each testbed you intend to implement. For example, you
might have a file in `gemfiles/rails-3.2` describing your dependencies for
testing within Rails 3.2, and another in `gemfiles/rails-4.0` which could
have a completely different set of dependencies.

## 3. The Bedfile

Then, create a `Bedfile` and use the handy-dandy DSL to build up your 
testbeds. Here's an example `Bedfile`:

    # store testbeds in spec/testbeds/*
    store_in "spec/testbeds"

    testbeds do
      # create 2 testbeds, one for Rails 3.2 and the other for Rails 4.0
      gemfiles 'gemfiles/rails-3.2',
               'gemfiles/rails-4.0'

      init do
        # when generating each testbed, first generate a Rails app...
        run "rails", "new", name, "--skip-bundle", "--skip-gemfile"
        chdir name

        # ...and then run the rspec-rails installer.
        run "rails", "g", "rspec:install"
      end

      # Load this Rakefile. More on this later.
      rakefile '<%= name %>/Rakefile'

      # Load this file as a dependency whenever code is executed in
      # the context of this testbed. More on this later.
      depend_on '<%= name %>/config/application.rb'
    end

There are only a few methods to be aware of:

  * `store_in` - sets the destination directory which will serve as the
    root of all of your testbeds. This is where the projects will be
    generated.

  * `testbeds do ... end` - Sets up one or more testbeds. You can call this
    method more than once, with different setup code for each invocation,
    or you can just call this method once.

  * `gemfiles` - Takes a list of paths to Gemfiles, relative to the
    `Bedfile`. Each Gemfile represents a testbed. All of the other set-up
    in this `testbeds do ... end` block will be duplicated once for each
    Gemfile.

  * `init do ... end` - Runs the given block when a testbed is being
    generated. This allows you to take whatever steps would be normally
    taken by a user of your gem within the target environment. In the 
    above example, we generate a Rails application and then run the
    rspec-rails installer, but this is only an example.

  * `rakefile` - Takes a path relative to `store_in` for loading Rake tasks.
    In your main `Rakefile`, you can just `require 'testbeds/rake'`. See
    the `Rake` section, below.

  * `depend_on` - Specifies the files within the testbed(s) which must be
    loaded whenever the testbed is being used. See the `Rake` section, below.

## 4. Generating Testbeds

When you're ready to build your testbeds, run the `generate-testbeds` script
that ships with this gem. It will remove everything in the `store_in` 
directory (so watch out!) and then start generating testbeds from scratch.
We purposely wipe out the previous state here, because we want to be able to
build up each testbed from a clean slate. In fact, you could opt not to even
commit the `store_in` directory to Git. (I haven't decided yet whether to
consider adding `store_in` to `.gitignore` a best practice, so consider it
a matter of opinion.)

At each stage of testbed generation, the command that is about to be executed
is printed to the screen for your reference. This way, if it fails, you will
know exactly at what point the failure occurred.

Here's an example of what testbed generation looks like:

    colin in testbeds  $ generate-testbeds 

    rm -rf /Users/colin/projects/gems/testbeds/spec/testbeds
    mkdir -p /Users/colin/projects/gems/testbeds/spec/testbeds
    export BUNDLE_GEMFILE="/Users/colin/projects/gems/testbeds/gemfiles/rails-3.2"
    bundle install
    bundle exec rails new rails-3.2 --skip-bundle --skip-gemfile
    bundle exec rails g rspec:install

    export BUNDLE_GEMFILE="/Users/colin/projects/gems/testbeds/gemfiles/rails-4.0"
    bundle install
    bundle exec rails new rails-4.0 --skip-bundle --skip-gemfile
    bundle exec rails g rspec:install


### Note about `BUNDLE_GEMFILE`

As you can see, `BUNDLE_GEMFILE` is exported at each stage. This gem relies
heavily on Bundler in this way. I think it's probably a bad idea to execute
`bundle execute generate-testbeds`, as this will create an environment that
conflicts with the testbed environments. I'm not sure what to expect in such
a state. You have been warned -- but I'll still accept pull requests if it
leads to fixable bugs.

## 5. Rake

Instead of trying to guess at a once-size-fits-all set of Rake tasks, I
decided after some deliberation that this gem should instead focus on
augmenting tasks written _by you_. So it's not a one-line drop-in sort of
thing. Instead it provides you the tools you need to run a Rake task
in one or more testbeds of your choosing.

Here's a typical `Rakefile` that makes use of this gem:

    # in Rakefile
    require 'testbeds/rake'
    require 'rspec/core/rake_task'

    # each_testbed yields a testbed itself, and also creates the corresponding
    # Rake namespace for the testbed.
    each_testbed do |testbed| # namespace 'testbed:rails-3.2'

      # create a namespaced rspec task for each testbed
      desc "run rspec tests in #{testbed.name}"
      task :rspec do
        ENV['BUNDLE_GEMFILE'] = testbed.gemfile

        # so here we'll create an RSpec task at runtime, and then invoke
        # it right away. You don't have to do it this way, but I chose to,
        # in order to silence some RSpec cruft at the command line.
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

When you have a `Rakefile` like this, running `rake --tasks` will show
about what you'd expect:

    rake build                     # Build testbeds-0.0.1.gem into the pkg directory.
    rake install                   # Build and install testbeds-0.0.1.gem into system gems.
    rake release                   # Create tag v0.0.1 and build and push testbeds-0.0.1.gem to Rubygems
    rake rspec                     # run rspec tests in each testbed consecutively
    rake testbed:rails-3.2:rspec   # run rspec tests in rails-3.2
    rake testbed:rails-4.0:rspec   # run rspec tests in rails-4.0

As you can see, we've namespaced each `rspec` task into its own testbed
namespace. This allows us to run the specs under, say, just the `rails-3.2`
testbed, ignoring for the moment the same specs under `rails-4.0`. We also
have the no-namespace `rake rspec` task, which will iterate through each
testbed and execute its specs consecutively. If any one of these fails,
the whole process will be aborted.

### Testbed Rake Tasks

There's one more thing you can do that is really cool, but not so obvious.
If you export the environment variable `BUNDLE_GEMFILE` pointing to one of
your testbed Gemfiles, then you get:

    $ BUNDLE_GEMFILE=gemfiles/rails-3.2 rake -T

    rake build                              # Build testbeds-0.0.1.gem into the pkg directory.
    rake install                            # Build and install testbeds-0.0.1.gem into system gems.
    rake release                            # Create tag v0.0.1 and build and push testbeds-0.0.1.gem to Rubygems
    rake rspec                              # run rspec tests in each testbed consecutively
    rake testbed:current:about              # List versions of all Rails frameworks and the environment
    rake testbed:current:assets:clean       # Remove compiled assets
    rake testbed:current:assets:precompile  # Compile all the assets named in config.assets.precompile
    rake testbed:current:db:create          # Create the database from config/database.yml for the current Rails.env (use db:create:a...
    rake testbed:current:db:drop            # Drops the database for the current Rails.env (use db:drop:all to drop all databases)
    rake testbed:current:db:fixtures:load   # Load fixtures into the current environment's database.
    rake testbed:current:db:migrate         # Migrate the database (options: VERSION=x, VERBOSE=false).
      < snip, long list >
    rake testbed:current:tmp:create         # Creates tmp directories for sessions, cache, sockets, and pids
    rake testbed:rails-3.2:rspec            # run rspec tests in rails-3.2
    rake testbed:rails-4.0:rspec            # run rspec tests in rails-4.0

As you can see, this syntax creates another namespace, `testbed:current`,
which contains the Rake tasks loaded for this testbed. This gives you a
convenient handle for e.g. running migrations and the like without having
to move from testbed to testbed.

## 6. Travis

You test on travis-ci.org, right? Yes, of course you do, and you want to run
your tests on each testbed, every time you commit. Here's how:

    # in .travis.yml
    before_script:
      # only if you don't commit the testbeds to git
      - generate-testbeds

    script: "rake testbeds:current:rspec"

    gemfile:
      - path/to/gemfiles/rails-3.2
      - path/to/gemfiles/rails-4.0


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
