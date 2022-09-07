# frozen_string_literal: true

require 'perimeterx/utils/px_logger'

module PxModule
  class PerimeterxRiskClient
    attr_accessor :px_config, :http_client

    def initialize(px_config, http_client)
      @px_config = px_config
      @http_client = http_client
      @logger = px_config[:logger]
    end

    def format_headers(px_ctx)
      @logger.debug('PerimeterxRiskClient[format_headers]')
      formated_headers = []
      px_ctx.context[:headers].each do |k, v|
        next if @px_config[:sensitive_headers].include? k.to_s

        formated_headers.push({
                                name: k.to_s,
                                value: v
                              })
        # end if
      end
      formated_headers
    end
  end
end
