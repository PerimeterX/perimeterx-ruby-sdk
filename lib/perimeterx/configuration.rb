require 'perimeterx/utils/px_logger'
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
      :remote_config_interval   => 60,
      :remote_config_enabled    => false,
      :sensitive_headers        => ["http-cookie", "http-cookies"],
      :ip_headers               => [],
      :api_connect_timeout      => 1,
      :api_timeout              => 1,
      :max_buffer_len           => 10,
      :checksum                 => nil,
      :send_page_activities     => false,
      :send_block_activities    => true,
      :sdk_name                 => PxModule::SDK_NAME,
      :debug                    => true,
      :module_mode              => PxModule::ACTIVE_MODE,
      :local_proxy              => false,
      :sensitive_routes         => []
    }

    def initialize(params)
      PX_DEFAULT[:perimeterx_server_host] = "https://sapi-#{params[:app_id].downcase}.perimeterx.net"
      @configuration = PX_DEFAULT.merge(params)
      @configuration[:logger] = PxLogger.new(@configuration[:debug])
    end
  end
end
