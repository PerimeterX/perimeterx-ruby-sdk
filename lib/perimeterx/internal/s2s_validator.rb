require 'perimeterx/utils/px_logger'

class PerimeterxS2SValidator
  L = PxLogger.instance


  def initialize(px_ctx, px_config)
    L.info("PerimeterxS2SValidator: initialize")

  end

  def verify
    L.info("PerimeterxS2SValidator: verify")
    return false
  end

end
