require 'perimeterx/utils/px_logger'

class PerimeterxCaptchaValidator
  L = PxLogger.instance


  def initialize(px_ctx, px_config)
    L.info("PerimeterxCaptchaValidator: initialize")

  end

  def verify
    L.info("PerimeterxCaptchaValidator: verify")
    return false
  end

end
