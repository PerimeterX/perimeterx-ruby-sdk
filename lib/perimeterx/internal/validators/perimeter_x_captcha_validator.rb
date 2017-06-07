require 'perimeterx/internal/clients/perimeter_x_risk_client'

module PxModule
  class PerimeterxCaptchaValidator < PerimeterxRiskClient

    def initialize(px_config, http_client)
      super(px_config, http_client)
    end

    def send_captcha_request(vid, uuid, captcha, px_ctx)

      request_body = {
        :request => {
          :ip => px_ctx.context[:ip],
          :headers => format_headers(px_ctx),
          :uri => px_ctx.context[:uri]
        },
        :pxCaptcha => captcha,
        :vid => vid,
        :uuid => uuid,
        :hostname => px_ctx.context[:hostname]
      }

      # Prepare request
      headers = {
          "Authorization" => "Bearer #{@px_config[:auth_token]}" ,
          "Content-Type" => "application/json"
      };

      return @http_client.post(PxModule::API_V1_CAPTCHA, request_body, headers, @px_config[:api_timeout], @px_config[:api_timeout_connection])

    end

    def verify(px_ctx)
      captcha_validated = false
      begin
        if(!px_ctx.context.key?(:px_captcha))
          return captcha_validated, px_ctx
        end
        captcha, vid, uuid = px_ctx.context[:px_captcha].split(':', 3)
        if captcha.nil? || vid.nil? || uuid.nil?
          return captcha_validated, px_ctx
        end

        px_ctx.context[:vid] = vid
        px_ctx.context[:uuid] = uuid
        response = send_captcha_request(vid, uuid, captcha, px_ctx)

        if (response.status_code == 200)
          response_body = eval(response.body)
          if ( response_body[:status] == 0 )
            captcha_validated = true
          end
        end

        return captcha_validated, px_ctx

      rescue Exception => e
        @logger.error("PerimeterxCaptchaValidator[verify]: failed, returning false")
        return captcha_validated, px_ctx
      end
    end

  end
end
