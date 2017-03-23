require 'perimeterx/utils/px_logger'

class PerimeterXContext
  L = PxLogger.instance

  attr_accessor :context
  attr_accessor :px_config

  def initialize(px_config, req)
    L.debug("PerimeterXContext[initialize] ")
    @context = Hash.new

    @context[:px_cookie] = Hash.new
    @context[:headers] = Hash.new
    cookies = req.cookies
    if (!cookies.empty?)
      # Prepare hashed cookies
      cookies.each do |k,v|
        case k.to_s
          when "_px3"
            @context[:px_cookie][:v3] = v
          when "_px"
            @context[:px_cookie][:v1] = v
          when "_pxCaptcha"
            @context[:px_captcha] = v
        end
      end #end case
    end#end empty cookies

    req.headers.each do |k,v|
      if(k.start_with? "HTTP_")
        header = k.to_s.gsub("HTTP_","")
        header = header.gsub("_","-").downcase
        @context[:headers][header.to_sym] = v
      end
    end#end headers foreach

    @context[:hostname]= req.headers['HTTP_HOST']
    @context[:user_agent] = req.headers['HTTP_USER_AGENT'] ? req.headers['HTTP_USER_AGENT'] : ''
    @context[:uri] = px_config[:custom_uri] ? px_config[:custom_uri]  : req.headers['REQUEST_URI']
    @context[:full_url] = self_url(req)
    @context[:score] = 0

    if px_config.key?(:custom_user_ip)
      @context[:ip] = px_config[:custom_user_ip]
    elsif px_config.key?(:px_custom_user_ip_method)
      @context[:ip] = px_config[:px_custom_user_ip_method].call(req)
    else
      @context[:ip] = req.headers['REMOTE_ADDR'];
    end

    if req.headers['SERVER_PROTOCOL']
        httpVer = req.headers['SERVER_PROTOCOL'].split("/")
        if httpVer.size > 0
            @context[:http_version] = httpVer[1];
        end
    end
    @context[:http_method] = req.headers['REQUEST_METHOD'];

  end #end init


  def get_px_cookie
    return @context[:px_cookie].key(:v3) ? @context[:px_cookie][:v3] : @context[:px_cookie][:v1]
  end

  def self_url(req)
    s = req.headers.key?('HTTPS') && req.headers['HTTPS'] == "on" ? "s" : "" #check if HTTPS or HTTP
    l = req.headers['SERVER_PROTOCOL'].downcase #get protocol and downcase it
    protocol = "#{l[0,l.index('/')]}#{s}#{l[(l.index('/') ),l.size]}" #concat http{s}:/x.y
    port = (req.headers["SERVER_PORT"] != "80") ? ":#{req.headers["SERVER_PORT"]}" : ""
    return "#{l}://#{req.headers['HTTP_HOST']}#{@uri}" #concant str
  end

  private :self_url
end
