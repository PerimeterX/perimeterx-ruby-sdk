require 'perimeterx/internal/perimeter_x_risk_client'

class PerimeterxActivitiesClient < PerimeterxRiskClient

  def initialize(px_ctx, px_config, http_client)
    L.info("PerimeterxActivitiesClient[initialize]")
    @px_ctx = px_ctx
    @px_config = px_config
    @http_client = http_client
  end

  def send_to_perimeter_x(activity_type, px_ctx, details = {})
    L.info("PerimeterxActivitiesClient[send_to_perimeter_x]")

    if (@px_config.key("additional_activity_handler"))
      L.info("PerimeterxActivitiesClient[send_to_perimeter_x] additional activitiy handler triggered")

      #TODO: execute function inputs
    end

    details[:module_version] = @px_config["sdk_name"];
    request_body = [{
      "type" => activity_type,
      "headers" => format_headers(),
      "timestamp" => DateTime.now.strftime('%Q'),
      "socket_ip" => px_ctx.context[:ip],
      "px_app_id" => @px_config["app_id"],
      "url" => px_ctx.context[:full_url],
      "details" => details
    }];

    if(px_ctx.context.key?("vid"))
      L.info("PerimeterxActivitiesClient[send_to_perimeter_x] found vid in context")
      request_body[:vid] = px_ctx.context[:vid]
    end

    headers = {
        "Authorization" => "Bearer #{@px_config['auth_token']}" ,
        "Content-Type" => "application/json"
    };

    L.info("PerimeterxActivitiesClient[send_to_perimeter_x] sending request")
    response = @http_client.post("/api/v1/collector/s2s", request_body, headers)
    puts(response)
  end

  def send_block_activity(px_ctx)
    L.info("PerimeterxActivitiesClient[send_block_activity]")
    details = {
      'block_uuid' => px_ctx.context[:uuid],
      'block_score' => px_ctx.context[:score],
      'block_reason' => px_ctx.context[:blocking_reason]
    }
    send_to_perimeter_x('block', px_ctx, details)

  end

end
