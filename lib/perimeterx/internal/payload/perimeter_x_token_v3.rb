module PxModule
  class PerimeterxTokenV3 < PerimeterxPayload

    attr_accessor :px_config, :px_ctx, :cookie_hash

    def initialize(px_config, px_ctx)
      super(px_config)
      hash, cookie = px_ctx.get_px_cookie().split(':', 2)
      @px_cookie = cookie
      @cookie_hash = hash
      @px_ctx = px_ctx
      @cookie_secret = px_config[:cookie_key]
      @logger.debug('PerimeterxTokenV3[initialize]')
    end

    def cookie_score
      return @decoded_cookie[:s]
    end

    def cookie_hmac
      return @cookie_hash
    end

    def valid_format?(cookie)
      return cookie.key?(:t) && cookie.key?(:s) && cookie.key?(:u) && cookie.key?(:u) && cookie.key?(:a)
    end

    def cookie_block_action
      @decoded_cookie[:a]
    end

    def secured?
      return hmac_valid?(@px_cookie, cookie_hmac)
    end
  end
end
