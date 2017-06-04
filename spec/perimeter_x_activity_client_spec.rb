require "spec_helper"


RSpec.describe PxModule::PerimeterxCaptchaValidator, "Captcha Validator Tests" do
  before(:each) do
    @params = {
      :app_id => "PX_APP_ID",
      :cookie_key => "PX_COOKIE_KEY",
      :auth_token => "PX_AUTH_TOKEN"
    }
    @http_client = double("http_client", :post => double("response", {:status_code => 200, :body => "{ status: 0 }" } ) )

    @req = double("http_request", {
      :cookies => Hash.new,
      :headers => Hash.new,
      :server_name => "MockServer",
      :user_agent => "MockUserAgent",
      :original_url => "http://moch.url.com/",
	  :fullpath => '/',
	  :format => double("format", { :symbol => nil } ),
      :ip => "1.2.3.4",
      :server_protocol => "HTTP://1.1",
      :method => "GET"
      })
  end


  it "send should return false on captcha_enabled is false" do
    @params[:captcha_enabled] = false
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCaptchaValidator.new(config, @http_client)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to be(false)
  end

  it "send should return false on captcha_enabled is false" do
    @req.expects(:cookies).returns({ "_pxCaptcha": "c:v:u" })
    config = PxModule::Configuration.new(@params).configuration;
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCaptchaValidator.new(config, @http_client)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to be(true)
  end


end
