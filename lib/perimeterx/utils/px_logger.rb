# frozen_string_literal: true

require 'logger'
module PxModule
  class PxLogger < Logger
    def initialize(debug)
      if debug
        super($stdout)
      else
        super(nil)
      end
    end
  end
end
