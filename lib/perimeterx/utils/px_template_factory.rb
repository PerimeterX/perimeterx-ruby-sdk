require 'mustache'
require 'perimeterx/utils/px_constants'
module PxModule
  module PxTemplateFactory

    def self.get_template(px_ctx, px_config, px_template_object)
      logger = px_config[:logger]
      if (px_config[:challenge_enabled] && px_ctx.context[:block_action] == 'challenge')
        logger.debug('PxTemplateFactory[get_template]: px challange triggered')
        return px_ctx.context[:block_action_data].html_safe
      end

      view = Mustache.new

      if (px_ctx.context[:block_action] == 'rate_limit')
        logger.debug('PxTemplateFactory[get_template]: rendering ratelimit template')
        template_type = RATELIMIT_TEMPLATE
      else
        logger.debug('PxTemplateFactory[get_template]: rendering template')
        template_type = CHALLENGE_TEMPLATE
      end

      Mustache.template_file =  "#{File.dirname(__FILE__) }/templates/#{template_type}#{PxModule::TEMPLATE_EXT}"

      view[PxModule::PROP_APP_ID] = px_config[:app_id]
      view[PxModule::PROP_VID] = px_ctx.context[:vid]
      view[PxModule::PROP_UUID] = px_ctx.context[:uuid]
      view[PxModule::PROP_CUSTOM_LOGO] = px_config[:custom_logo]
      view[PxModule::PROP_CSS_REF] = px_config[:css_ref]
      view[PxModule::PROP_JS_REF] = px_config[:js_ref]
      view[PxModule::PROP_HOST_URL] = px_template_object[:host_url]
      view[PxModule::PROP_LOGO_VISIBILITY] = px_config[:custom_logo] ? PxModule::VISIBLE : PxModule::HIDDEN
      view[PxModule::PROP_BLOCK_SCRIPT] = px_template_object[:block_script]
      view[PxModule::PROP_ALT_BLOCK_SCRIPT] = px_template_object[:alt_block_script]
      view[PxModule::PROP_JS_CLIENT_SRC] = px_template_object[:js_client_src]
      view[PxModule::PROP_FIRST_PARTY_ENABLED] = px_ctx.context[:first_party_enabled]

      return view.render.html_safe
    end
  end #end class
end #end module