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
  attr_accessor :score
  attr_accessor :ip
  attr_accessor :http_version

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
    @uri = px_config[:custom_uri] ? px_config[:custom_uri]  : req.headers['REQUEST_URI']
    @full_url = self_url(req)
    @score = 0

    if px_config[:custom_user_ip]
      @ip = px_config[:custom_user_ip]
      #TODO: Custom function ip, php example: call_user_func('pxCustomUserIP', $this);
    else
      @ip = req.headers['REMOTE_ADDR'];
    end

    if req.headers['SERVER_PROTOCOL']
        httpVer = req.headers['SERVER_PROTOCOL'].split("/")
        if httpVer.size > 0
            @http_version = httpVer[1];
        end
    end
    @http_method = req.headers['REQUEST_METHOD'];

  end #end init

  def self_url(req)
    s = req.headers['HTTPS'] && req.headers['HTTPS'] == on ? "s" : "" #check if HTTPS or HTTP
    l = req.headers['SERVER_PROTOCOL'].downcase #get protocol and downcase it
    protocol = "#{l[0,l.index('/')]}#{s}#{l[(l.index('/') ),l.size]}" #concat http{s}:/x.y
    port = (req.headers["SERVER_PORT"] != "80") ? ":#{req.headers["SERVER_PORT"]}" : ""
    return "#{l}://#{req.headers['HTTP_HOST']}#{port}#{@uri}" #concant str
  end

  private :self_url

end #end class
