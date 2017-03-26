require 'perimeterx/internal/perimeter_x_cookie'
require 'perimeterx/internal/perimeter_x_cookie_v1'
require 'perimeterx/internal/perimeter_x_cookie_v3'

class PerimeterxCookieValidator

  L = PxLogger.instance
  attr_accessor :px_config

  def initialize(px_config)
    @px_config = px_config
  end


  def verify(px_ctx)
    begin
      # Case no cookie
      if !px_ctx.context.key?(:px_cookie)
        L.warn("PerimeterxCookieValidator:[verify]: cookie not found")
        px_ctx.context[:s2s_call_reason] = 'no_cookie' #TODO: replace to constant
        return false, px_ctx
      end

      # Deserialize cookie start
      cookie = PerimeterxCookie.px_cookie_factory(px_ctx, @px_config)
      if (!cookie.deserialize())
        L.warn("PerimeterxCookieValidator:[verify]: invalid cookie")
        px_ctx.context[:s2s_call_reason] = 'invalid cookie' #TODO: replace to constant
        return false, px_ctx
      end

      px_ctx.context[:decoded_cookie] = cookie.decoded_cookie
      px_ctx.context[:score] = cookie.cookie_score()
      px_ctx.context[:uuid] = cookie.decoded_cookie[:u]
      px_ctx.context[:vid] = cookie.decoded_cookie[:v]
      px_ctx.context[:block_action] = cookie.cookie_block_action()
      px_ctx.context[:cookie_hmac] = cookie.cookie_hmac()

      if (cookie.expired?)
        L.warn("PerimeterxCookieValidator:[verify]: cookie expired")
        px_ctx.context[:s2s_call_reason] = 'cookie_expired' #TODO: replace to constant
        return false, px_ctx
      end

      if (cookie.high_score?)
        L.warn("PerimeterxCookieValidator:[verify]: cookie high score")
        px_ctx.context[:s2s_call_reason] = 'cookie_high_score' #TODO: replace to constant
        return false, px_ctx
      end

      if (cookie.secured?)
        L.warn("PerimeterxCookieValidator:[verify]: cookie invalid hmac")
        px_ctx.context[:s2s_call_reason] = 'cookie_validation_failed' #TODO: replace to constant
        return false, px_ctx
      end

      L.debug("PerimeterxCookieValidator:[verify]: cookie validation passed succesfully")

      return true, px_ctx
    rescue Exception => e
      L.error("PerimeterxCookieValidator:[verify]: exception while verifying cookie")
      px_ctx.context[:s2s_call_reason] = 'cookie_decryption_failed' #TODO: replace to constant
      return false, px_ctx
    end
  end

end
