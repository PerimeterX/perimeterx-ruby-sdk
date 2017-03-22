require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/perimeter_x_s2s_validator'
require 'perimeterx/internal/perimeter_x_activity_client'
require 'perimeterx/internal/perimeter_x_cookie_validator'

module PerimeterX
  class PxModule
    L = PxLogger.instance

    @@singleton__instance__ = nil
    @@singleton__mutex__ = Mutex.new

    attr_reader :px_config
    attr_accessor :px_http_client
    attr_accessor :px_activity_client

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

      @px_activity_client = PerimeterxActivitiesClient.new(@px_config, @px_http_client)

      @px_cookie_validator = PerimeterxCookieValidator.new(@px_config)
      @px_s2s_validator = PerimeterxS2SValidator.new(@px_config, @px_http_client)
      @px_captcha_validator = PerimeterxCaptchaValidator.new(@px_config, @px_http_client)
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
        if (px_captcha_validator.verify(px_ctx))
          return handle_verification(px_ctx)
        end

        # Cookie phase
        cookie_verified, px_ctx = @px_cookie_validator.verify(px_ctx)
        if (!cookie_verified)
          px_s2s_validator.verify(px_ctx)
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
      L.debug("PerimeterX[handle_verification]")
      L.debug("PerimeterX[handle_verification]: processing ended - score:#{px_ctx.context[:score]}, uuid:#{px_ctx.context[:uuid]}")

      score = px_ctx.context[:score]
      # Case PASS request
      if (score < @px_config["blocking_score"])
        L.debug("PerimeterX[handle_verification]: score:#{score} < blocking score, passing request")
        @px_activity_client.send_page_requested_activity(px_ctx)
        return true
      end

      # Case blocking activity
      @px_activity_client.send_block_activity(px_ctx)

      # custom_block_handler - custom block handler defined by the user
      if(@px_config.key?('custom_block_handler'))
        @px_config['custom_block_handler'].call(px_ctx)
      end

      # In case were in monitor mode, end here
      if(@px_config["module_mode"] == 1) #TODO: reaplce with constatn
        return true
      end

      #TODO: Render HTML from here

      return false

    end

    private_class_method :new
  end

end
