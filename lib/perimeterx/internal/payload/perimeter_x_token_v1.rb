module PxModule
  class PerimeterxTokenV1 < PerimeterxPayload

    attr_accessor :px_config, :px_ctx

    def initialize(px_config, px_ctx)
      super(px_config)
      @px_ctx = px_ctx
      @px_cookie = px_ctx.get_px_cookie
      @cookie_secret = px_config[:cookie_key]
      @logger.debug('PerimeterxTokenV1[initialize]')
    end

    def cookie_score
      return @decoded_cookie[:s][:b]
    end

    def cookie_hmac
      return @decoded_cookie[:h]
    end

    def valid_format?(cookie)
      return cookie.key?(:t) && cookie.key?(:s) && cookie[:s].key?(:b) && cookie.key?(:s) && cookie.key?(:v) && cookie.key?(:h)
    end

    def cookie_block_action
      return 'c'
    end

    def secured?
      hmac_str = "#{cookie_time}#{@decoded_cookie[:s][:a]}#{cookie_score}#{cookie_uuid}#{cookie_vid}"

      return hmac_valid?(hmac_str, cookie_hmac)
    end

  end

end