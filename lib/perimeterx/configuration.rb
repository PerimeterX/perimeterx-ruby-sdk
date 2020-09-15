require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_constants'
require 'perimeterx/internal/validators/hash_schema_validator'

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
      :api_timeout_connection       => 1,
      :api_timeout                  => 1,
      :send_page_activities         => true,
      :send_block_activities        => true,
      :sdk_name                     => PxModule::SDK_NAME,
      :debug                        => false,
      :module_mode                  => PxModule::MONITOR_MODE,
      :sensitive_routes             => [],
      :whitelist_routes             => [],
      :ip_headers                   => [],
      :ip_header_function           => nil,
      :bypass_monitor_header        => nil,
      :risk_cookie_max_iterations   => 5000,
      :first_party_enabled          => true
    }

    CONFIG_SCHEMA = {
      :app_id                       => {types: [String], required: true},
      :cookie_key                   => {types: [String], required: true},
      :auth_token                   => {types: [String], required: true},
      :module_enabled               => {types: [FalseClass, TrueClass], required: false},
      :challenge_enabled            => {types: [FalseClass, TrueClass], required: false},
      :encryption_enabled           => {types: [FalseClass, TrueClass], required: false},
      :blocking_score               => {types: [Integer], required: false},
      :sensitive_headers            => {types: [Array], allowed_element_types: [String], required: false},
      :api_timeout_connection       => {types: [Integer, Float], required: false},
      :api_timeout                  => {types: [Integer, Float], required: false},
      :send_page_activities         => {types: [FalseClass, TrueClass], required: false},
      :send_block_activities        => {types: [FalseClass, TrueClass], required: false},
      :sdk_name                     => {types: [String], required: false},
      :debug                        => {types: [FalseClass, TrueClass], required: false},
      :module_mode                  => {types: [Integer], required: false},
      :sensitive_routes             => {types: [Array], allowed_element_types: [String], required: false},
      :whitelist_routes             => {types: [Array], allowed_element_types: [String, Regexp], required: false},
      :ip_headers                   => {types: [Array], allowed_element_types: [String], required: false},
      :ip_header_function           => {types: [Proc], required: false},
      :bypass_monitor_header        => {types: [FalseClass, TrueClass], required: false},
      :risk_cookie_max_iterations   => {types: [Integer], required: false},
      :custom_verification_handler  => {types: [Proc], required: false},
      :additional_activity_handler  => {types: [Proc], required: false},
      :custom_logo                  => {types: [String], required: false},
      :css_ref                      => {types: [String], required: false},
      :js_ref                       => {types: [String], required: false},
      :custom_uri                   => {types: [Proc], required: false},
      :first_party_enabled          => {types: [FalseClass, TrueClass], required: false}

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
        raise PxConfigurationException.new('PerimeterX: Please initialize PerimeterX first')
      end
      
      # merge request configuration into the basic configuration
      @configuration = @@basic_config.merge(params)
      validate_hash_schema(@configuration, CONFIG_SCHEMA)
      
      @configuration[:backend_url] = "https://sapi-#{@configuration[:app_id].downcase}.perimeterx.net"
      @configuration[:logger] = PxLogger.new(@configuration[:debug])
    end
  end
end
