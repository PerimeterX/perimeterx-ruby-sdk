require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/perimeter_x_captcha_validator'
require 'perimeterx/internal/perimeter_x_cookie_validator'
require 'perimeterx/internal/perimeter_x_s2s_validator'
require 'perimeterx/internal/perimeter_x_activities_client'

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

        if (@px_config['module_enabled'])
          L.warn("Module is disabled")
          return true
        end
        px_ctx = PerimeterXContext.new(@px_config, req)
        px_ctx.context[:s2s_call_reason] = "no_cookie"

        s2sValidator = PerimeterxS2SValidator.new(px_ctx, @px_config, @px_http_client)
        px_ctx = s2sValidator.verify()

        handle_verification(px_ctx)
      rescue Exception => e
        puts("#{e.backtrace.first}: #{e.message} (#{e.class})", e.backtrace.drop(1).map{|s| "\t#{s}"})
      end
    end

    # private methods
    def handle_verification(px_ctx)
      L.info("PxModule[handle_verification]: started")
      px_activities_client = PerimeterxActivitiesClient.new(px_ctx, @px_config, @px_http_client)
      score = px_ctx.context[:score]

      # Passing request
      if ( score < @px_config["blocking_score"] )
        L.info("PxModule[handle_verification]: passing request")
        px_activities_client.send_page_requested_activity(px_ctx);
        return
      end

      #Block request
      L.info("PxModule[handle_verification]: blocking request")
      px_activities_client.send_block_activity(px_ctx)
      if (!@px_config.key?("custom_block_handler"))
        #TODO: Use custom block handler
        return
      end

      # End here if monitor mode
      if (@px_config['module_mode'] == 1) #TODO: Make a constant
          return
      end

      #TODO: add block logic

    end

    private :handle_verification
  end

end
