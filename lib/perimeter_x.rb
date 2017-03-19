require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/captcha_validator'
require 'perimeterx/internal/cookie_validator'
require 'perimeterx/internal/s2s_validator'

module PerimeterX
  class PxModule
    L = PxLogger.instance

    attr_accessor :px_config
    attr_accessor :px_client
    attr_accessor :instance

    def initialize(params)
      @px_config = Configuration.new(params).configuration
    end

    def pxVerify(env)
      L.info("pxVerify started")
      req = ActionDispatch::Request.new(env)

      if !px_config[:module_enabled]
        L.warn("Module is disabled")
        return
      end
      px_ctx = PerimeterXContext.new(px_config, req)

      captcha_validator = PerimeterxCaptchaValidator.new(px_ctx, px_config)
      if (captcha_validator.verify())
        return handle_verification(px_ctx)
      end

      cookie_validator = PerimeterxCookieValidator.new(px_ctx, px_config)
      if (!cookie_validator.verify())
        s2sValidator = PerimeterxS2SValidator.new(px_ctx, px_config)
        s2sValidator.verify()
      end

      return handle_verification(px_ctx)
    end

    # private methods
    def handle_verification(px_ctx)
      L.info("handle_verification")
    end

    private :handle_verification
  end

end
