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
      :challenge_enabled        => true,
      :encryption_enabled       => true,
      :blocking_score           => 100,
      :sensitive_headers        => ["http-cookie", "http-cookies"],
      :api_connect_timeout      => 1,
      :api_timeout              => 1,
      :max_buffer_len           => 10,
      :send_page_activities     => true,
      :send_block_activities    => true,
      :sdk_name                 => PxModule::SDK_NAME,
      :debug                    => false,
      :module_mode              => PxModule::MONITOR_MODE,
      :local_proxy              => false,
      :sensitive_routes         => [],
      :whitelist_routes         => [],
      :ip_headers               => [],
      :ip_header_function       => nil,
      :bypass_monitor_header    => nil
    }

    def initialize(params)
      PX_DEFAULT[:perimeterx_server_host] = "https://sapi-#{params[:app_id].downcase}.perimeterx.net"
      @configuration = PX_DEFAULT.merge(params)
      @configuration[:logger] = PxLogger.new(@configuration[:debug])
    end
  end
end
