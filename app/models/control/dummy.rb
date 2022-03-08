module Control
  class Dummy < Base
    option :expected_result
    enumerize :expected_result, in: %w{warning error fail}, default: "warning"

    class Run < Macro::Base::Run
      def run
        raise "Raise error as expected" if options[:expected_result] == "fail"
      end
    end
  end
end