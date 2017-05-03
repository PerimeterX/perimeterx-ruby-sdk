require 'perimeterx/utils/px_logger'

module PxModule
  class PerimeterXContext

    attr_accessor :context
    attr_accessor :px_config

    def initialize(px_config, req)
      @logger = px_config[:logger];
      @logger.debug("PerimeterXContext[initialize] ")
      @context = Hash.new

      @context[:px_cookie] = Hash.new
      @context[:headers] = Hash.new
      cookies = req.cookies
      if (!cookies.empty?)
        # Prepare hashed cookies
        cookies.each do |k, v|
          case k.to_s
            when "_px3"
              @context[:px_cookie][:v3] = v
            when "_px"
              @context[:px_cookie][:v1] = v
            when "_pxCaptcha"
              @context[:px_captcha] = v
          end
        end #end case
      end #end empty cookies

      req.headers.each do |k, v|
        if (k.start_with? "HTTP_")
          header = k.to_s.gsub("HTTP_", "")
          header = header.gsub("_", "-").downcase
          @context[:headers][header.to_sym] = v
        end
      end #end headers foreach

      @context[:hostname]= req.server_name
      @context[:user_agent] = req.user_agent ? req.user_agent : ''
      @context[:uri] = px_config[:custom_uri] ? px_config[:custom_uri].call(req)  : req.headers['REQUEST_URI']
      @context[:full_url] = req.original_url
      @context[:format] = req.format
      @context[:score] = 0

      if px_config.key?(:custom_user_ip)
        @context[:ip] = req.headers[px_config[:custom_user_ip]]
      elsif px_config.key?(:px_custom_user_ip_method)
        @context[:ip] = px_config[:px_custom_user_ip_method].call(req)
      else
        @context[:ip] = req.ip
      end

      if req.server_protocol
          httpVer = req.server_protocol.split("/")
          if httpVer.size > 0
              @context[:http_version] = httpVer[1];
          end
      end
      @context[:http_method] = req.method

    end #end init

    def set_block_action_type(action)
      @context[:block_action] = case action
        when "c"
          "captcha"
        when "b"
          return "block"
        when "j"
          return "challenge"
        else
          return "captcha"
        end
    end

    def get_px_cookie
      cookie = @context[:px_cookie].key?(:v3) ? @context[:px_cookie][:v3] : @context[:px_cookie][:v1]
      return cookie.tr(' ','+') if !cookie.nil?
    end

  end
end
