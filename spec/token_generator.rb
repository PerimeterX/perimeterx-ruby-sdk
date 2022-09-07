require 'base64'
require 'openssl'
require 'json'

module TokenGenerator
  def gen_token_v1(k, t, u, v, a, b, h = nil)
    s = "#{t}#{a}#{b}#{u}#{v}"

    unless h
      h = hmac(k, s)
    end

    d = {
        :t => t,
        :u => u,
        :v => v,
        :s => {
            :a => a,
            :b => b,
        },
        :h => h
    }

    j = JSON.generate(d)

    salt, enc = encrypt(k, j)
    b64_s = Base64.encode64(salt)

    return "#{b64_s}:1000:#{Base64.encode64(enc)}"
  end

  def gen_token_v3(k, t, u, v, s, a, h = nil)
    d = {
        :t => t,
        :u => u,
        :v => v,
        :s => s,
        :a => a
    }

    j = JSON.generate(d)

    salt, enc = encrypt(k, j)
    b64_s = Base64.encode64(salt).gsub(/\s+/, "")

    c = "#{b64_s}:1000:#{Base64.encode64(enc).gsub(/\s+/, "")}"
    unless h
      h = hmac(k, c)
    end

    return "#{h}:#{c}"
  end

  def encrypt(key, data)
    cipher = OpenSSL::Cipher.new 'AES-256-CBC'
    cipher.encrypt

    salt = OpenSSL::Random.random_bytes 16
    iter = 1000
    digest = OpenSSL::Digest::SHA256.new

    value = OpenSSL::PKCS5.pbkdf2_hmac(key, salt, iter, 48, digest)
    cipher.key = value[0..31]
    cipher.iv = value[32..-1]

    encrypted = cipher.update data
    encrypted << cipher.final

    return salt, encrypted
  end

  def hmac(key, data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest::SHA256.new, key, data)
  end
end