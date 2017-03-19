require 'logger'

class PxLogger
  @@instance = Logger.new(STDOUT)

  def self.instance
    return @@instance
  end

  private_class_method :new
end
