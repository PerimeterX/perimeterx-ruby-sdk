require "spec_helper"


RSpec.describe PxModule::PerimeterxCaptchaValidator, 'Remote configuration test' do

  before(:each) do
    params = {
        :app_id => "PX_APP_ID",
        :cookie_key => "PX_COOKIE_KEY",
        :auth_token => "PX_AUTH_TOKEN"
    }
    @config = PxModule::Configuration.new(params).configuration
  end

  it 'Should run get_configuratoin_from_server and update configuration' do
    body = '{"moduleEnabled":false,"cookieKey":"cookie_key","blockingScore":60,"appId":"app_id","moduleMode":"monitoring","ipHeaders":["X-PX-TRUE-IP"],"sensitiveHeaders":["X-PX-SENSITIVE-HEADER"],"connectTimeout":3,"riskTimeout":3,"debugMode":false,"checksum":"1234567890abcdefg"}'

    http_client = get_http_client(body,200)
    remote_config = PxModule::PerimeterxRemoteConfiguration.new(@config, http_client)
    remote_config.get_configuration_from_server()

    expect(@config[:module_enabled]).to eq false
    expect(@config[:cookie_key]).to eq 'cookie_key'
    expect(@config[:blocking_score]).to eq 60
    expect(@config[:app_id]).to eq 'app_id'
    expect(@config[:module_mode]).to eq PxModule::MONITOR_MODE
    expect(@config[:ip_headers]).to eq ['X-PX-TRUE-IP']
    expect(@config[:sensitive_headers]).to eq ['X-PX-SENSITIVE-HEADER']
    expect(@config[:api_connect_timeout]).to eq 3
    expect(@config[:api_timeout]).to eq 3
    expect(@config[:checksum]).to eq '1234567890abcdefg'

  end

  it 'Should run and fail to get_configuratoin_from_server but set perimeterx to disable' do
    body = ''
    http_client = get_http_client(body,500)
    remote_config = PxModule::PerimeterxRemoteConfiguration.new(@config, http_client)
    remote_config.get_configuration_from_server()

    expect(@config[:module_enabled]).to eq false
  end

  it 'Should run and fail to get_configuratoin_from_server but not set perimeterx to disable' do
    @config[:checksum] = 'test_checksum'
    body = ''
    http_client = get_http_client(body,500)
    remote_config = PxModule::PerimeterxRemoteConfiguration.new(@config, http_client)
    remote_config.get_configuration_from_server()

    expect(@config[:module_enabled]).to eq true
  end

  it 'Should run and  get configuratoin from server but not update configuration' do
    @config[:checksum] = 'test_checksum'
    body = ''
    http_client = get_http_client(body,204)
    remote_config = PxModule::PerimeterxRemoteConfiguration.new(@config, http_client)
    remote_config.get_configuration_from_server()

    expect(@config[:module_enabled]).to eq true
    expect(@config[:cookie_key]).to eq 'PX_COOKIE_KEY'
    expect(@config[:app_id]).to eq 'PX_APP_ID'
    expect(@config[:auth_token]).to eq 'PX_AUTH_TOKEN'
  end

  def get_http_client(body, code)
    double_response_obj = double('double_response_obj',{
      :code => code,
      :body => body
    })

    double('double_http_client', {
        :get => double_response_obj,
        :post => double_response_obj
    })
  end

end