class PerimeterX::Configuration

  attr_accessor :configuration
  attr_accessor :PX_DEFAULT

  PX_DEFAULT = {
    "app_id"                   => nil,
    "cookie_key"               => nil,
    "auth_token"               => nil,
    "module_enabled"           => true,
    "captcha_enabled"          => true,
    "challenge_enabled"        => true,
    "encryption_enabled"       => true,
    "blocking_score"           => 70,
    "sensitive_header"         => ['cookie', 'cookies'],
    "max_buffer_len"           => 1,
    "send_page_activities"     => false,
    "send_block_activities"    => true,
    "sdk_name"                 => 'RUBY SDK v1.0.0',
    "debug_mode"               => false,
    "api_timeout"              => 1,
    "api_connect_timeout"      => 1,
    "local_proxy"              => false
  }

  # 'perimeterx_server_host' = 'https://sapi-' . strtolower($pxConfig['app_id']) . '.perimeterx.net',

  def initialize(params)
    @configuration = PX_DEFAULT.merge(params);
  end

end
