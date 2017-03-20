require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/perimeter_x_captcha_validator'
require 'perimeterx/internal/perimeter_x_cookie_validator'
require 'perimeterx/internal/perimeter_x_s2s_validator'

#TODO: Make it a singleton instance
module PerimeterX
  class PxModule
    L = PxLogger.instance

    attr_reader :px_config
    attr_accessor :px_http_client

    def initialize(params)
      @px_config = Configuration.new(params).configuration
      @px_http_client = PxHttpClient.new(@px_config)
    end

    def pxVerify(env)
      begin
        L.info("pxVerify started")
        req = ActionDispatch::Request.new(env)

        if (@px_config[:module_enabled])
          L.warn("Module is disabled")
          return
        end
        px_ctx = PerimeterXContext.new(@px_config, req)
        px_ctx.context[:s2s_call_reason] = "NO_COOKIE"

        s2sValidator = PerimeterxS2SValidator.new(px_ctx, @px_config, @px_http_client)
        px_ctx = s2sValidator.verify()

        handle_verification(px_ctx)
      rescue Exception => e
        puts("#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"})
      end
    end

    # private methods
    def handle_verification(px_ctx)
      L.info("handle_verification")
    end

    private :handle_verification
  end

end
