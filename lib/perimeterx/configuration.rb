class PerimeterX::Configuration

  attr_accessor :configuration
  attr_accessor :PX_DEFAULT
  attr_accessor :MONITOR_MODE
  attr_accessor :ACTIVE_MODE

  MONITOR_MODE = 1
  ACTIVE_MODE = 2

  PX_DEFAULT = {
    "app_id"                   => nil,
    "cookie_key"               => nil,
    "auth_token"               => nil,
    "module_enabled"           => true,
    "captcha_enabled"          => true,
    "challenge_enabled"        => true,
    "encryption_enabled"       => true,
    "blocking_score"           => 70,
    "sensitive_headers"        => ['cookie', 'cookies'],
    "api_connect_timeout"      => 0,
    "api_timeout"              => 0,
    "max_buffer_len"           => 1,
    "send_page_activities"     => false,
    "send_block_activities"    => true,
    "sdk_name"                 => "RUBY SDK v1.0.0",
    "debug_mode"               => false,
    "module_mode"              => MONITOR_MODE,
    "api_timeout"              => 1,
    "perimeterx_server_host"   => "https://sapi.perimeterx.net",
    "api_connect_timeout"      => 1,
    "local_proxy"              => false
  }


  def initialize(params)
    @configuration = PX_DEFAULT.merge(params);
  end

end
