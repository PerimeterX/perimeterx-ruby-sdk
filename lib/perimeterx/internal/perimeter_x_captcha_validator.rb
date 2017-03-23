class PerimeterxCaptchaValidator < PerimeterxRiskClient

  def initialize(px_config, http_client)
    @px_config = px_config
    @http_client = http_client
  end

  def send_captcha_request(vid, uuid, captcha, px_ctx)

    request_body = {
      :request => {
        :ip => px_ctx.context[:ip],
        :headers => format_headers(px_ctx),
        :uri => px_ctx.context[uri]
      },
      :pxCaptcha => captcha,
      :vid => vid,
      :uuid => uuid,
      hostname => px_ctx.context[:hostname]
    }

    # Prepare request
    headers = {
        "Authorization" => "Bearer #{@px_config[:auth_token]}" ,
        "Content-Type" => "application/json"
    };

    return @http_client.post('/api/v1/risk/captcha', request_body, @px_config[:api_timeout]) #TODO: replace to constant

  end

  def verify(px_ctx)
    captcha_validated = false
    begin
      if(!px_ctx.context.key?("px_captcha"))
        return captcha_validated, px_ctx
      end

      #TODO: set _pxCaptcha cookie to be invalid
      captcha, vid, uuid = px_ctx.context[:px_captcha].split(':', 3)
      if (!captcha.nil?) && (!vid.nil?) && (!uuid.nil?)
        return captcha_validated, px_ctx
      end

      px_ctx.context[:vid] = vid
      px_ctx.context[:uuid] = uuid
      response = send_captcha_request(vid, uuid, captcha, px_ctx)

      if (response.status == 200) #TODO: verify with ben
        captcha_validated = true
      end

      return captcha_validated

    rescue Exception => e
      L.error("PerimeterxCaptchaValidator[verify]: failed, returning false")
      return captcha_validated, px_ctx
    end
  end

end
