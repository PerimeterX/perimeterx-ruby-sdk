require 'perimeterx/configuration'

module PerimterX
  class << self
    attr_accessor :px_config

    def initialize(params)
      @px_config = Configuration.new(params)
    end


    def verify
        puts("running px verify")
    end

  end

end
