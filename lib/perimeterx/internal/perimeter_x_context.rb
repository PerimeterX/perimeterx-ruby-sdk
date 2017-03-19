require 'perimeterx/utils/px_logger'

class PerimeterXContext
  L = PxLogger.instance

  attr_accessor :px_cookies
  attr_accessor :px_captcha
  attr_accessor :start_time
  attr_accessor :headers
  attr_accessor :px_config
  attr_accessor :hostname
  attr_accessor :user_agent
  attr_accessor :uri
  attr_accessor :full_url

  def initialize(px_config, req)
    L.info("PerimeterXContext: initialize")

    @px_config = px_config
    @px_cookies = Hash.new
    @headers = Hash.new
    cookies = req.cookies
    if (!cookies.empty?)
      # Prepare hashed cookies
      cookies.each do |k,v|
        case k
          when"_px3"
            @px_cookies[:v3] = v
          when "_px"
            @px_cookies[:v1] = v
          when "_pxCaptcha"
            @px_captcha = v
        end
      end #end case
    end#end empty cookies

    @start_time = Time.now
    req.headers.each do |k,v|
      if(k.start_with? "HTTP_")
        header = k.gsub("_","-").downcase
        @headers[header] = v
      end
    end#end headers foreach

    @hostname = req.headers['HTTP_HOST']
    @user_agent = req.headers['HTTP_USER_AGENT'] ? req.headers['HTTP_USER_AGENT'] : ''
    @uri = px_config.custom_uri ? px_config.custom_uri : req.headers['REQUEST_URI']
    @full_url = self_url(req)

  end #end init

  def self_url(req)

  end

  private :self_url

end #end class
