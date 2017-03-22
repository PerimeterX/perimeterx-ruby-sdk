module PerimeterX
  class Configuration

    attr_accessor :configuration
    attr_accessor :PX_DEFAULT
    attr_accessor :MONITOR_MODE
    attr_accessor :ACTIVE_MODE

    MONITOR_MODE = 1
    ACTIVE_MODE = 2

    PX_DEFAULT = {
      "app_id"                   => nil,
      "auth_token"               => nil,
      "module_enabled"           => true,
      "blocking_score"           => 70,
      "sensitive_headers"        => ["cookie", "cookies"],
      "api_connect_timeout"      => 1,
      "api_timeout"              => 1,
      "sdk_name"                 => "RUBY SLIM SDK v1.0.0",
      "debug_mode"               => false,
      "module_mode"              => MONITOR_MODE,
    }

    def initialize(params)
      PX_DEFAULT["perimeterx_server_host"] = "https://sapi-#{params['app_id'].downcase}.perimeterx.net"
      @configuration = PX_DEFAULT.merge(params);
    end
  end
end
