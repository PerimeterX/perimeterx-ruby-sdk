require "spec_helper"
require "base64"


RSpec.describe PxModule::PerimeterxCaptchaValidator, "Captcha Validator Tests" do
  before(:each) do
    @params = {
      :app_id => "PX_APP_ID",
      :cookie_key => "PX_COOKIE_KEY",
      :auth_token => "PX_AUTH_TOKEN"
    }
    @http_client = spy("http_client", :post => double("response", {:code => 200, :body => "{ status: 0 }", :success? => true } ))


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

  it "Should send received pxCaptcha as is and correspond to captcha_api v2" do
    pxCookie = Base64.encode64('c:v:u')
    @req.expects(:cookies).returns ({ :_pxCaptcha => pxCookie })

    config = PxModule::Configuration.new(@params).configuration
    px_ctx = PxModule::PerimeterXContext.new(config, @req)
    validator = PxModule::PerimeterxCaptchaValidator.new(config, @http_client)

    path = '/api/v2/risk/captcha'
    headers =  { "Authorization" => "Bearer PX_AUTH_TOKEN", "Content-Type" => "application/json" }
    captcha_api_post = {
        :request => {
            :ip => "1.2.3.4", :headers => [], :uri => "/", :captchaType => "reCaptcha"
        },
        :additional => {
            :module_version => "RUBY SDK v1.4.0"
        },
        :pxCaptcha => pxCookie,
        :hostname => "MockServer"
    }

    expect(@http_client).to receive(:post).with(path, captcha_api_post, headers, 1, nil)

    verified, px_ctx = validator.verify(px_ctx)
    expect(verified).to be(true)
  end

end
