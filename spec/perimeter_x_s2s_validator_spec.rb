# require "spec_helper"


# RSpec.describe PxModule::PerimeterxS2SValidator, "S2S Validator Tests" do
#   before(:each) do
#     @params = {
#       :app_id => "PX_APP_ID",
#       :cookie_key => "PX_COOKIE_KEY",
#       :auth_token => "PX_AUTH_TOKEN"
#     }
#     @http_client = double("http_client")

#     @req = double("http_request", {
#       :cookies => Hash.new,
#       :headers => Hash.new,
#       :server_name => "MockServer",
#       :user_agent => "MockUserAgent",
#       :original_url => "http://moch.url.com/",
#       :fullpath => '/',
#       :format => double("format", { :symbol => nil } ),
#       :ip => "1.2.3.4",
#       :server_protocol => "HTTP://1.1",
#       :method => "GET"
#       })
#   end


#   # it "pass request because sending failed" do
#   #   @http_client.expects(:post).returns(nil)
#   #   config = PxModule::Configuration.new(@params).configuration;
#   #   px_ctx = PxModule::PerimeterXContext.new(config, @req)
#   #   validator = PxModule::PerimeterxS2SValidator.new(config, @http_client)

#   #   px_ctx = validator.verify(px_ctx)
#   #   expect(px_ctx).to eq px_ctx
#   # end

#   # it "ctx will contain block_action from captcha type" do
#   #   @http_client.expects(:post).returns( double("response", {:code => 200 ,:body  => "{ score: 69, uuid: 'uuid', action: 'c' }"}) )
#   #   config = PxModule::Configuration.new(@params).configuration;
#   #   px_ctx = PxModule::PerimeterXContext.new(config, @req)
#   #   validator = PxModule::PerimeterxS2SValidator.new(config, @http_client)
#   #   expect(px_ctx.context[:block_action]).to be_nil

#   #   px_ctx = validator.verify(px_ctx)
#   #   expect(px_ctx.context[:block_action]).to eq "captcha"
#   # end

#   # it "ctx will contain block_action from block type" do
#   #   @http_client.expects(:post).returns( double("response", {:code => 200 ,:body  => "{ score: 69, uuid: 'uuid', action: 'b' }"}) )
#   #   config = PxModule::Configuration.new(@params).configuration;
#   #   px_ctx = PxModule::PerimeterXContext.new(config, @req)
#   #   validator = PxModule::PerimeterxS2SValidator.new(config, @http_client)
#   #   expect(px_ctx.context[:block_action]).to be_nil

#   #   px_ctx = validator.verify(px_ctx)
#   #   expect(px_ctx.context[:block_action]).to eq "block"
#   #   expect(px_ctx.context[:blocking_reason]).to be_nil
#   # end

#   # it "ctx will contain block_action from block type and blocking_reason should s2s_high_score" do
#   #   @http_client.expects(:post).returns( double("response", {:code => 200 ,:body  => "{ score: 71, uuid: 'uuid', action: 'b' }"}) )
#   #   config = PxModule::Configuration.new(@params).configuration;
#   #   px_ctx = PxModule::PerimeterXContext.new(config, @req)
#   #   validator = PxModule::PerimeterxS2SValidator.new(config, @http_client)
#   #   expect(px_ctx.context[:block_action]).to be_nil

#   #   px_ctx = validator.verify(px_ctx)
#   #   expect(px_ctx.context[:block_action]).to eq "block"
#   #   expect(px_ctx.context[:blocking_reason]).to eq "s2s_high_score"
#   # end

#   # it "ctx will contain block_action from block type and blocking_reason should be empty" do
#   #   @http_client.expects(:post).returns( double("response", {:code => 200 ,:body  => "{ score: 69, uuid: 'uuid', action: 'b' }"}) )
#   #   config = PxModule::Configuration.new(@params).configuration;
#   #   px_ctx = PxModule::PerimeterXContext.new(config, @req)
#   #   validator = PxModule::PerimeterxS2SValidator.new(config, @http_client)
#   #   expect(px_ctx.context[:block_action]).to be_nil

#   #   px_ctx = validator.verify(px_ctx)
#   #   expect(px_ctx.context[:block_action]).to eq "block"
#   #   expect(px_ctx.context[:blocking_reason]).to be_nil
#   # end

#   # it "ctx will contain block_action from challange type and have block block_action_data" do
#   #   @http_client.expects(:post).returns( double("response", {:code => 200 ,:body  => "{ score: 69, uuid: 'uuid', action: 'j', action_data: { body: 'challange_body' } }" } ) )
#   #   config = PxModule::Configuration.new(@params).configuration;
#   #   px_ctx = PxModule::PerimeterXContext.new(config, @req)
#   #   validator = PxModule::PerimeterxS2SValidator.new(config, @http_client)
#   #   expect(px_ctx.context[:block_action]).to be_nil

#   #   px_ctx = validator.verify(px_ctx)
#   #   expect(px_ctx.context[:block_action]).to eq 'challenge'
#   #   expect(px_ctx.context[:block_action_data]).not_to be_nil
#   # end



# end
