# frozen_string_literal: true

require 'base64'
require 'openssl'
require 'json'

module TokenGenerator
  def gen_token_v1(k, t, u, v, a, b, h = nil)
    s = "#{t}#{a}#{b}#{u}#{v}"

    h ||= hmac(k, s)

    d = {
      t: t,
      u: u,
      v: v,
      s: {
        a: a,
        b: b
      },
      h: h
    }

    j = JSON.generate(d)

    salt, enc = encrypt(k, j)
    b64_s = Base64.encode64(salt)

    "#{b64_s}:1000:#{Base64.encode64(enc)}"
  end

  def gen_token_v3(k, t, u, v, s, a, h = nil)
    d = {
      t: t,
      u: u,
      v: v,
      s: s,
      a: a
    }

    j = JSON.generate(d)

    salt, enc = encrypt(k, j)
    b64_s = Base64.encode64(salt).gsub(/\s+/, '')

    c = "#{b64_s}:1000:#{Base64.encode64(enc).gsub(/\s+/, '')}"
    h ||= hmac(k, c)

    "#{h}:#{c}"
  end

  def encrypt(key, data)
    cipher = OpenSSL::Cipher.new 'AES-256-CBC'
    cipher.encrypt

    salt = OpenSSL::Random.random_bytes 16
    iter = 1000
    digest = OpenSSL::Digest.new('SHA256')

    value = OpenSSL::PKCS5.pbkdf2_hmac(key, salt, iter, 48, digest)
    cipher.key = value[0..31]
    cipher.iv = value[32..]

    encrypted = cipher.update data
    encrypted << cipher.final

    [salt, encrypted]
  end

  def hmac(key, data)
    OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('SHA256'), key, data)
  end
end
