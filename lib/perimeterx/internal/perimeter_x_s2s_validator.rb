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
    L.info("PerimeterxS2SValidator: send_risk_request")
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
        'module_version' => @px_config[:sdk_name],
        'http_method' => @px_ctx.context[:http_method],
        'http_version' => @px_ctx.context[:http_method],
        'risk_mode' => risk_mode
      }
    }

    if @px_ctx.context[:vid]
        request_body[:vid] = @px_ctx.context[:vid];
    end


    if @px_ctx.context[:uuid]
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
      # response = @px_config['custom_risk_handler'](origReq);
    else
      #TODO: possible to add ,@px_config['api_timeout'], @px_config['api_connect_timeout']?
      response = @http_client.post("/api/v2/risk", request_body, headers)
    end
    return response;
  end

  def verify
    response = send_risk_request()
    @px_ctx.context[:made_s2s_risk_api_call] = true
  end

end
