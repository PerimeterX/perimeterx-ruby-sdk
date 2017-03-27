require 'logger'
# TODO: when set to debug mode write logs
module PxModule
  class PxLogger
    @@instance = Logger.new(STDOUT)

    def self.instance
      return @@instance
    end

    private_class_method :new
  end

end
