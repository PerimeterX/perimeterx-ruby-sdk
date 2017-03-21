require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/perimeter_x_s2s_validator'
#TODO: Make it a singleton instance
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
      L.info("PerimeterX[initialize]")
      @px_config = Configuration.new(params).configuration
      @px_http_client = PxHttpClient.new(@px_config)
    end

    def px_verify(env)
      begin
        L.info("PerimeterX[pxVerify]")
        req = ActionDispatch::Request.new(env)

        if (!@px_config['module_enabled'])
          L.warn("Module is disabled")
          return true
        end

        px_ctx = PerimeterXContext.new(@px_config, req)
        px_ctx.context[:s2s_call_reason] = "no_cookie"

        s2sValidator = PerimeterxS2SValidator.new(px_ctx, @px_config, @px_http_client)
        px_ctx = s2sValidator.verify()

        if (px_config.key?('custom_verification_handler'))
          return px_config['custom_verification_handler'].call(px_ctx.context)
        else
          return handle_verification(px_ctx)
        end
      rescue Exception => e
        puts("#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map { |s| "\t#{s}" })
        return true
      end
    end

    # private methods
    private def handle_verification(px_ctx)
      L.info("perimeterx processing ended - score:#{px_ctx.context[:score]}, uuid:#{px_ctx.context[:uuid]}")
      return true
    end

    private_class_method :new
  end

end
