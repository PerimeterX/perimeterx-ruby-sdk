class PerimeterX::Configuration

  attr_accessor :enable_module
  attr_accessor :captcha_enable
  attr_accessor :blocking_score
  attr_accessor :ip_header
  attr_accessor :report_page_activities
  attr_accessor :sensetive_headers
  attr_accessor :app_id
  attr_accessor :cookie_secret_key
  attr_accessor :auth_token
  attr_accessor :proxy_url
  attr_accessor :max_buffer_length
  attr_accessor :custom_logo
  attr_accessor :css_ref
  attr_accessor :js_ref

  def initialize(params)
    @enable_module = configuration_overriding(params, 'enable_module', true )
    @captcha_enable = configuration_overriding(params, 'captcha_enable', true )
    @blocking_score = configuration_overriding(params, 'blocking_score', 70 )
    @ip_header = configuration_overriding(params, ip_header,'px-user-ip')
    @report_page_activities = configuration_overriding(params, 'report_page_activities', true)
    @sensetive_headers = configuration_overriding(params, 'sensetive_headers',['cookie', 'cookies'])
    @max_buffer_length = 30
  end

  def configuration_overriding(params, param_name, defualt_value)
    ret = defualt_value
    if params.key?(param_name) then
      ret = params[param_name]
    end
    return ret
  end

end
