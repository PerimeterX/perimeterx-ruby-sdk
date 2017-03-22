require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/perimeter_x_s2s_validator'

module PerimeterX
  class PxModule
    L = PxLogger.instance

    @@singleton__instance__ = nil
    @@singleton__mutex__ = Mutex.new

    attr_reader :px_config
    attr_accessor :px_http_client

    def self.instance(params)
      return @@singleton__instance__ if @@singleton__instance__
      @@singleton__mutex__.synchronize {
        return @@singleton__instance__ if @@singleton__instance__
        @@singleton__instance__ = new(params)
      }
      @@singleton__instance__
    end


    private def initialize(params)
      L.debug("PerimeterX[initialize]")
      @px_config = Configuration.new(params).configuration
      @px_http_client = PxHttpClient.new(@px_config)
    end

    def px_verify(env)
      begin
        L.debug("PerimeterX[pxVerify]")
        req = ActionDispatch::Request.new(env)

        if (!@px_config['module_enabled'])
          L.warn("Module is disabled")
          return true
        end

        px_ctx = PerimeterXContext.new(@px_config, req)

        # Captcha phase
        captcha_validator = PerimeterxCaptchaValidator.new(px_ctx, @px_config)
        if (captcha_validator.verify())
          return handle_verification(px_ctx)
        end

        # Cookie phase
        cookie_validator = PerimeterxCookieValidator.new(px_ctx, @px_config)
        if (!cookie_validator.verify())
          s2sValidator = PerimeterxS2SValidator.new(px_ctx, @px_config, @px_http_client)
          s2sValidator.verify()
        end

      return handle_verification(px_ctx)
        if (px_config.key?('custom_verification_handler'))
          return px_config['custom_verification_handler'].call(px_ctx.context)
        else
          return handle_verification(px_ctx)
        end
      rescue Exception => e
        L.error("#{e.backtrace.first}: #{e.message} (#{e.class})")
        e.backtrace.drop(1).map { |s| L.error("\t#{s}") }
        return true
      end
    end

    # private methods
    private def handle_verification(px_ctx)
      L.debug("perimeterx processing ended - score:#{px_ctx.context[:score]}, uuid:#{px_ctx.context[:uuid]}")
      return true
    end

    private_class_method :new
  end

end
