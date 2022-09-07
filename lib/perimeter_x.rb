# frozen_string_literal: true

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
require 'perimeterx/internal/exceptions/px_config_exception'
require 'perimeterx/internal/first_party/px_first_party'

module PxModule
  # Module expose API
  def px_verify_request(request_config = {})
    px_instance = PerimeterX.new(request_config)
    req = ActionDispatch::Request.new(request.env)

    # handle first party requests
    if px_instance.first_party.is_first_party_request(req)
      render_first_party_response(req, px_instance)
      return true
    end

    # verify request
    px_ctx = px_instance.verify(req)
    px_config = px_instance.px_config

    msg_title = 'PxModule[px_verify_request]'

    # In case custom verification handler is in use
    if px_config.key?(:custom_verification_handler)
      px_config[:logger].debug("#{msg_title}: custom_verification_handler triggered")
      return instance_exec(px_ctx, &px_config[:custom_verification_handler])
    end

    unless px_ctx.nil? || px_ctx.context[:verified] || (px_config[:module_mode] == PxModule::MONITOR_MODE && !px_ctx.context[:should_bypass_monitor])
      # In case custom block handler exists (soon to be deprecated)
      if px_config.key?(:custom_block_handler)
        px_config[:logger].debug("#{msg_title}: custom_block_handler triggered")
        px_config[:logger].debug(
          "#{msg_title}: Please note that custom_block_handler is deprecated. Use custom_verification_handler instead."
        )
        return instance_exec(px_ctx, &px_config[:custom_block_handler])
      else
        if px_ctx.context[:block_action] == 'rate_limit'
          px_config[:logger].debug("#{msg_title}: sending rate limit page")
          response.status = 429
        else
          px_config[:logger].debug("#{msg_title}: sending default block page")
          response.status = 403
        end

        is_mobile = px_ctx.context[:cookie_origin] == 'header' ? '1' : '0'
        action = px_ctx.context[:block_action][0, 1]
        block_script_uri = "/captcha.js?a=#{action}&u=#{px_ctx.context[:uuid]}&v=#{px_ctx.context[:vid]}&m=#{is_mobile}"

        px_template_object = if px_config[:first_party_enabled]
                               {
                                 js_client_src: "/#{px_config[:app_id][2..]}/init.js",
                                 block_script: "/#{px_config[:app_id][2..]}/captcha/#{px_config[:app_id]}#{block_script_uri}",
                                 host_url: "/#{px_config[:app_id][2..]}/xhr",
                                 alt_block_script: "//#{PxModule::ALT_CAPTCHA_HOST}/#{px_config[:app_id]}#{block_script_uri}"
                               }
                             else
                               {
                                 js_client_src: "//#{PxModule::CLIENT_HOST}/#{px_config[:app_id]}/main.min.js",
                                 block_script: "//#{PxModule::CAPTCHA_HOST}/#{px_config[:app_id]}#{block_script_uri}",
                                 host_url: "https://collector-#{px_config[:app_id]}.perimeterx.net",
                                 alt_block_script: "//#{PxModule::ALT_CAPTCHA_HOST}/#{px_config[:app_id]}#{block_script_uri}"
                               }
                             end

        html = PxTemplateFactory.get_template(px_ctx, px_config, px_template_object)

        # Web handler
        if px_ctx.context[:cookie_origin] == 'cookie'

          accept_header_value = request.headers['accept'] || request.headers['content-type']
          is_json_response = px_ctx.context[:block_action] != 'rate_limit' && accept_header_value && accept_header_value.split(',').select do |e|
            e.downcase.include? 'application/json'
          end.length.positive?

          if is_json_response
            px_config[:logger].debug("#{msg_title}: advanced blocking response response")
            response.headers['Content-Type'] = 'application/json'

            hash_json = {
              appId: px_config[:app_id],
              jsClientSrc: px_template_object[:js_client_src],
              firstPartyEnabled: px_ctx.context[:first_party_enabled],
              uuid: px_ctx.context[:uuid],
              vid: px_ctx.context[:vid],
              hostUrl: "https://collector-#{px_config[:app_id]}.perimeterx.net",
              blockScript: px_template_object[:block_script],
              altBlockScript: px_template_object[:alt_block_script],
              customLogo: px_config[:custom_logo]
            }

            render json: hash_json
          else
            px_config[:logger].debug("#{msg_title}: web block")
            response.headers['Content-Type'] = 'text/html'
            render html: html
          end
        else # Mobile SDK
          px_config[:logger].debug("#{msg_title}: mobile sdk block")
          response.headers['Content-Type'] = 'application/json'
          hash_json = {
            action: px_ctx.context[:block_action],
            uuid: px_ctx.context[:uuid],
            vid: px_ctx.context[:vid],
            appId: px_config[:app_id],
            page: Base64.strict_encode64(html),
            collectorUrl: "https://collector-#{px_config[:app_id]}.perimeterx.net"
          }
          render json: hash_json
        end
      end
    end

    # Request was verified
    px_ctx.nil? ? true : px_ctx.context[:verified]
  rescue PxConfigurationException
    raise
  rescue Exception => e
    error_logger = PxLogger.new(true)
    error_logger.error("#{e.backtrace.first}: #{e.message} (#{e.class})")
    e.backtrace.drop(1).map { |s| error_logger.error("\t#{s}") }
    nil
  end

  def render_first_party_response(req, px_instance)
    fp = px_instance.first_party
    px_config = px_instance.px_config

    if px_config[:first_party_enabled]
      # first party enabled - proxy response
      fp_response = fp.send_first_party_request(req)
      response.status = fp_response.code
      fp_response.to_hash.each do |header_name, header_value_arr|
        response.headers[header_name] = header_value_arr[0] if header_name != 'content-length'
      end
      res_type = fp.get_response_content_type(req)
      render res_type => fp_response.body
    else
      # first party disabled - return empty response
      response.status = 200
      res_type = fp.get_response_content_type(req)
      render res_type => ''
    end
  end

  def self.configure(basic_config)
    PerimeterX.set_basic_config(basic_config)
  end

  # PerimeterX Module
  class PerimeterX
    attr_reader :px_config, :first_party
    attr_accessor :px_http_client, :px_activity_client

    # Static methods
    def self.set_basic_config(basic_config)
      Configuration.set_basic_config(basic_config)
    end

    # Instance Methods
    def verify(req)
      # check module_enabled
      @logger.debug('PerimeterX[pxVerify]')
      unless @px_config[:module_enabled]
        @logger.warn('Module is disabled')
        return nil
      end

      # filter whitelist routes
      url_path = URI.parse(req.original_url).path
      if url_path && !url_path.empty? && check_whitelist_routes(px_config[:whitelist_routes], url_path)
        @logger.debug("PerimeterX[pxVerify]: whitelist route: #{url_path}")
        return nil
      end

      # create context
      px_ctx = PerimeterXContext.new(@px_config, req)

      # Cookie phase
      cookie_verified, px_ctx = @px_cookie_validator.verify(px_ctx)
      unless cookie_verified
        px_ctx.context[:s2s_call_reason] = "mobile_error_#{px_ctx.context[:mobile_error]}" unless px_ctx.context[:mobile_error].nil?
        @px_s2s_validator.verify(px_ctx)
      end

      handle_verification(px_ctx)
    rescue Exception => e
      @logger.error("#{e.backtrace.first}: #{e.message} (#{e.class})")
      e.backtrace.drop(1).map { |s| @logger.error("\t#{s}") }
      nil
    end

    def initialize(request_config)
      @px_config = Configuration.new(request_config).configuration
      @logger = @px_config[:logger]
      @px_http_client = PxHttpClient.new(@px_config)

      @px_activity_client = PerimeterxActivitiesClient.new(@px_config, @px_http_client)
      @first_party = FirstPartyManager.new(@px_config, @px_http_client, @logger)

      @px_cookie_validator = PerimeterxCookieValidator.new(@px_config)
      @px_s2s_validator = PerimeterxS2SValidator.new(@px_config, @px_http_client)
      @logger.debug('PerimeterX[initialize]')
    end

    private

    def check_whitelist_routes(whitelist_routes, path)
      whitelist_routes.each do |whitelist_route|
        return true if whitelist_route.is_a?(Regexp) && path.match(whitelist_route)
        return true if whitelist_route.is_a?(String) && path.start_with?(whitelist_route)
      end
      false
    end

    def handle_verification(px_ctx)
      @logger.debug('PerimeterX[handle_verification]')
      @logger.debug("PerimeterX[handle_verification]: processing ended - score:#{px_ctx.context[:score]}, uuid:#{px_ctx.context[:uuid]}")

      score = px_ctx.context[:score]
      px_ctx.context[:should_bypass_monitor] =
        @px_config[:bypass_monitor_header] && px_ctx.context[:headers][@px_config[:bypass_monitor_header].to_sym] == '1'

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
      if @px_config[:module_mode] == PxModule::MONITOR_MODE && !px_ctx.context[:should_bypass_monitor]
        @logger.debug('PerimeterX[handle_verification]: monitor mode is on, passing request')
        return px_ctx
      end

      @logger.debug('PerimeterX[handle_verification]: verification ended, the request should be blocked')

      px_ctx
    end
  end
end
