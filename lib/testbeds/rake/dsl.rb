module Testbeds
  module Rake
    module DSL
      def each_testbed
        if current = Testbeds.current
          namespace 'testbed:current' do
            yield current
          end
        end

        Testbeds.each do |testbed|
          namespace testbed.namespace do
            yield testbed
          end
        end
      end
    end
  end
end
