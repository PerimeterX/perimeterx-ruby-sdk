require "spec_helper"

RSpec.describe PxModule::Configuration, "User Configuration verification" do
  before(:each) do
    @params = {
      :app_id => "PX_APP_ID",
      :cookie_key => "PX_COOKIE_KEY",
      :auth_token => "PX_AUTH_TOKEN"
    }
  end

  context "Validating defualt values and override values" do
    it "should validate default values" do
      config = PxModule::Configuration.new(@params).configuration

      expect(config[:module_enabled]).to eq true
      expect(config[:challenge_enabled]).to eq true
      expect(config[:encryption_enabled]).to eq true
      expect(config[:blocking_score]).to eq 100
      expect(config[:sensitive_headers]).to eq ["http-cookie", "http-cookies"]
      expect(config[:api_timeout_connection]).to eq 1
      expect(config[:api_timeout]).to eq 1
      expect(config[:max_buffer_len]).to eq 10
      expect(config[:send_page_activities]).to eq true
      expect(config[:send_block_activities]).to eq true
      expect(config[:debug]).to eq false
      expect(config[:module_mode]).to eq PxModule::MONITOR_MODE
      expect(config[:local_proxy]).to eq false
    end

    it "should overide default values" do
      @params[:module_enabled] = false
      @params[:challenge_enabled] = false
      @params[:encryption_enabled] = false
      @params[:blocking_score] = 100
      @params[:sensitive_headers] = ["http-cookie", "http-cookies","http-px"]
      @params[:api_timeout_connection] = 1
      @params[:api_timeout] = 1
      @params[:max_buffer_len] = 1
      @params[:send_page_activities] = true
      @params[:send_block_activities] = false
      @params[:debug] = true
      @params[:module_mode] = PxModule::MONITOR_MODE
      @params[:local_proxy] = true

      config = PxModule::Configuration.new(@params).configuration

      expect(config[:module_enabled]).to eq false
      expect(config[:challenge_enabled]).to eq false
      expect(config[:encryption_enabled]).to eq false
      expect(config[:blocking_score]).to eq 100
      expect(config[:sensitive_headers]).to eq ["http-cookie", "http-cookies","http-px"]
      expect(config[:api_timeout_connection]).to eq 1
      expect(config[:api_timeout]).to eq 1
      expect(config[:max_buffer_len]).to eq 1
      expect(config[:send_page_activities]).to eq true
      expect(config[:send_block_activities]).to eq false
      expect(config[:debug]).to eq true
      expect(config[:module_mode]).to eq PxModule::MONITOR_MODE
      expect(config[:local_proxy]).to eq true
    end
  end

end
