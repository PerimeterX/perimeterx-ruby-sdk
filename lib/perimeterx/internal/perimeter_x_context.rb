require 'perimeterx/utils/px_logger'

module PxModule
  class PerimeterXContext

    attr_accessor :context
    attr_accessor :px_config

    def initialize(px_config, req)
      @logger = px_config[:logger]
      @logger.debug('PerimeterXContext[initialize]')
      @context = Hash.new

      @context[:px_cookie] = Hash.new
      @context[:headers] = Hash.new
      @context[:cookie_origin] = 'cookie'
      @context[:made_s2s_risk_api_call] = false
      cookies = req.cookies

      # Get token from header
      if req.headers[PxModule::TOKEN_HEADER]
        @context[:cookie_origin] = 'header'
        token = req.headers[PxModule::TOKEN_HEADER]
        if token.include? ':'
          exploded_token = token.split(':', 2)
          cookie_sym = "v#{exploded_token[0]}".to_sym
          @context[:px_cookie][cookie_sym] = exploded_token[1]
        else  # TOKEN_HEADER exists yet there's no ':' delimiter - may indicate an error (storing original value)
          # TODO FIXME :px_cookie is expected to be a hash everywhere else; this will eventually raise an exception
          @context[:px_cookie] = req.headers[PxModule::TOKEN_HEADER]
        end
      elsif !cookies.empty? # Get cookie from jar
        # Prepare hashed cookies
        cookies.each do |k, v|
          case k.to_s
            when '_px3'
              @context[:px_cookie][:v3] = v
            when '_px'
              @context[:px_cookie][:v1] = v
            when '_pxCaptcha'
              @context[:px_captcha] = v
          end
        end #end case
      end #end empty cookies

      req.headers.each do |k, v|
        if (k.start_with? 'HTTP_')
          header = k.to_s.gsub('HTTP_', '')
          header = header.gsub('_', '-').downcase
          @context[:headers][header.to_sym] = v
        end
      end #end headers foreach

      @context[:hostname]= req.server_name
      @context[:user_agent] = req.user_agent ? req.user_agent : ''
      @context[:uri] = px_config[:custom_uri] ? px_config[:custom_uri].call(req)  : req.fullpath 
      @context[:full_url] = req.original_url
      @context[:format] = req.format.symbol
      @context[:score] = 0

      if px_config.key?(:custom_user_ip)
        @context[:ip] = req.headers[px_config[:custom_user_ip]]
      elsif px_config.key?(:px_custom_user_ip_method)
        @context[:ip] = px_config[:px_custom_user_ip_method].call(req)
      else
        @context[:ip] = req.ip
      end

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
