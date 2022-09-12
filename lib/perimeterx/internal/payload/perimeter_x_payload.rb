# frozen_string_literal: true

require 'base64'
require 'openssl'
require 'json'
require 'perimeterx/internal/exceptions/px_cookie_decryption_exception'

module PxModule
  class PerimeterxPayload
    attr_accessor :px_cookie, :px_config, :px_ctx, :cookie_secret, :decoded_cookie

    def initialize(px_config)
      @px_config = px_config
      @logger = px_config[:logger]
    end

    def self.px_cookie_factory(px_ctx, px_config)
      if px_ctx.context[:cookie_origin] == 'header'
        return PerimeterxTokenV3.new(px_config, px_ctx) if px_ctx.context[:px_cookie].key?(:v3)

        return PerimeterxTokenV1.new(px_config, px_ctx)
      elsif px_ctx.context[:px_cookie].key?(:v3)
        return PerimeterxCookieV3.new(px_config, px_ctx)
      end
      PerimeterxCookieV1.new(px_config, px_ctx)
    end

    def cookie_score
      # abstract, must be implemented
      raise StandardError, 'Unimplemented method'
    end

    def cookie_hmac
      # abstract, must be implemented
      raise StandardError, 'Unimplemented method'
    end

    def valid_format?(_cookie)
      # abstract, must be implemented
      raise StandardError, 'Unimplemented method'
    end

    def cookie_block_action
      # abstract, must be implemented
      raise StandardError, 'Unimplemented method'
    end

    def secured?
      # abstract, must be implemented
      raise StandardError, 'Unimplemented method'
    end

    def is_valid?
      deserialize && !expired? && secured?
    end

    def cookie_time
      @decoded_cookie[:t]
    end

    def cookie_uuid
      @decoded_cookie[:u]
    end

    def cookie_vid
      @decoded_cookie[:v]
    end

    def high_score?
      cookie_score >= @px_config[:blocking_score]
    end

    def expired?
      cookie_time < (Time.now.to_f * 1000).floor
    end

    def deserialize
      return true unless @decoded_cookie.nil?

      # Decode or decrypt, depends on configuration
      cookie = if @px_config[:encryption_enabled]
                 decrypt(@px_cookie)
               else
                 decode(@px_cookie)
               end

      return false if cookie.nil?

      return false unless valid_format?(cookie)

      @decoded_cookie = cookie

      true
    end

    def decrypt(px_cookie)
      return if px_cookie.nil?

      px_cookie = px_cookie.gsub(' ', '+')
      salt, iterations, cipher_text = px_cookie.split(':')
      iterations = iterations.to_i
      return if iterations > @px_config[:risk_cookie_max_iterations] || iterations < 500

      salt = Base64.decode64(salt)
      cipher_text = Base64.decode64(cipher_text)
      digest = OpenSSL::Digest.new('SHA256')
      value = OpenSSL::PKCS5.pbkdf2_hmac(@px_config[:cookie_key], salt, iterations, 48, digest)
      key = value[0..31]
      iv = value[32..]
      cipher = OpenSSL::Cipher.new('aes-256-cbc')
      cipher.decrypt
      cipher.key = key
      cipher.iv = iv
      plaintext = cipher.update(cipher_text) + cipher.final

      JSON.parse(plaintext, symbolize_names: true)
    rescue Exception => e
      @logger.debug("PerimeterxCookie[decrypt]: Cookie decrypt fail #{e.message}")
      raise PxCookieDecryptionException, "Cookie decrypt fail => #{e.message}"
    end

    def decode(px_cookie)
      JSON.parse(Base64.decode64(px_cookie), symbolize_names: true)
    end

    def hmac_valid?(hmac_str, cookie_hmac)
      hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), @cookie_secret, hmac_str)
      secure_compare(hmac, cookie_hmac)
    end

    def secure_compare(a, b)
      # https://github.com/rails/rails/blob/main/activesupport/lib/active_support/security_utils.rb
      return false if a.bytesize != b.bytesize

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res.zero?
    end
  end
end
