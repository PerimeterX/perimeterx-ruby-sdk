# frozen_string_literal: true

require 'spec_helper'
require 'token_generator'

RSpec.describe PxModule::PerimeterxPayload, 'Mobile SDK tests' do
  before(:each) do
    @params = {
      app_id: 'PX_APP_ID',
      cookie_key: 'cookie_key',
      auth_token: 'PX_AUTH_TOKEN'
    }

    @req = double('http_request', {
                    cookies: {},
                    headers: {},
                    server_name: 'MockServer',
                    user_agent: 'MockUserAgent',
                    original_url: 'http://moch.url.com/',
                    fullpath: '/',
                    format: double('format', { symbol: nil }),
                    ip: '1.2.3.4',
                    server_protocol: 'HTTP://1.1',
                    method: 'GET'
                  })
  end

  describe PxModule::PerimeterXContext, 'Context holding tokens' do
    it 'Should have cookie origin header and store token v3 in context' do
      @req.headers[PxModule::TOKEN_HEADER] = '3:1234567890:1234567890:1000:123456789'
      config = PxModule::Configuration.new(@params).configuration
      px_ctx = PxModule::PerimeterXContext.new(config, @req)

      expect(px_ctx.context[:cookie_origin]).to eq 'header'
      expect(px_ctx.context[:px_cookie][:v3]).to eq '1234567890:1234567890:1000:123456789'
    end
  end

  describe PxModule::PerimeterxTokenV3, 'Token v3 tests' do
    it 'Should not pass on cookie expired' do
      @req.headers[PxModule::TOKEN_HEADER] =
        "3:#{gen_token_v3(@params[:cookie_key], (Time.now.to_f * 1000).floor - 100_000, 'u', 'v', 100, 'c')}"

      config = PxModule::Configuration.new(@params).configuration
      px_ctx = PxModule::PerimeterXContext.new(config, @req)
      validator = PxModule::PerimeterxCookieValidator.new(config)

      verified, px_ctx = validator.verify(px_ctx)
      expect(verified).to eq false
      expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::EXPIRED_COOKIE
    end

    it 'Should pass and cookie high score' do
      @req.headers[PxModule::TOKEN_HEADER] =
        "3:#{gen_token_v3(@params[:cookie_key], (Time.now.to_f * 1000).floor + 20_000, 'u', 'v', 100, 'c')}"
      config = PxModule::Configuration.new(@params).configuration
      px_ctx = PxModule::PerimeterXContext.new(config, @req)
      validator = PxModule::PerimeterxCookieValidator.new(config)

      verified, px_ctx = validator.verify(px_ctx)
      expect(verified).to eq true
      expect(px_ctx.context[:blocking_reason]).to eq PxModule::COOKIE_HIGH_SCORE
    end

    it 'Should not pass and cookie high score' do
      @req.headers[PxModule::TOKEN_HEADER] =
        "3:#{gen_token_v3(@params[:cookie_key], (Time.now.to_f * 1000).floor + 20_000, 'u', 'v', 0, 'c', 'sdfdsf')}"
      config = PxModule::Configuration.new(@params).configuration
      px_ctx = PxModule::PerimeterXContext.new(config, @req)
      validator = PxModule::PerimeterxCookieValidator.new(config)

      verified, px_ctx = validator.verify(px_ctx)
      expect(verified).to eq false
      expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::COOKIE_VALIDATION_FAILED
    end

    it 'Should pass ok' do
      @req.headers[PxModule::TOKEN_HEADER] =
        "3:#{gen_token_v3(@params[:cookie_key], (Time.now.to_f * 1000).floor + 20_000, 'u', 'v', 0, 'c')}"
      config = PxModule::Configuration.new(@params).configuration
      px_ctx = PxModule::PerimeterXContext.new(config, @req)
      validator = PxModule::PerimeterxCookieValidator.new(config)

      verified, px_ctx = validator.verify(px_ctx)
      expect(verified).to eq true
      expect(px_ctx.context[:s2s_call_reason]).to eq nil
    end
  end
end
