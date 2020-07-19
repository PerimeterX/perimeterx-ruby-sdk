require 'perimeterx/internal/clients/perimeter_x_risk_client'

module PxModule
  class PerimeterxActivitiesClient < PerimeterxRiskClient


    def initialize(px_config, http_client)
      super(px_config, http_client)
      @logger.debug("PerimeterxActivitiesClients[initialize]")
    end

    def send_to_perimeterx(activity_type, px_ctx, details = [])
      @logger.debug("PerimeterxActivitiesClients[send_to_perimeterx]")
      @logger.debug("PerimeterxActivitiesClients[send_to_perimeterx]: new activity #{activity_type} logged")

      if (@px_config.key?(:additional_activity_handler))
        @px_config[:additional_activity_handler].call(activity_type, px_ctx, details)
      end

      details[:module_version] = @px_config[:sdk_name]
      details[:cookie_origin] = px_ctx.context[:cookie_origin]

      px_data = {
        :type       => activity_type,
        :headers    => format_headers(px_ctx),
        :timestamp  => (Time.now.to_f*1000).floor,
        :socket_ip  => px_ctx.context[:ip],
        :px_app_id  => @px_config[:app_id],
        :url        => px_ctx.context[:full_url],
        :details    => details,
      }

      if (px_ctx.context.key?(:vid))
        @logger.debug("PerimeterxActivitiesClients[send_to_perimeterx]: found vid in ctx")
        px_data[:vid] = px_ctx.context[:vid]
      end

      # Prepare request
      headers = {
          "Authorization" => "Bearer #{@px_config[:auth_token]}" ,
          "Content-Type" => "application/json"
      };

      s = Time.now
      @http_client.async.post(PxModule::API_V1_S2S, px_data, headers)
      e = Time.now
      @logger.debug("PerimeterxActivitiesClients[send_to_perimeterx]: post runtime #{(e-s)*1000}")
    end

    def send_block_activity(px_ctx)
      @logger.debug("PerimeterxActivitiesClients[send_block_activity]")
      if (!@px_config[:send_block_activities])
        @logger.debug("PerimeterxActivitiesClients[send_block_activity]: sending activites is disabled")
        return
      end

      details = {
        :http_version  => px_ctx.context[:http_version],
        :http_method   => px_ctx.context[:http_method],
        :client_uuid => px_ctx.context[:uuid],
        :block_score => px_ctx.context[:score],
        :block_reason => px_ctx.context[:blocking_reason],
        :simulated_block => @px_config[:module_mode] == PxModule::MONITOR_MODE
      }

      if (px_ctx.context.key?(:risk_rtt))
        details[:risk_rtt] = px_ctx.context[:risk_rtt]
      end

      if (px_ctx.context.key?(:px_orig_cookie))
        details[:px_orig_cookie] = px_ctx.context[:px_orig_cookie]
      end

      send_to_perimeterx(PxModule::BLOCK_ACTIVITY, px_ctx, details)

    end

    def send_page_requested_activity(px_ctx)
      @logger.debug("PerimeterxActivitiesClients[send_page_requested_activity]")
      if (!@px_config[:send_page_activities])
        return
      end

      details = {
        :http_version  => px_ctx.context[:http_version],
        :http_method   => px_ctx.context[:http_method],
        :client_uuid   => px_ctx.context[:uuid],
        :pass_reason  => px_ctx.context[:pass_reason]
      }

      if (px_ctx.context.key?(:decoded_cookie))
        details[:px_cookie] = px_ctx.context[:decoded_cookie]
      end

      if (px_ctx.context.key?(:px_orig_cookie))
        details[:px_orig_cookie] = px_ctx.context[:px_orig_cookie]
      end

      if (px_ctx.context.key?(:cookie_hmac))
        details[:px_cookie_hmac] = px_ctx.context[:cookie_hmac]
      end

      if (px_ctx.context.key?(:risk_rtt))
        details[:risk_rtt] = px_ctx.context[:risk_rtt]
      end

      send_to_perimeterx(PxModule::PAGE_REQUESTED_ACTIVITY, px_ctx, details)
    end
  end
end
