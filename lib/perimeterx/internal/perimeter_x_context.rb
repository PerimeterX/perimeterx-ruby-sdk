require 'ipaddr'
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
      cookies = req.cookies
      unless cookies.empty?
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
        if k.start_with? 'HTTP_'
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

      # Take ip from custom method, if not try from ip headers
      if !px_config[:ip_headers].nil?
        px_config[:ip_headers].each do |ip_header|
          # go over ip_headers and try to get the ip
          if req.headers[ip_header.to_sym] and  !@context[:ip].nil?
            begin
              @context[:ip] = IPAddr.new(req.headers[ip_header.to_sym]).to_s
            rescue
              # fall back to nil
              @context[:ip] = nil
            end
          end
        end
      elsif px_config.key?(:px_custom_user_ip_method)
        @context[:ip] = px_config[:px_custom_user_ip_method].call(req)
      end

      # In case ip still empty take from default
      if @context[:ip].nil?
        @context[:ip] = req.ip
      end

      if req.server_protocol
          httpVer = req.server_protocol.split('/')
          if httpVer.size > 0
              @context[:http_version] = httpVer[1];
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
          return 'captcha'
        end
    end

    def get_px_cookie
      cookie = @context[:px_cookie].key?(:v3) ? @context[:px_cookie][:v3] : @context[:px_cookie][:v1]
      return cookie.tr(' ','+') if !cookie.nil?
    end

  end
end
