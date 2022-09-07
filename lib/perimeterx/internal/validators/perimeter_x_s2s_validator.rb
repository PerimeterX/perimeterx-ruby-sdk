# frozen_string_literal: true

require 'json'
require 'perimeterx/internal/clients/perimeter_x_risk_client'

module PxModule
  class PerimeterxS2SValidator < PerimeterxRiskClient
    def initialize(px_config, http_client)
      super(px_config, http_client)
      @logger.debug('PerimeterxS2SValidator[initialize]')
    end

    def send_risk_request(px_ctx)
      @logger.debug('PerimeterxS2SValidator[send_risk_request]: send_risk_request')

      risk_mode = PxModule::RISK_MODE_ACTIVE
      risk_mode = PxModule::RISK_MODE_MONITOR if @px_config[:module_mode] == PxModule::MONITOR_MODE

      request_body = {
        request: {
          ip: px_ctx.context[:ip],
          headers: format_headers(px_ctx),
          url: px_ctx.context[:full_url]
        },
        additional: {
          s2s_call_reason: px_ctx.context[:s2s_call_reason],
          module_version: @px_config[:sdk_name],
          http_method: px_ctx.context[:http_method],
          http_version: px_ctx.context[:http_version],
          risk_mode: risk_mode
        }
      }

      # Check for cookie_origin
      unless px_ctx.context[:px_cookie].empty?
        request_body[:additional][:cookie_origin] =
          px_ctx.context[:cookie_origin]
      end

      # Override s2s_call_reason in case of mobile error
      request_body[:additional][:s2s_call_reason] = "mobile_error_#{px_ctx.context[:mobile_error]}" unless px_ctx.context[:mobile_error].nil?

      # Check for hmac
      @logger.debug("px_ctx cookie_hmac key = #{px_ctx.context.key?(:cookie_hmac)}, value is: #{px_ctx.context[:cookie_hmac]}")
      request_body[:additional][:px_cookie_hmac] = px_ctx.context[:cookie_hmac] if px_ctx.context.key?(:cookie_hmac)

      # Check for VID
      request_body[:vid] = px_ctx.context[:vid] if px_ctx.context.key?(:vid)

      # Check for uuid
      request_body[:uuid] = px_ctx.context[:uuid] if px_ctx.context.key?(:uuid)

      # S2S Call reason
      decode_cookie_reasons = [PxModule::EXPIRED_COOKIE, PxModule::COOKIE_VALIDATION_FAILED]
      if px_ctx.context[:s2s_call_reason] == PxModule::COOKIE_DECRYPTION_FAILED
        @logger.debug('PerimeterxS2SValidator[send_risk_request]: attaching px_orig_cookie to request')
        request_body[:additional][:px_orig_cookie] = px_ctx.context[:px_orig_cookie]
      elsif decode_cookie_reasons.include?(px_ctx.context[:s2s_call_reason])
        request_body[:additional][:px_cookie] = px_ctx.context[:decoded_cookie] if px_ctx.context.key?(:decoded_cookie)
      end

      # Prepare request
      headers = {
        'Authorization' => "Bearer #{@px_config[:auth_token]}",
        'Content-Type' => 'application/json'
      }

      # Custom risk handler
      risk_start = Time.now
      response = if risk_mode == PxModule::ACTIVE_MODE && @px_config.key?(:custom_risk_handler)
                   @px_config[:custom_risk_handler].call(PxModule::API_V3_RISK, request_body, headers,
                                                         @px_config[:api_timeout], @px_config[:api_timeout_connection])
                 else
                   @http_client.post(PxModule::API_V3_RISK, request_body, headers, @px_config[:api_timeout],
                                     @px_config[:api_timeout_connection])
                 end

      # Set risk_rtt
      if response
        risk_end = Time.now
        px_ctx.context[:risk_rtt] = ((risk_end - risk_start) * 1000).round
      end

      response
    end

    def verify(px_ctx)
      @logger.debug('PerimeterxS2SValidator[verify]')
      response = send_risk_request(px_ctx)
      unless response
        px_ctx.context[:pass_reason] = 's2s_timeout'
        return px_ctx
      end
      px_ctx.context[:made_s2s_risk_api_call] = true

      # From here response should be valid, if success or error
      response_body = JSON.parse(response.body, symbolize_names: true)
      # When success
      if response.code == 200 && response_body.key?(:score) && response_body.key?(:action) && response_body.key?(:status) && (response_body[:status]).zero?
        @logger.debug('PerimeterxS2SValidator[verify]: response ok')
        score = response_body[:score]
        px_ctx.context[:score] = score
        px_ctx.context[:uuid] = response_body[:uuid]
        px_ctx.context[:block_action] = px_ctx.set_block_action_type(response_body[:action])
        if response_body[:action] == 'j' && response_body.key?(:action_data) && response_body[:action_data].key?(:body)
          px_ctx.context[:block_action_data] = response_body[:action_data][:body]
          px_ctx.context[:blocking_reason] = 'challenge'
        elsif score >= @px_config[:blocking_score]
          px_ctx.context[:blocking_reason] = 's2s_high_score'
        else
          px_ctx.context[:pass_reason] = 's2s'
        end
      end

      # When error
      risk_error_status = response_body&.key?(:status) && response_body[:status] == -1
      if response.code != 200 || risk_error_status
        @logger.warn("PerimeterxS2SValidator[verify]: bad response, returned code #{response.code} #{risk_error_status ? 'risk status: -1' : ''}")
        px_ctx.context[:pass_reason] = 'request_failed'
        px_ctx.context[:uuid] = !response_body || response_body[:uuid].nil? ? '' : response_body[:uuid]
        px_ctx.context[:s2s_error_msg] =
          !response_body || response_body[:message].nil? ? 'unknown' : response_body[:message]
      end

      @logger.debug('PerimeterxS2SValidator[verify]: done')
      px_ctx
    end
  end
end
