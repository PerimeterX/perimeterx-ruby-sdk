require 'perimeterx/utils/px_logger'
require 'perimeterx/utils/px_constants'

module PxModule
  class PerimeterXContext

    attr_accessor :context
    attr_accessor :px_config
    
    # class methods

    def self.extract_ip(req, px_config)
      # Get IP from header/custom function
      if px_config[:ip_headers].length() > 0
        px_config[:ip_headers].each do |ip_header|
          if req.headers[ip_header]
            return PerimeterXContext.force_utf8(req.headers[ip_header])
          end
        end
      elsif px_config[:ip_header_function] != nil
        return px_config[:ip_header_function].call(req) 
      end      
      return req.ip
    end

    def self.force_utf8(str)
      return str.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    end

    # instance methods

    def initialize(px_config, req)
      @logger = px_config[:logger]
      @logger.debug('PerimeterXContext[initialize]')
      @context = Hash.new

      @context[:px_cookie] = Hash.new
      @context[:headers] = Hash.new
      @context[:cookie_origin] = 'cookie'
      @context[:made_s2s_risk_api_call] = false
      @context[:first_party_enabled] = px_config[:first_party_enabled]
      
      cookies = req.cookies

      @context[:ip] = PerimeterXContext.extract_ip(req, px_config)

      # Get token from header
      if req.headers[PxModule::TOKEN_HEADER]
        @context[:cookie_origin] = 'header'
        token = PerimeterXContext.force_utf8(req.headers[PxModule::TOKEN_HEADER])
        if token.match(PxModule::MOBILE_TOKEN_V3_REGEX)
          @context[:px_cookie][:v3] = token[2..-1]
        elsif token.match(PxModule::MOBILE_ERROR_REGEX)
          @context[:mobile_error] = token
          if req.headers[PxModule::ORIGINAL_TOKEN_HEADER]
            token = PerimeterXContext.force_utf8(req.headers[PxModule::ORIGINAL_TOKEN_HEADER])
            if token.match(PxModule::MOBILE_TOKEN_V3_REGEX)
              @context[:px_cookie][:v3] = token[2..-1]
            end
          end
        end
      elsif !cookies.empty? # Get cookie from jar
        # Prepare hashed cookies
        cookies.each do |k, v|
          case k.to_s
            when '_px3'
              @context[:px_cookie][:v3] = PerimeterXContext.force_utf8(v)
            when '_px'
              @context[:px_cookie][:v1] = PerimeterXContext.force_utf8(v)
            when '_pxvid'
              if v.is_a?(String) && v.match(PxModule::VID_REGEX)
                @context[:vid_source] = "vid_cookie"
                @context[:vid] = PerimeterXContext.force_utf8(v)
              end
          end
        end #end case
      end #end empty cookies

      req.headers.each do |k, v|
        if (k.start_with? 'HTTP_')
          header = k.to_s.gsub('HTTP_', '')
          header = header.gsub('_', '-').downcase
          @context[:headers][header.to_sym] = PerimeterXContext.force_utf8(v)
        end
      end #end headers foreach
      
      @context[:hostname]= req.server_name
      @context[:user_agent] = req.user_agent ? req.user_agent : ''
      @context[:uri] = px_config[:custom_uri] ? px_config[:custom_uri].call(req)  : req.fullpath 
      @context[:full_url] = req.original_url
      @context[:format] = req.format.symbol
      @context[:score] = 0

      if req.server_protocol
          httpVer = req.server_protocol.split('/')
          if httpVer.size > 0
              @context[:http_version] = httpVer[1]
          end
      end
      @context[:http_method] = req.method
	  @context[:sensitive_route] = check_sensitive_route(px_config[:sensitive_routes], @context[:uri]) 
    end #end init

	def check_sensitive_route(sensitive_routes, uri)
		sensitive_routes.each do |sensitive_route|
			return true if uri.start_with? sensitive_route
		end
    false
	end

    def set_block_action_type(action)
      @context[:block_action] = case action
        when 'c'
          'captcha'
        when 'b'
          return 'block'
        when 'j'
          return 'challenge'
        when 'r'
          return 'rate_limit'
        else
          return captcha
        end
    end

    def get_px_cookie
      cookie = @context[:px_cookie].key?(:v3) ? @context[:px_cookie][:v3] : @context[:px_cookie][:v1]
      return cookie.tr(' ','+') if !cookie.nil?
    end

  end
end
