require 'perimeterx/utils/px_constants'
require 'perimeterx/internal/payload/perimeter_x_payload'
require 'perimeterx/internal/payload/perimeter_x_token_v1'
require 'perimeterx/internal/payload/perimeter_x_token_v3'
require 'perimeterx/internal/payload/perimeter_x_cookie_v1'
require 'perimeterx/internal/payload/perimeter_x_cookie_v3'

module PxModule
  class PerimeterxCookieValidator

    attr_accessor :px_config

    def initialize(px_config)
      @px_config = px_config
      @logger = px_config[:logger]
    end


    def verify(px_ctx)
      begin
        # Case no cookie
        if px_ctx.context[:px_cookie].empty?
          @logger.warn("PerimeterxCookieValidator:[verify]: cookie not found")
          px_ctx.context[:s2s_call_reason] = PxModule::NO_COOKIE
          return false, px_ctx
        end

        # Deserialize cookie start
        cookie = PerimeterxPayload.px_cookie_factory(px_ctx, @px_config)
        if (!cookie.deserialize())
          @logger.warn("PerimeterxCookieValidator:[verify]: invalid cookie")
          px_ctx.context[:s2s_call_reason] =  PxModule::COOKIE_DECRYPTION_FAILED
          return false, px_ctx
        end
        px_ctx.context[:decoded_cookie] = cookie.decoded_cookie
        px_ctx.context[:score] = cookie.cookie_score()
        px_ctx.context[:uuid] = cookie.decoded_cookie[:u]
        px_ctx.context[:vid] = cookie.decoded_cookie[:v]
        px_ctx.context[:block_action] = px_ctx.set_block_action_type(cookie.cookie_block_action())
        px_ctx.context[:cookie_hmac] = cookie.cookie_hmac()

        if (cookie.expired?)
          @logger.warn("PerimeterxCookieValidator:[verify]: cookie expired")
          px_ctx.context[:s2s_call_reason] = PxModule::EXPIRED_COOKIE
          return false, px_ctx
        end

        if (cookie.high_score?)
          @logger.warn("PerimeterxCookieValidator:[verify]: cookie high score")
          px_ctx.context[:blocking_reason] = 'cookie_high_score'
          return true, px_ctx
        end

        if (!cookie.secured?)
          @logger.warn("PerimeterxCookieValidator:[verify]: cookie invalid hmac")
          px_ctx.context[:s2s_call_reason] = PxModule::COOKIE_VALIDATION_FAILED
          return false, px_ctx
        end

        if (px_ctx.context[:sensitive_route])
          @logger.info("PerimeterxCookieValidator:[verify]: cookie was verified but route is sensitive")
          px_ctx.context[:s2s_call_reason] = PxModule::SENSITIVE_ROUTE
          return false, px_ctx
        end

        @logger.debug("PerimeterxCookieValidator:[verify]: cookie validation passed succesfully")

        return true, px_ctx
      rescue Exception => e
        @logger.error("PerimeterxCookieValidator:[verify]: exception while verifying cookie => #{e.message}")
        px_ctx.context[:px_orig_cookie] = cookie.px_cookie
        px_ctx.context[:s2s_call_reason] = PxModule::COOKIE_DECRYPTION_FAILED
        return false, px_ctx
      end
    end

  end
end
