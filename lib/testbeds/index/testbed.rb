module Testbeds
  class Index
    class Testbed
      def initialize store_in, &block
        @gemfiles = []
        @dependencies = []
        @rakefile = "Rakefile"
        @init_script = nil
        @store_in = store_in
        instance_eval &block
      end

      def gemfiles *gemfiles
        @gemfiles.concat gemfiles.flatten
      end

      def init &block
        @init_script = block
      end

      def rakefile template
        @rakefile = template
      end

      def depend_on *deps
        @dependencies.concat deps.flatten
      end

      def flatten
        gemfiles.collect do |gemfile|
          Testbeds::Bed.new gemfile, @dependencies, @rakefile, @init_script, @store_in
        end
      end
    end
  end
end
