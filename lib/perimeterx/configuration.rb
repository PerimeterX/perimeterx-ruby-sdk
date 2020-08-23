require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_constants'

module PxModule
  class Configuration
    @@basic_config = nil
    @@mutex = Mutex.new

    attr_accessor :configuration

    PX_DEFAULT = {
      :app_id                       => nil,
      :cookie_key                   => nil,
      :auth_token                   => nil,
      :module_enabled               => true,
      :challenge_enabled            => true,
      :encryption_enabled           => true,
      :blocking_score               => 100,
      :sensitive_headers            => ["http-cookie", "http-cookies"],
      :api_connect_timeout          => 1,
      :api_timeout                  => 1,
      :max_buffer_len               => 10,
      :send_page_activities         => true,
      :send_block_activities        => true,
      :sdk_name                     => PxModule::SDK_NAME,
      :debug                        => false,
      :module_mode                  => PxModule::MONITOR_MODE,
      :local_proxy                  => false,
      :sensitive_routes             => [],
      :whitelist_routes             => [],
      :ip_headers                   => [],
      :ip_header_function           => nil,
      :bypass_monitor_header        => nil,
      :risk_cookie_max_iterations   => 5000
    }

    def self.set_basic_config(basic_config)
      if @@basic_config.nil?
        @@mutex.synchronize {          
          @@basic_config = PX_DEFAULT.merge(basic_config)
      }
      end
    end

    def initialize(params)
      if ! @@basic_config.is_a?(Hash)
        raise Exception.new('Please initialize PerimeterX first')
      end
      @configuration = @@basic_config.merge(params)
      @configuration[:backend_url] = "https://sapi-#{params[:app_id].downcase}.perimeterx.net"
      @configuration[:logger] = PxLogger.new(@configuration[:debug])
    end
  end
end
