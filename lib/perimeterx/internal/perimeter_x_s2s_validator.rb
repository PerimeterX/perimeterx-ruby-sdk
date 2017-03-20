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
        'http_version' => @px_ctx.context[:http_version],
      }
    }

    headers = {
        "Authorization" => "Bearer #{@px_config['auth_token']}" ,
        "Content-Type" => "application/json"
    };

    return @http_client.post("/api/v2/risk", request_body, headers)
  end

  def verify
    L.info("PerimeterxS2SValidator[verify]: started")
    response = send_risk_request()
    @px_ctx.context[:made_s2s_risk_api_call] = true

    # When success
    if (response.code == 200 && response.key?("score") && response.key?("action"))
      L.info("PerimeterxS2SValidator[verify]: response ok")
      score = response["score"]
      @px_ctx.context[:score] = score
      @px_ctx.context[:uuid] = response["uuid"]
      @px_ctx.context[:block_action] = response["action"]
    end #end success response

    # When error
    if(response.code != 200)
      L.warn("PerimeterxS2SValidator[verify]: bad response, return code #{response.code}")
      @px_ctx.context[:uuid] = ""
      @px_ctx.context[:s2s_error_msg] = response["message"]
    end

    L.info("PerimeterxS2SValidator[verify]: done")
    return @px_ctx
  end #end method

end
