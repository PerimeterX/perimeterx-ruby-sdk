require 'perimeterx/internal/perimeter_x_risk_client'

module PxModule
  class PerimeterxS2SValidator < PerimeterxRiskClient

    def initialize(px_config, http_client)
      L.debug("PerimeterxS2SValidator[initialize]")
      @px_config = px_config
      @http_client = http_client
    end

    def send_risk_request(px_ctx)
      L.debug("PerimeterxS2SValidator[send_risk_request]: send_risk_request")

      risk_mode = PxModule::RISK_MODE_ACTIVE
      if @px_config[:module_mode] == PxModule::MONITOR_MODE
        risk_mode = PxModule::RISK_MODE_MONITOR
      end

      request_body = {
        'request' => {
          'ip'      => px_ctx.context[:ip],
          'headers' => format_headers(px_ctx),
          'uri'     => px_ctx.context[:uri],
          'url'     => px_ctx.context[:full_url]
        },
        'additional' => {
          's2s_call_reason' => px_ctx.context[:s2s_call_reason],
          'module_version' => @px_config[:sdk_name],
          'http_method' => px_ctx.context[:http_method],
          'http_version' => px_ctx.context[:http_version],
          'risk_mode' => risk_mode
        }
      }

      #Check for hmac
      if px_ctx.context.key?(:cookie_hmac)
        request_body[:additional][:px_cookie_hmac] = px_ctx[:cookie_hmac]
      end


      #Check for VID
      if px_ctx.context.key?(:vid)
        request_body[:vid] = px_ctx.context[:vid]
      end

      #Check for uuid
      if px_ctx.context.key?(:uuid)
        request_body[:uuid] = px_ctx.context[:uuid]
      end

      #S2S Call reason
      decode_cookie_reasons = ['cookie_expired', 'cookie_validation_failed']
      if decode_cookie_reasons.include? (px_ctx.context[:s2s_call_reason])
        if (px_ctx.context.key?(:decoded_cookie))
          request_body[:additional][:px_cookie] = px_ctx.context[:decoded_cookie]
        end
      end

      # Prepare request
      headers = {
          "Authorization" => "Bearer #{@px_config[:auth_token]}" ,
          "Content-Type" => "application/json"
      };

      # Custom risk handler
      if (risk_mode == PxModule::ACTIVE_MODE && @px_config.key?(:custom_risk_handler))
        response = @px_config[:custom_risk_handler].call(PxModule::API_V2_RISK, request_body, headers, @px_config[:api_timeout])
      else
        response = @http_client.post(PxModule::API_V2_RISK , request_body, headers)
      end
      return response
    end

    def verify(px_ctx)
      L.debug("PerimeterxS2SValidator[verify]")
      response = send_risk_request(px_ctx)
      if (!response)
        return px_ctx
      end
      px_ctx.context[:made_s2s_risk_api_call] = true

      # From here response should be valid, if success or error
      response_body = eval(response.content);
      # When success
      if (response.status == 200 && response_body.key?(:score) && response_body.key?(:action))
        L.debug("PerimeterxS2SValidator[verify]: response ok")
        score = response_body[:score]
        px_ctx.context[:score] = score
        px_ctx.context[:uuid] = response_body[:uuid]
        px_ctx.context[:block_action] = response_body[:action]
        if (response_body[:action] == 'j' && response_body.key?("action_data") && response_body[:action_data].key?("body"))
          px_ctx.context[:block_action_data] = response_body[:action_data][:body]
          px_ctx.context[:blocking_reason] = 'challenge'
        elsif (score >= @px_config[:blocking_score])
          px_ctx.context[:blocking_reason] = 's2s_high_score'
        end #end challange or blocking score
      end #end success response

      # When error
      if(response.status != 200)
        L.warn("PerimeterxS2SValidator[verify]: bad response, return code #{response.code}")
        px_ctx.context[:uuid] = ""
        px_ctx.context[:s2s_error_msg] = response_body[:message]
      end

      L.debug("PerimeterxS2SValidator[verify]: done")
      return px_ctx
    end #end method

  end
end
