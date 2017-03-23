class PerimeterxCookieV3 < PerimeterxCookie

  attr_accessor :px_config, :px_ctx, :cookie_hash

  def initialize(px_config, px_ctx)
    hash, cookie = px_ctx.get_px_cookie().split(':', 3)
    @px_cookie = cookie
    @cookie_hash = hash
    @px_config = px_config
    @px_ctx = px_ctx
    @cookie_secret = px_config[:cookie_key]
  end

  def cookie_score
    return @decoded_cookie[:v3]
  end

  def cookie_hmac
    return @cookie_hmac
  end

  def valid_format?(cookie)
    debugger
    return cookie.key?(:t) && cookie.key?(:s) && cookie.key?(:u) && cookie.key?(:u) && cookie.key?(:a)
  end

  def cookie_block_action
    @decoded_cookie[:a]
  end

  def secured?
    hmac_string = "#{@px_cookie}#{@px_ctx.context[:user_agent]}"

    return hmac_valid?(hmac_string, @cookie_hmac)
  end
end
