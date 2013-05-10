require 'erb'

module Testbeds
  class Bed
    attr_reader :gemfile, :dependencies, :rakefile, :store_in

    def namespace
      "testbed:#{name}"
    end

    def template str
      ERB.new(str).result(binding)
    end

    def name
      @name ||= Pathname.new File.basename(gemfile)
    end

    def run_init_script
      instance_eval &@init_script if @init_script
    end

    def initialize gemfile, dependencies, rakefile, init_script, store_in
      @store_in     = Pathname.new File.expand_path(store_in)
      @gemfile      = File.expand_path gemfile
      @rakefile     = @store_in.join template(rakefile)
      @init_script  = init_script
      @dependencies = dependencies.collect do |dep|
        @store_in.join template(dep)
      end
    end
  end
end
