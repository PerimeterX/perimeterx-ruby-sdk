require 'perimeterx/internal/perimeter_x_risk_client'

class PerimeterxActivitiesClient < PerimeterxRiskClient

  attr_accessor :activities

  def initialize(px_config, http_client)
    L.debug("PerimeterxActivitiesClients[initialize]")
    @px_config = px_config
    @http_client = http_client
    @activities = [];
  end

  def send_to_perimeterx(activity_type, px_ctx, details = [])
    L.debug("PerimeterxActivitiesClients[send_to_perimeterx]")
    L.debug("PerimeterxActivitiesClients[send_to_perimeterx]: new activity #{activity_type} logged")

    if (@px_config.key?("additional_activity_handler"))
      @px_config["additional_activity_handler"].call(activity_type, px_ctx, details)
    end

    details[:module_version] = @px_config["sdk_name"]
    px_data = {
      :type       => activity_type,
      :headers    => format_headers(px_ctx),
      :timestamp  => DateTime.now.strftime('%Q'),
      :socket_ip  => px_ctx.context[:ip],
      :px_app_id  => @px_config["app_id"],
      :url        => px_ctx.context[:full_url],
      :details    => details,
    }

    if (px_ctx.context.key("vid"))
      L.debug("PerimeterxActivitiesClients[send_to_perimeterx]: found vid in ctx")
      px_data[:vid] = px_ctx.context[:vid]
    end

    # Prepare request
    headers = {
        "Authorization" => "Bearer #{@px_config['auth_token']}" ,
        "Content-Type" => "application/json"
    };

    @activities.push(px_data)
    if (@activities.size == @px_config["max_buffer_len"])
      L.debug("PerimeterxActivitiesClients[send_to_perimeterx]: max buffer length reached, sending activities")
      @http_client.async_post("/api/v1/collector/s2s", @activities, headers) #TODO: replace to constant

      @activities.clear
    end
  end

  def send_block_activity(px_ctx)
    L.debug("PerimeterxActivitiesClients[send_block_activity]")
    if (!@px_config["send_page_acitivites"])
      L.debug("PerimeterxActivitiesClients[send_block_activity]: sending activites is disabled")
      return
    end

    details = {
      :block_uuid    => px_ctx.context[:uuid],
      :block_score   => px_ctx.context[:score],
      :block_reason  => px_ctx.context[:block_reason]
    }

    send_to_perimeterx('block', px_ctx, details) #TODO: replace to constant

  end

  def send_page_requested_activity(px_ctx)
    L.debug("PerimeterxActivitiesClients[send_page_requested_activity]")
    if (!@px_config["send_page_acitivites"])
      return
    end

    details = {
      :http_version  => px_ctx.context[:http_version],
      :http_method   => px_ctx.context[:http_method]
    }

    if (px_ctx.context.key?("decoded_cookie"))
      details[:px_cookie] = px_ctx.context[:decoded_cookie]
    end

    if (px_ctx.context.key?("cookie_hmac"))
      details[:px_cookie_hmac] = px_ctx.context[:cookie_hmac]
    end

    send_to_perimeterx('page_requested', px_ctx, details) #TODO: replace to constant
  end
end
