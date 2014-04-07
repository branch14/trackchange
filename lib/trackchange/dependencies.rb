module Trackchange
  class Dependencies

    class << self

      def check
        quit('no diff?') if %x[ which diff ].empty?
        quit('no lynx?') if %x[ which lynx ].empty?
        quit('no mail?') if %x[ which mail ].empty?
      end

      def quit(msg)
        puts msg
        exit 1
      end

    end

  end
end

Trackchange::Dependencies.check
