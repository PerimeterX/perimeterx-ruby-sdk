require 'perimeterx/utils/px_logger'

class PerimeterxCookieValidator
  L = PxLogger.instance


  def initialize(px_ctx, px_config)
    L.info("PerimeterxCookieValidator: initialize")

  end

  def verify
    L.info("PerimeterxCookieValidator: verify")
    return false
  end

end
