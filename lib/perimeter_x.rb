require 'concurrent'
require 'json'
require 'base64'
require 'uri'
require 'perimeterx/configuration'
require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_constants'
require 'perimeterx/utils/px_http_client'
require 'perimeterx/utils/px_template_factory'
require 'perimeterx/internal/perimeter_x_context'
require 'perimeterx/internal/clients/perimeter_x_activity_client'
require 'perimeterx/internal/validators/perimeter_x_s2s_validator'
require 'perimeterx/internal/validators/perimeter_x_cookie_validator'

module PxModule
  # Module expose API
  def px_verify_request
    px_ctx = PerimeterX.instance.verify(request.env)
    px_config = PerimeterX.instance.px_config
    msg_title = 'PxModule[px_verify_request]'

    # In case custom verification handler is in use
    if px_config.key?(:custom_verification_handler)
      px_config[:logger].debug("#{msg_title}: custom_verification_handler triggered")
      return instance_exec(px_ctx, &px_config[:custom_verification_handler])
    end

    unless px_ctx.nil? || px_ctx.context[:verified] || px_config[:module_mode] == PxModule::MONITOR_MODE
      # In case custom block handler exists (soon to be deprecated)
      if px_config.key?(:custom_block_handler)
        px_config[:logger].debug("#{msg_title}: custom_block_handler triggered")
        px_config[:logger].debug(
            "#{msg_title}: Please note that custom_block_handler is deprecated. Use custom_verification_handler instead.")
        return instance_exec(px_ctx, &px_config[:custom_block_handler])
      else
        # Generate template
        px_config[:logger].debug("#{msg_title}: sending default block page")
        response.status = 403

        is_mobile = px_ctx.context[:cookie_origin] == 'header' ? '1' : '0'
        action = px_ctx.context[:block_action][0,1]

        px_template_object = {
          block_script: "//#{PxModule::CAPTCHA_HOST}/#{px_config[:app_id]}/captcha.js?a=#{action}&u=#{px_ctx.context[:uuid]}&v=#{px_ctx.context[:vid]}&m=#{is_mobile}",
          js_client_src: "//#{PxModule::CLIENT_HOST}/#{px_config[:app_id]}/main.min.js"
        }

        html = PxTemplateFactory.get_template(px_ctx, px_config, px_template_object)

        # Web handler
        if px_ctx.context[:cookie_origin] == 'cookie'

          accept_header_value = request.headers['accept'] || request.headers['content-type'];
          is_json_response = px_ctx.context[:block_action] != 'rate_limit' && accept_header_value && accept_header_value.split(',').select {|e| e.downcase.include? 'application/json'}.length > 0;

          if (is_json_response)
            px_config[:logger].debug("#{msg_title}: advanced blocking response response")
            response.headers['Content-Type'] = 'application/json'

            hash_json = {
                :appId => px_config[:app_id],
                :jsClientSrc => px_template_object[:js_client_src],
                :firstPartyEnabled => false,
                :uuid => px_ctx.context[:uuid],
                :vid => px_ctx.context[:vid],
                :hostUrl => "https://collector-#{px_config[:app_id]}.perimeterx.net",
                :blockScript => px_template_object[:block_script],
            }

            render :json => hash_json
          else
            px_config[:logger].debug('#{msg_title}: web block')
            response.headers['Content-Type'] = 'text/html'
            render :html => html
          end
        else # Mobile SDK
          px_config[:logger].debug("#{msg_title}: mobile sdk block")
          response.headers['Content-Type'] = 'application/json'
          hash_json = {
              :action => px_ctx.context[:block_action],
              :uuid => px_ctx.context[:uuid],
              :vid => px_ctx.context[:vid],
              :appId => px_config[:app_id],
              :page => Base64.strict_encode64(html),
              :collectorUrl => "https://collector-#{px_config[:app_id]}.perimeterx.net"
          }
          render :json => hash_json
        end
      end
    end

    # Request was verified
    return px_ctx.nil? ? true : px_ctx.context[:verified]
  end

  def self.configure(params)
    @px_instance = PerimeterX.configure(params)
  end


  # PerimeterX Module
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
      return @@__instance if !@@__instance.nil?
      raise Exception.new('Please initialize perimeter x first')
    end


    #Instance Methods
    def verify(env)
      begin

        # check module_enabled 
        @logger.debug('PerimeterX[pxVerify]')
        if !@px_config[:module_enabled]
          @logger.warn('Module is disabled')
          return nil
        end

        req = ActionDispatch::Request.new(env)
        
        # filter whitelist routes
        url_path = URI.parse(req.original_url).path
        if url_path && !url_path.empty?
          if check_whitelist_routes(px_config[:whitelist_routes], url_path)
            @logger.debug("PerimeterX[pxVerify]: whitelist route: #{url_path}")
            return nil
          end
        end
        
        # create context
        px_ctx = PerimeterXContext.new(@px_config, req)

        # Cookie phase
        cookie_verified, px_ctx = @px_cookie_validator.verify(px_ctx)
        if !cookie_verified
          @px_s2s_validator.verify(px_ctx)
        end

        return handle_verification(px_ctx)
      rescue Exception => e
        @logger.error("#{e.backtrace.first}: #{e.message} (#{e.class})")
        e.backtrace.drop(1).map {|s| @logger.error("\t#{s}")}
        return nil
      end
    end

    private def initialize(params)
      @px_config = Configuration.new(params).configuration
      @logger = @px_config[:logger]
      @px_http_client = PxHttpClient.new(@px_config)

      @px_activity_client = PerimeterxActivitiesClient.new(@px_config, @px_http_client)

      @px_cookie_validator = PerimeterxCookieValidator.new(@px_config)
      @px_s2s_validator = PerimeterxS2SValidator.new(@px_config, @px_http_client)
      @logger.debug('PerimeterX[initialize]')
    end

    private def handle_verification(px_ctx)
      @logger.debug('PerimeterX[handle_verification]')
      @logger.debug("PerimeterX[handle_verification]: processing ended - score:#{px_ctx.context[:score]}, uuid:#{px_ctx.context[:uuid]}")

      score = px_ctx.context[:score]
      px_ctx.context[:verified] = score < @px_config[:blocking_score]
      # Case PASS request
      if px_ctx.context[:verified]
        @logger.debug("PerimeterX[handle_verification]: score:#{score} < blocking score, passing request")
        @px_activity_client.send_page_requested_activity(px_ctx)
        return px_ctx
      end

      # Case blocking activity
      @px_activity_client.send_block_activity(px_ctx)

      # In case were in monitor mode, end here
      if @px_config[:module_mode] == PxModule::MONITOR_MODE
        @logger.debug('PerimeterX[handle_verification]: monitor mode is on, passing request')
        return px_ctx
      end

      @logger.debug('PerimeterX[handle_verification]: verification ended, the request should be blocked')

      return px_ctx
    end

    private def check_whitelist_routes(whitelist_routes, path)
      whitelist_routes.each do |whitelist_route|
        if whitelist_route.is_a?(Regexp) && path.match(whitelist_route)
          return true
        end
        if whitelist_route.is_a?(String) && path.start_with?(whitelist_route)
          return true
        end
      end
      false
    end

    private_class_method :new
  end
end
