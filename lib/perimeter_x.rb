require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_constants'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/utils/px_template_factory'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/clients/perimeter_x_activity_client'
require 'perimeterx/internal/validators/perimeter_x_s2s_validator'
require 'perimeterx/internal/validators/perimeter_x_cookie_validator'
require 'perimeterx/internal/validators/perimeter_x_captcha_validator'

module PxModule

  # Module expose API
  def px_verify_request
    verified, px_ctx = PerimeterX.instance.verify(env)

    # Invalidate _pxCaptcha, can be done only on the controller level
    cookies[:_pxCaptcha] = { value: "", expires: -1.minutes.from_now }

    if (!verified)
      # In case custon block handler exists
      if (PerimeterX.instance.px_config.key?(:custom_block_handler))
        PerimeterX.instance.px_config[:custom_block_handler].call(px_ctx)
      elsif (!verified)
        # Generate template
        html = PxTemplateFactory.get_template(px_ctx, PerimeterX.instance.px_config)
        response.headers["Content-Type"] = "text/html"
        response.status = 403
        render :html => html
      end
    end

    return verified
  end

  def self.configure(params)
    @px_instance = PerimeterX.configure(params)
  end


  # PerimtereX Module
  class PerimeterX
    @@__instance = nil
    @@mutex = Mutex.new

    attr_reader :px_config
    attr_accessor :px_http_client
    attr_accessor :px_activity_client

    #Static methods
    def self.configure(params)
      return true if @@__instance
      @@mutex.synchronize {
        return @@__instance if @@__instance
        @@__instance = new(params)
      }
      return true
    end

    def self.instance
      return @@__instance if !@@__instance.nil? else raise Exception.new("Please initialize perimeter x first")
    end


    #Instance Methods
    def verify(env)
      begin
        @logger.debug("PerimeterX[pxVerify]")
        req = ActionDispatch::Request.new(env)
        if (!@px_config[:module_enabled])
          @logger.warn("Module is disabled")
          return true
        end
        px_ctx = PerimeterXContext.new(@px_config, req)

        # Captcha phase
        captcha_verified, px_ctx = @px_captcha_validator.verify(px_ctx)
        if (captcha_verified)
          return handle_verification(px_ctx)
        end

        # Cookie phase
        cookie_verified, px_ctx = @px_cookie_validator.verify(px_ctx)
        if (!cookie_verified)
          @px_s2s_validator.verify(px_ctx)
        end

        if (@px_config.key?(:custom_verification_handler))
          return @px_config[:custom_verification_handler].call(px_ctx.context)
        else
          return handle_verification(px_ctx)
        end
      rescue Exception => e
        @logger.error("#{e.backtrace.first}: #{e.message} (#{e.class})")
        e.backtrace.drop(1).map { |s| @logger.error("\t#{s}") }
        return true
      end
    end

    private def initialize(params)
      @px_config = Configuration.new(params).configuration
      @logger = @px_config[:logger]
      @px_http_client = PxHttpClient.new(@px_config)

      @px_activity_client = PerimeterxActivitiesClient.new(@px_config, @px_http_client)

      @px_cookie_validator = PerimeterxCookieValidator.new(@px_config)
      @px_s2s_validator = PerimeterxS2SValidator.new(@px_config, @px_http_client)
      @px_captcha_validator = PerimeterxCaptchaValidator.new(@px_config, @px_http_client)
      @logger.debug("PerimeterX[initialize]")
    end

    private def handle_verification(px_ctx)
      @logger.debug("PerimeterX[handle_verification]")
      @logger.debug("PerimeterX[handle_verification]: processing ended - score:#{px_ctx.context[:score]}, uuid:#{px_ctx.context[:uuid]}")

      score = px_ctx.context[:score]
      # Case PASS request
      if (score < @px_config[:blocking_score])
        @logger.debug("PerimeterX[handle_verification]: score:#{score} < blocking score, passing request")
        @px_activity_client.send_page_requested_activity(px_ctx)
        return true
      end

      # Case blocking activity
      @px_activity_client.send_block_activity(px_ctx)

      # custom_block_handler - custom block handler defined by the user
      if(@px_config.key?(:custom_block_handler))
        @logger.debug("PerimeterX[handle_verification]: custom block handler triggered")
        @px_config[custom_block_handler].call(px_ctx)
      end

      # In case were in monitor mode, end here
      if(@px_config[:module_mode] == PxModule::MONITOR_MODE)
        @logger.debug("PerimeterX[handle_verification]: monitor mode is on, passing request")
        return true
      end

      @logger.debug("PerimeterX[handle_verification]: sending block page")

      return false, px_ctx
    end

    private_class_method :new
  end
end
