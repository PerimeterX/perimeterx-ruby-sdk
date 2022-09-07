# frozen_string_literal: true

require 'perimeterx/internal/perimeter_x_context'
module PxModule
  class FirstPartyManager
    def initialize(px_config, px_http_client, logger)
      @px_config = px_config
      @app_id = px_config[:app_id]
      @px_http_client = px_http_client
      @logger = logger
      @from = [
        "/#{@app_id[2..]}/init.js",
        "/#{@app_id[2..]}/captcha",
        "/#{@app_id[2..]}/xhr"
      ]
    end

    def send_first_party_request(req)
      uri = URI.parse(req.original_url)
      url_path = uri.path

      headers = extract_headers(req)
      headers['x-px-first-party'] = '1'
      headers['x-px-enforcer-true-ip'] = PerimeterXContext.extract_ip(req, @px_config)

      if url_path.start_with?(@from[0])
        get_client(req, uri, headers)
      elsif url_path.start_with?(@from[1])
        get_captcha(req, uri, headers)
      elsif url_path.start_with?(@from[2])
        send_xhr(req, uri, headers)
      end
    end

    def get_client(_req, uri, headers)
      @logger.debug('FirstPartyManager[get_client]')

      # define host
      headers['host'] = PxModule::CLIENT_HOST

      # define request url
      url = "#{uri.scheme}://#{PxModule::CLIENT_HOST}/#{@app_id}/main.min.js"

      # send request
      @px_http_client.get(url, headers)
    end

    def get_captcha(_req, uri, headers)
      @logger.debug('FirstPartyManager[get_captcha]')

      # define host
      headers['host'] = PxModule::CAPTCHA_HOST

      # define request url
      path_and_query = uri.request_uri
      uri_suffix = path_and_query.sub "/#{@app_id[2..]}/captcha", ''
      url = "#{uri.scheme}://#{PxModule::CAPTCHA_HOST}#{uri_suffix}"

      # send request
      @px_http_client.get(url, headers)
    end

    def send_xhr(req, uri, headers)
      @logger.debug('FirstPartyManager[send_xhr]')

      # handle vid cookies
      if !req.cookies.nil? && req.cookies.key?('_pxvid')
        vid = PerimeterXContext.force_utf8(req.cookies['_pxvid'])
        if headers.key?('cookie')
          headers['cookie'] += "; pxvid=#{vid}"
        else
          headers['cookie'] = "pxvid=#{vid}"
        end
      end

      # define host
      headers['host'] = "collector-#{@app_id.downcase}.perimeterx.net"

      # define request url
      path_and_query = uri.request_uri
      path_suffix = path_and_query.sub "/#{@app_id[2..]}/xhr", ''
      url = "#{uri.scheme}://collector-#{@app_id.downcase}.perimeterx.net#{path_suffix}"

      # send request
      @px_http_client.post_xhr(url, req.body.string, headers)
    end

    def extract_headers(req)
      headers = {}
      req.headers.each do |k, v|
        next unless (k.start_with? 'HTTP_') && (!@px_config[:sensitive_headers].include? k)

        header = k.to_s.gsub('HTTP_', '')
        header = header.gsub('_', '-').downcase
        headers[header] = PerimeterXContext.force_utf8(v)
      end
      headers
    end

    # -1 - not first party request
    # 0 - /init.js
    # 1 - /captcha
    # 2 - /xhr
    def get_first_party_request_type(req)
      url_path = URI.parse(req.original_url).path
      @from.each_with_index do |val, index|
        return index if url_path.start_with?(val)
      end
      -1
    end

    def is_first_party_request(req)
      get_first_party_request_type(req) != -1
    end

    def get_response_content_type(req)
      get_first_party_request_type(req) == 2 ? :json : :js
    end
  end
end
