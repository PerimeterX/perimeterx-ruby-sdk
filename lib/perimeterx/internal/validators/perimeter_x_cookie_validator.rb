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
        # Mobile Error cases
        if px_ctx.context[:cookie_origin] == 'header'
          if px_ctx.context[:px_cookie].to_s.empty?
            @logger.warn("PerimeterxCookieValidator:[verify]: Empty token value - decryption failed")
            px_ctx.context[:s2s_call_reason] = PxModule::COOKIE_DECRYPTION_FAILED
            return false, px_ctx
          elsif px_ctx.context[:px_cookie] == "1"
            @logger.warn("PerimeterxCookieValidator:[verify]: no cookie")
            px_ctx.context[:s2s_call_reason] = PxModule::NO_COOKIE
            return false, px_ctx
          elsif px_ctx.context[:px_cookie] == "2"   # Mobile SDK connection error
            @logger.warn("PerimeterxCookieValidator:[verify]: mobile sdk connection error")
            px_ctx.context[:s2s_call_reason] = PxModule::MOBILE_SDK_CONNECTION_ERROR
            return false, px_ctx
          elsif px_ctx.context[:px_cookie] == "3"   # Mobile SDK pinning error
            @logger.warn("PerimeterxCookieValidator:[verify]: mobile sdk pinning error")
            px_ctx.context[:s2s_call_reason] = PxModule::MOBILE_SDK_PINNING_ERROR
            return false, px_ctx
          end
        elsif px_ctx.context[:px_cookie].empty?
          @logger.warn("PerimeterxCookieValidator:[verify]: no cookie")
          px_ctx.context[:s2s_call_reason] = PxModule::NO_COOKIE
          return false, px_ctx
        end

        # Deserialize cookie start
        cookie = PerimeterxPayload.px_cookie_factory(px_ctx, @px_config)
        if !cookie.deserialize()
          @logger.warn("PerimeterxCookieValidator:[verify]: invalid cookie")
          px_ctx.context[:px_orig_cookie] = px_ctx.get_px_cookie
          px_ctx.context[:s2s_call_reason] =  PxModule::COOKIE_DECRYPTION_FAILED
          return false, px_ctx
        end
        px_ctx.context[:decoded_cookie] = cookie.decoded_cookie
        px_ctx.context[:score] = cookie.cookie_score()
        px_ctx.context[:uuid] = cookie.decoded_cookie[:u]
        px_ctx.context[:vid] = cookie.decoded_cookie[:v]
        px_ctx.context[:block_action] = px_ctx.set_block_action_type(cookie.cookie_block_action())
        px_ctx.context[:cookie_hmac] = cookie.cookie_hmac()

        if cookie.expired?
          @logger.warn("PerimeterxCookieValidator:[verify]: cookie expired")
          px_ctx.context[:s2s_call_reason] = PxModule::EXPIRED_COOKIE
          return false, px_ctx
        end

        if cookie.high_score?
          @logger.warn("PerimeterxCookieValidator:[verify]: cookie high score")
          px_ctx.context[:blocking_reason] = 'cookie_high_score'
          return true, px_ctx
        end

        if !cookie.secured?
          @logger.warn("PerimeterxCookieValidator:[verify]: cookie invalid hmac")
          px_ctx.context[:s2s_call_reason] = PxModule:: COOKIE_VALIDATION_FAILED
          return false, px_ctx
        end

        if px_ctx.context[:sensitive_route]
          @logger.info("PerimeterxCookieValidator:[verify]: cookie was verified but route is sensitive")
          px_ctx.context[:s2s_call_reason] = PxModule::SENSITIVE_ROUTE
          return false, px_ctx
        end

        @logger.debug("PerimeterxCookieValidator:[verify]: cookie validation passed succesfully")

        px_ctx.context[:pass_reason] = 'cookie'
        return true, px_ctx
      rescue Exception => e
        @logger.error("PerimeterxCookieValidator:[verify]: exception while verifying cookie => #{e.message}")
        px_ctx.context[:px_orig_cookie] = px_ctx.context[:px_cookie]
        px_ctx.context[:s2s_call_reason] = PxModule::COOKIE_DECRYPTION_FAILED
        return false, px_ctx
      end
    end

  end
end
