class PerimeterxCookie
  attr_accessor :px_cookie, :px_config, :px_ctx, :cookie_secret, :decoded_cookie

  def self.px_cookie_factory(px_ctx, px_config)
    if (px_ctx.context[:px_cookie].key?('v3'))
      return CookieV3.new(px_ctx, px_config)
    end
    return CookieV1.new(px_ctx, px_config)
  end

  def deserialize
    if (@decoded_cookie.nil?)
      return true
    end

    # Decode or decrypt, depends on configuration
    if (@px_config["encryption_enabled"])
      cookie = decrypt(@px_cookie)
    else
      cookie = decode(@px_cookie)
    end

    if (cookie.nil?)
      return false
    end

    if (!validate_cookie_format(cookie))
      return false
    end

    @decoded_cookie = cookie

    return true
  end


  def decrypt(px_cookie)
        if (px_cookie.nil?)
          return
        end

        px_cookie = px_cookie.gsub(' ', '+')
        salt, iterations, cipher_text = px_cookie.split(':')
        iterations = iterations.to_i
        salt = Base64.decode64(salt)
        cipher_text = Base64.decode64(cipher_text)
        digest = OpenSSL::Digest::SHA256.new
        value = OpenSSL::PKCS5.pbkdf2_hmac(@px_config['cookie_key'], salt, iterations, 48, digest)
        key = value[0..31]
        iv = value[32..-1]
        cipher = OpenSSL::Cipher::AES256.new(:CBC)
        cipher.decrypt
        cipher.key = key
        cipher.iv = iv
        plaintext = cipher.update(cipher_text) + cipher.final
        return eval(Oj.load(plaintext))
      rescue
        raise RiskCookieError.new(Status::CookieDecryptionFailed)
      end
    end

    def decode(px_cookie)
      return eval(Base64.decode64(px_cookie))
    end
end
