require 'perimeterx/internal/clients/perimeter_x_risk_client'

module PxModule
  class PerimeterxCaptchaValidator < PerimeterxRiskClient

    def initialize(px_config, http_client)
      super(px_config, http_client)
    end

    def send_captcha_request(captcha, px_ctx)

      request_body = {
        :request => {
          :ip => px_ctx.context[:ip],
          :headers => format_headers(px_ctx),
          :uri => px_ctx.context[:uri],
          :captchaType => @px_config[:captcha_provider]
        },
        :additional => {
          :module_version => @px_config[:sdk_name]
        },
        :pxCaptcha => captcha,
        :hostname => px_ctx.context[:hostname]
      }

      # Prepare request
      headers = {
          "Authorization" => "Bearer #{@px_config[:auth_token]}" ,
          "Content-Type" => "application/json"
      }

      return @http_client.post(PxModule::API_CAPTCHA, request_body, headers, @px_config[:api_timeout], @px_config[:api_timeout_connection])

    end

    def verify(px_ctx)
      captcha_validated = false
      begin
        if !px_ctx.context.key?(:px_captcha)
          return captcha_validated, px_ctx
        end
        captcha = px_ctx.context[:px_captcha]
        if captcha.nil?
          return captcha_validated, px_ctx
        end

        response = send_captcha_request(captcha, px_ctx)

        if response.success?
          response_body = eval(response.body)
          if response_body[:status] == 0
            captcha_validated = true
          end
        end

        return captcha_validated, px_ctx

      rescue Exception => e
        @logger.error("PerimeterxCaptchaValidator[verify]: failed, returning false => #{e.message}")
        return captcha_validated, px_ctx
      end
    end

  end
end
