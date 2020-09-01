# require 'spec_helper'
# require 'token_generator'

# RSpec.describe PxModule::PerimeterxPayload, 'Mobile SDK tests' do

#   before(:each) do
#     @params = {
#         :app_id => 'PX_APP_ID',
#         :cookie_key => 'cookie_key',
#         :auth_token => 'PX_AUTH_TOKEN'
#     }

#     @req = double('http_request', {
#         :cookies => Hash.new,
#         :headers => Hash.new,
#         :server_name => 'MockServer',
#         :user_agent => 'MockUserAgent',
#         :original_url => 'http://moch.url.com/',
#         :fullpath => '/',
#         :format => double('format', { :symbol => nil } ),
#         :ip => '1.2.3.4',
#         :server_protocol => 'HTTP://1.1',
#         :method => 'GET'
#     })
#   end

#   describe PxModule::PerimeterXContext, 'Context holding tokens' do
#     it 'Should have cookie origin header and store token v1 in context' do
#       @req.headers['X-PX-AUTHORIZATION'] = '1:1234567890:1000:123456789'
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)

#       expect(px_ctx.context[:cookie_origin]).to eq 'header'
#       expect(px_ctx.context[:px_cookie][:v1]).to eq '1234567890:1000:123456789'
#     end

#     it 'Should have cookie origin header and store token v3 in context' do
#       @req.headers['X-PX-AUTHORIZATION'] = '3:1234567890:1234567890:1000:123456789'
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)

#       expect(px_ctx.context[:cookie_origin]).to eq 'header'
#       expect(px_ctx.context[:px_cookie][:v3]).to eq '1234567890:1234567890:1000:123456789'
#     end
#   end

#   describe PxModule::PerimeterxPayload, 'Getting correct token' do
#     it 'Factory should extract token v1' do
#       @req.headers['X-PX-AUTHORIZATION'] = '1:1234567890:1000:123456789'
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)

#       token = PxModule::PerimeterxPayload.px_cookie_factory(px_ctx,config)

#       expect(token.class).to eq PxModule::PerimeterxTokenV1
#     end

#     it 'Factory should extract token v1' do
#       @req.headers['X-PX-AUTHORIZATION'] = '3:1234567890:1234567890:1000:123456789'
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)

#       token = PxModule::PerimeterxPayload.px_cookie_factory(px_ctx,config)

#       expect(token.class).to eq PxModule::PerimeterxTokenV3
#     end
#   end

#   describe PxModule::PerimeterxCookieValidator, 'Verifying tokens' do

#     it 'Should not pass on empty token' do
#       @req.headers["#{PxModule::TOKEN_HEADER}"] = ""
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)
#       validator = PxModule::PerimeterxCookieValidator.new(config)

#       verified, px_ctx = validator.verify(px_ctx)
#       expect(verified).to eq false
#       expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::COOKIE_DECRYPTION_FAILED
#     end

#     it 'Should not pass on no cookie' do
#       @req.headers["#{PxModule::TOKEN_HEADER}"] = "1"
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)
#       validator = PxModule::PerimeterxCookieValidator.new(config)

#       verified, px_ctx = validator.verify(px_ctx)
#       expect(verified).to eq false
#       expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::NO_COOKIE
#     end

#     it 'Should not pass on connection error' do
#       @req.headers["#{PxModule::TOKEN_HEADER}"] = "2"
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)
#       validator = PxModule::PerimeterxCookieValidator.new(config)

#       verified, px_ctx = validator.verify(px_ctx)
#       expect(verified).to eq false
#     end

#     it 'Should not pass on pinning error' do
#       @req.headers["#{PxModule::TOKEN_HEADER}"] = "3"
#       config = PxModule::Configuration.new(@params).configuration
#       px_ctx = PxModule::PerimeterXContext.new(config, @req)
#       validator = PxModule::PerimeterxCookieValidator.new(config)

#       verified, px_ctx = validator.verify(px_ctx)
#       expect(verified).to eq false
#     end

#     describe PxModule::PerimeterxTokenV1, 'Token v1 tests' do
#       it 'Should not pass on cookie expired' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "1:#{gen_token_v1(@params[:cookie_key],(Time.now.to_f*1000).floor - 100000,'u','v',0,0)}"

#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq false
#         expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::EXPIRED_COOKIE
#       end

#       it 'Should pass and cookie high score' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "1:#{gen_token_v1(@params[:cookie_key],(Time.now.to_f*1000).floor - 100000,'u','v',0,100)}"

#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq false
#         expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::EXPIRED_COOKIE
#       end

#       it 'Should not pass and validation failed' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "1:#{gen_token_v1(@params[:cookie_key],(Time.now.to_f*1000).floor + 100000,'u','v',0,0, 'kjdshfkjdsf')}"
#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq false
#         expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::COOKIE_VALIDATION_FAILED
#       end

#       it 'Should pass ok' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "1:#{gen_token_v1(@params[:cookie_key],(Time.now.to_f*1000).floor + 100000,'u','v',0,0)}"
#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq true
#         expect(px_ctx.context[:s2s_call_reason]).to eq nil

#       end
#     end

#     describe PxModule::PerimeterxTokenV3, 'Token v3 tests' do
#       it 'Should not pass on cookie expired' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "3:#{gen_token_v3(@params[:cookie_key],(Time.now.to_f*1000).floor - 100000,'u','v',100,'c')}"

#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq false
#         expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::EXPIRED_COOKIE
#       end

#       it 'Should pass and cookie high score' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "3:#{gen_token_v3(@params[:cookie_key],(Time.now.to_f*1000).floor + 20000,'u','v',100,'c')}"
#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq true
#         expect(px_ctx.context[:blocking_reason]).to eq PxModule::COOKIE_HIGH_SCORE
#       end

#       it 'Should not pass and cookie high score' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "3:#{gen_token_v3(@params[:cookie_key],(Time.now.to_f*1000).floor + 20000,'u','v',0,'c','sdfdsf')}"
#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq false
#         expect(px_ctx.context[:s2s_call_reason]).to eq PxModule::COOKIE_VALIDATION_FAILED
#       end

#       it 'Should pass ok' do
#         @req.headers["#{PxModule::TOKEN_HEADER}"] = "3:#{gen_token_v3(@params[:cookie_key],(Time.now.to_f*1000).floor + 20000,'u','v',0,'c')}"
#         config = PxModule::Configuration.new(@params).configuration
#         px_ctx = PxModule::PerimeterXContext.new(config, @req)
#         validator = PxModule::PerimeterxCookieValidator.new(config)

#         verified, px_ctx = validator.verify(px_ctx)
#         expect(verified).to eq true
#         expect(px_ctx.context[:s2s_call_reason]).to eq nil
#       end
#     end
#   end
# end