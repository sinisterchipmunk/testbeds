module Testbeds
  class Index
    attr_reader :beds

    def find_index_file base_path = Pathname.new('.')
      path = File.expand_path(base_path.join('Bedfile'))
      return path if File.file?(path)
      # if we hit root, there is no Bedfile
      return nil if path =~ /:\\Bedfile/ or path =~ /^\/Bedfile/
      find_index_file base_path.join('..')
    end

    def initialize
      @store_in = "testbeds"
      @beds = []
      raise "no Bedfile found" unless file = find_index_file
      src = File.read file
      eval src, binding, file
    end

    def testbeds &block
      @beds.concat Testbeds::Index::Testbed.new(@store_in, &block).flatten
    end

    alias_method :testbed, :testbeds

    def store_in dest
      @store_in = dest
    end
  end
end
