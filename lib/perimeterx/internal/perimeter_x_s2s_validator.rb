require 'perimeterx/internal/perimeter_x_risk_client'

class PerimeterxS2SValidator < PerimeterxRiskClient

  attr_accessor :risk_mode
  attr_accessor :response

  def initialize(px_ctx, px_config, http_client)
    L.info("PerimeterxS2SValidator: initialize")
    @px_ctx = px_ctx
    @px_config = px_config
    @http_client = http_client
  end

  def send_risk_request
    L.info("PerimeterxS2SValidator[send_risk_request]: send_risk_request")
    risk_mode = @px_config['module_mode'] == 2 ? 'active_blocking' : 'monitor' #TODO: Make a constant instead of 2
    request_body = {
      'request' => {
        'ip'      => @px_ctx.context[:ip],
        'headers' => format_headers(),
        'uri'     => @px_ctx.context[:uri],
        'url'     => @px_ctx.context[:full_url]
      },
      'additional' => {
        's2s_call_reason' => @px_ctx.context[:s2s_call_reason],
        'module_version' => @px_config["sdk_name"],
        'http_method' => @px_ctx.context[:http_method],
        'http_version' => @px_ctx.context[:http_method],
        'risk_mode' => risk_mode
      }
    }

    if @px_ctx.context.key?("vid")
      L.info("PerimeterxS2SValidator[send_risk_request]: found vid")
      request_body[:vid] = @px_ctx.context[:vid];
    end


    if @px_ctx.context.key?("uuid")
      L.info("PerimeterxS2SValidator[send_risk_request]: found uuid")
      request_body[:uuid] = @px_ctx.context[:uuid];
    end

    # if (in_array($this->pxCtx->getS2SCallReason(), ['cookie_expired', 'cookie_validation_failed'])) {
    #     if ($this->pxCtx->getDecodedCookie()) {
    #         $requestBody['additional']['px_cookie'] = $this->pxCtx->getDecodedCookie();
    #     }
    # }

    headers = {
        "Authorization" => "Bearer #{@px_config['auth_token']}" ,
        "Content-Type" => "application/json"
    };
    
    if (risk_mode != 2  && @px_config['custom_risk_handler'])
      L.info("PerimeterxS2SValidator[send_risk_request]: custom risk handler")
      # response = @px_config['custom_risk_handler'](origReq);
    else
      L.info("PerimeterxS2SValidator[send_risk_request]: posting to px")
      #TODO: possible to add ,@px_config['api_timeout'], @px_config['api_connect_timeout']?
      response = @http_client.post("/api/v2/risk", request_body, headers)
    end
    return response;
  end

  def verify
    L.info("PerimeterxS2SValidator[verify]: started")
    response = send_risk_request()
    @px_ctx.context[:made_s2s_risk_api_call] = true

    # When success
    if (response.code == 200 && response.key?("score") && response.key?("action") )
      L.info("PerimeterxS2SValidator[verify]: response ok")
      score = response["score"]
      @px_ctx.context[:score] = score
      @px_ctx.context[:uuid] = response["uuid"]
      @px_ctx.context[:block_action] = response["action"]
      if(response["action"] == "j" && response.key?("action_data") && response["action_data"].key?("body"))
        L.info("PerimeterxS2SValidator[verify]: using challange")
        @px_ctx.context[:blocking_action_data] = response["action_data"]["body"]
        @px_ctx.context[:blocking_reason] = "challenge"
      elsif (score >= @px_config["blocking_score"])
        L.info("PerimeterxS2SValidator[verify]: s2s high score found")
        @px_ctx.context[:blocking_reason] = "s2s_high_score"
      end #end if challange or blocking score

    end#end success response

    # When error
    if(response.code != 200)
      L.warn("PerimeterxS2SValidator[verify]: bad response, return code #{response.code}")
      @px_ctx.context[:s2s_error_msg] = response["message"]
    end

    L.info("PerimeterxS2SValidator[verify]: done")
    return @px_ctx
  end #end method

end
