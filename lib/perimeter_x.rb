require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/perimeter_x_captcha_validator'
require 'perimeterx/internal/perimeter_x_cookie_validator'
require 'perimeterx/internal/perimeter_x_s2s_validator'

module PerimeterX
  class PxModule
    L = PxLogger.instance

    attr_reader :px_config
    attr_accessor :px_client
    attr_accessor :instance

    def initialize(params)
      @px_config = Configuration.new(params).configuration
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
        s2sValidator = PerimeterxS2SValidator.new(px_ctx, @px_config)
        s2sValidator.verify()

        return handle_verification(px_ctx)
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
