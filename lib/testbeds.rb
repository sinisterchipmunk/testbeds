$:.unshift File.dirname(__FILE__)

require 'pathname'

require "testbeds/version"
require "testbeds/index"
require "testbeds/bed"
require "testbeds/index/testbed"

module Testbeds
  module_function

  def all
    @testbeds ||= Testbeds::Index.new.beds
  end

  def each &block
    all.each &block
  end

  def current
    if current_gemfile = ENV['BUNDLE_GEMFILE']
      all.each do |testbed|
        if testbed.gemfile == File.expand_path(current_gemfile)
          return testbed
        end
      end
    end

    nil
  end
end
