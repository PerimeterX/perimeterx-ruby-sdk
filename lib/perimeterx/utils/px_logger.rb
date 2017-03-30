require 'logger'
module PxModule

  class PxLogger < Logger

    def initialize(debug)
      if debug
        super(STDOUT)
      else
        super(nil)
      end

    end

  end
  
end
