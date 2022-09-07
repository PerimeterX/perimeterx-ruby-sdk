# frozen_string_literal: true

module PxModule
  class PerimeterxCookieV1 < PerimeterxPayload
    attr_accessor :px_config, :px_ctx

    def initialize(px_config, px_ctx)
      super(px_config)
      @px_ctx = px_ctx
      @px_cookie = px_ctx.get_px_cookie
      @cookie_secret = px_config[:cookie_key]
      @logger.debug('PerimeterxCookieV1[initialize]')
    end

    def cookie_score
      @decoded_cookie[:s][:b]
    end

    def cookie_hmac
      @decoded_cookie[:h]
    end

    def valid_format?(cookie)
      cookie.key?(:t) && cookie.key?(:s) && cookie[:s].key?(:b) && cookie.key?(:s) && cookie.key?(:v) && cookie.key?(:h)
    end

    def cookie_block_action
      'c'
    end

    def secured?
      base_hmac_str = "#{cookie_time}#{@decoded_cookie[:s][:a]}#{cookie_score}#{cookie_uuid}#{cookie_vid}"

      hmac_str_withip = "#{base_hmac_str}#{@px_ctx.context[:ip]}#{@px_ctx.context[:user_agent]}"

      hmac_str_withoutip = "#{base_hmac_str}#{@px_ctx.context[:user_agent]}"

      (hmac_valid?(hmac_str_withoutip, cookie_hmac) || hmac_valid?(hmac_str_withip, cookie_hmac))
    end
  end
end
