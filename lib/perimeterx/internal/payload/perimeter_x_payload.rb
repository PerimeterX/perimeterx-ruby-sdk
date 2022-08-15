require 'base64'
require 'openssl'
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
        if (px_ctx.context[:px_cookie].key?(:v3))
          return PerimeterxTokenV3.new(px_config,px_ctx)
        end
        return PerimeterxTokenV1.new(px_config,px_ctx)
      elsif (px_ctx.context[:px_cookie].key?(:v3))
        return PerimeterxCookieV3.new(px_config, px_ctx)
      end
      return PerimeterxCookieV1.new(px_config, px_ctx)
    end

    def cookie_score
      #abstract, must be implemented
      raise Exception.new("Unimplemented method")
    end

    def cookie_hmac
      #abstract, must be implemented
      raise Exception.new("Unimplemented method")
    end

    def valid_format?(cookie)
      #abstract, must be implemented
      raise Exception.new("Unimplemented method")
    end

    def cookie_block_action
      #abstract, must be implemented
      raise Exception.new("Unimplemented method")
    end

    def secured?
      #abstract, must be implemented
      raise Exception.new("Unimplemented method")
    end

    def is_valid?
      return deserialize && !expired? && secured?
    end

    def cookie_time
      return @decoded_cookie[:t]
    end

    def cookie_uuid
      return @decoded_cookie[:u]
    end

    def cookie_vid
      return @decoded_cookie[:v]
    end

    def high_score?
      return cookie_score >= @px_config[:blocking_score]
    end

    def expired?
      return cookie_time < (Time.now.to_f*1000).floor
    end


    def deserialize
      if (!@decoded_cookie.nil?)
        return true
      end

      # Decode or decrypt, depends on configuration
      if (@px_config[:encryption_enabled])
        cookie = decrypt(@px_cookie)
      else
        cookie = decode(@px_cookie)
      end

      if (cookie.nil?)
        return false
      end

      if (!valid_format?(cookie))
        return false
      end

      @decoded_cookie = cookie

      return true
    end


    def decrypt(px_cookie)
      begin
        if (px_cookie.nil?)
          return
        end
        px_cookie = px_cookie.gsub(' ', '+')
        salt, iterations, cipher_text = px_cookie.split(':')
        iterations = iterations.to_i
        if (iterations > @px_config[:risk_cookie_max_iterations] || iterations < 500)
          return
        end
        salt = Base64.decode64(salt)
        cipher_text = Base64.decode64(cipher_text)
        digest = OpenSSL::Digest::SHA256.new
        value = OpenSSL::PKCS5.pbkdf2_hmac(@px_config[:cookie_key], salt, iterations, 48, digest)
        key = value[0..31]
        iv = value[32..-1]
        cipher = OpenSSL::Cipher::AES256.new(:CBC)
        cipher.decrypt
        cipher.key = key
        cipher.iv = iv
        plaintext = cipher.update(cipher_text) + cipher.final

        return eval(plaintext)
      rescue Exception => e
        @logger.debug("PerimeterxCookie[decrypt]: Cookie decrypt fail #{e.message}")
        raise PxCookieDecryptionException.new("Cookie decrypt fail => #{e.message}");
      end
    end

    def decode(px_cookie)
      return eval(Base64.decode64(px_cookie))
    end


    def hmac_valid?(hmac_str, cookie_hmac)
      hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, @cookie_secret, hmac_str)
      password_correct = secure_compare(hmac, cookie_hmac)
    end

    def secure_compare(a, b)
      # https://github.com/rails/rails/blob/main/activesupport/lib/active_support/security_utils.rb
      if (a.bytesize != b.bytesize)
        return false
      end

      l = a.unpack "C#{a.bytesize}"

      res = 0
      b.each_byte { |byte| res |= byte ^ l.shift }
      res == 0
    end
  end
end
