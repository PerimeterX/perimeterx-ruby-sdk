# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PxModule::PerimeterxS2SValidator, 'S2S Validator Tests' do
  before(:each) do
    @params = {
      app_id: 'PX_APP_ID',
      cookie_key: 'PX_COOKIE_KEY',
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

    @config = PxModule::Configuration.new(@params).configuration
  end

  it 'pass request because sending failed' do
    px_ctx = PxModule::PerimeterXContext.new(@config, @req)

    http_client = double('http_client', post: nil)
    validator = PxModule::PerimeterxS2SValidator.new(@config, http_client)

    px_ctx = validator.verify(px_ctx)
    expect(px_ctx.context[:pass_reason]).to eq 's2s_timeout'
  end

  it 'ctx will contain block_action from captcha type' do
    px_ctx = PxModule::PerimeterXContext.new(@config, @req)

    http_client = double('http_client',
                         post: double('response',
                                      { code: 200,
                                        body: '{ "score": 0, "uuid": "uuid", "action": "c", "status": 0 }' }))
    validator = PxModule::PerimeterxS2SValidator.new(@config, http_client)
    expect(px_ctx.context[:block_action]).to be_nil

    px_ctx = validator.verify(px_ctx)
    expect(px_ctx.context[:block_action]).to eq 'captcha'
  end

  it 'ctx will contain block_action from block type' do
    px_ctx = PxModule::PerimeterXContext.new(@config, @req)

    http_client = double('http_client',
                         post: double('response',
                                      { code: 200,
                                        body: '{ "score": 0, "uuid": "uuid", "action": "b", "status": 0 }' }))
    validator = PxModule::PerimeterxS2SValidator.new(@config, http_client)
    expect(px_ctx.context[:block_action]).to be_nil

    px_ctx = validator.verify(px_ctx)
    expect(px_ctx.context[:block_action]).to eq 'block'
    expect(px_ctx.context[:blocking_reason]).to be_nil
  end

  it 'ctx will contain block_action from block type and blocking_reason should s2s_high_score' do
    px_ctx = PxModule::PerimeterXContext.new(@config, @req)

    http_client = double('http_client',
                         post: double('response',
                                      { code: 200,
                                        body: '{ "score": 100, "uuid": "uuid", "action": "b", "status": 0 }' }))
    validator = PxModule::PerimeterxS2SValidator.new(@config, http_client)
    expect(px_ctx.context[:block_action]).to be_nil

    px_ctx = validator.verify(px_ctx)
    expect(px_ctx.context[:block_action]).to eq 'block'
    expect(px_ctx.context[:blocking_reason]).to eq 's2s_high_score'
  end

  it 'ctx will contain block_action from block type and blocking_reason should be empty' do
    px_ctx = PxModule::PerimeterXContext.new(@config, @req)

    http_client = double('http_client',
                         post: double('response',
                                      { code: 200, body: '{"score": 0, "uuid": "uuid", "action": "b", "status": 0}' }))
    validator = PxModule::PerimeterxS2SValidator.new(@config, http_client)
    expect(px_ctx.context[:block_action]).to be_nil

    px_ctx = validator.verify(px_ctx)
    expect(px_ctx.context[:block_action]).to eq 'block'
    expect(px_ctx.context[:blocking_reason]).to be_nil
  end

  it 'ctx will contain block_action from challenge type and have block block_action_data' do
    px_ctx = PxModule::PerimeterXContext.new(@config, @req)

    http_client = double('http_client',
                         post: double('response',
                                      { code: 200,
                                        body: '{"score": 0, "uuid": "uuid", "action": "j", "status": 0, "action_data": {"body": "challenge_body"}}' }))
    validator = PxModule::PerimeterxS2SValidator.new(@config, http_client)
    expect(px_ctx.context[:block_action]).to be_nil

    px_ctx = validator.verify(px_ctx)
    expect(px_ctx.context[:block_action]).to eq 'challenge'
    expect(px_ctx.context[:block_action_data]).not_to be_nil
  end
end
