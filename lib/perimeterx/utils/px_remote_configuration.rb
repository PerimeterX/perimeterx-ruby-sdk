require 'perimeterx/utils/px_constants'


module PxModule
  class PerimeterxRemoteConfiguration
    attr_accessor :px_config
    attr_accessor :px_http_client

    def initialize(px_config, px_http_client)
      @px_http_client = px_http_client
      @px_config = px_config
      @logger = px_config[:logger]
      @logger.debug('PxRemoteConfiguration[initialize]')
    end

    def get_configuration_from_server
      @logger.debug('PxRemoteConfiguration[get_configuration_from_server]')
      headers = {
          'Authorization' => "Bearer #{@px_config[:auth_token]}" ,
          'Content-Type' => 'application/json'
      };

      checksum_param = ''
      if !@px_config[:checksum].nil?
        @logger.debug('PxRemoteConfiguration[get_configuration_from_server]: adding checksum')
        checksum_param = "?checksum=#{@px_config[:checksum]}"
      end

      uri = "#{PxModule::REMOTE_CONFIG_PATH}#{checksum_param}"

      response = @px_http_client.get(uri, headers, @px_config[:api_timeout], @px_config[:api_connect_timeout], PxModule::REMOTE_CONFIG_SERVER)

      if !response || response.code > 204 # error/timeout
        @logger.debug('PxRemoteConfiguration[get_configuration_from_server]: failed to get configuration')
        if checksum_param.empty?
          @logger.debug('PxRemoteConfiguration[get_configuration_from_server]: disabling module')
          @px_config[:module_enabled] = false
        end

      elsif response.code == 204 # no update
        @logger.debug('PxRemoteConfiguration[get_configuration_from_server]: no update')
      elsif response.code == 200 # ok
        @logger.debug("PxRemoteConfiguration[get_configuration_from_server]:new configuration found #{response.body}")
        response_body = eval(response.body);

        @px_config[:ip_headers] =  response_body[:ipHeaders]
        @px_config[:sensitive_headers] = response_body[:sensitiveHeaders]
        @px_config[:module_enabled] = response_body[:moduleEnabled]
        @px_config[:cookie_key] = response_body[:cookieKey]
        @px_config[:blocking_score] = response_body[:blockingScore]
        @px_config[:app_id] = response_body[:app_id]
        @px_config[:api_connect_timeout] = response_body[:connectTimeout]
        @px_config[:api_timeout] = response_body[:riskTimeout]
        @px_config[:checksum] = response_body[:checksum]
      end
    end
  end
end