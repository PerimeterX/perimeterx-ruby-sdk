
require 'perimeterx/utils/px_constants'
module PxModule
  class Configuration

    attr_accessor :configuration
    attr_accessor :PX_DEFAULT

    PX_DEFAULT = {
      :app_id                   => nil,
      :cookie_key               => nil,
      :auth_token               => nil,
      :module_enabled           => true,
      :captcha_enabled          => true,
      :challenge_enabled        => true,
      :encryption_enabled       => true,
      :blocking_score           => 70,
      :sensitive_headers        => ["http-cookie", "http-cookies"],
      :api_connect_timeout      => 0,
      :api_timeout              => 0,
      :max_buffer_len           => 30,
      :send_page_activities     => false,
      :send_block_activities    => true,
      :sdk_name                 => PxModule::SDK_NAME,
      :debug_mode               => false,
      :module_mode              => PxModule::ACTIVE_MODE,
      :local_proxy              => false
    }

    def initialize(params)
      PX_DEFAULT[:perimeterx_server_host] = "https://sapi-#{params[:app_id].downcase}.perimeterx.net"
      @configuration = PX_DEFAULT.merge(params);
    end
  end
end
