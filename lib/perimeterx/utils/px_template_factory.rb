require 'mustache'
require 'perimeterx/utils/px_constants'
module PxModule
  module PxTemplateFactory

    def self.get_template(px_ctx, px_config)
      logger = px_config[:logger]
      if (px_config[:challenge_enabled] && px_ctx.context[:block_action] == 'challenge')
        logger.debug('PxTemplateFactory[get_template]: px challange triggered')
        return px_ctx.context[:block_action_data].html_safe
      end

      logger.debug('PxTemplateFactory[get_template]: rendering template')
      template_type = px_ctx.context[:block_action] == 'captcha' ? PxModule::CAPTCHA_TEMPLATE : BLOCK_TEMPLATE

      template_postfix = ''
      if px_ctx.context[:cookie_origin] == 'header'
        template_postfix = '.mobile'
      end

      Mustache.template_file =  "#{File.dirname(__FILE__) }/templates/#{template_type}#{template_postfix}#{PxModule::TEMPLATE_EXT}"
      view = Mustache.new

      view[PxModule::PROP_APP_ID] = px_config[:app_id]
      view[PxModule::PROP_REF_ID] = px_ctx.context[:uuid]
      view[PxModule::PROP_VID] = px_ctx.context[:vid]
      view[PxModule::PROP_UUID] = px_ctx.context[:uuid]
      view[PxModule::PROP_CUSTOM_LOGO] = px_config[:custom_logo]
      view[PxModule::PROP_CSS_REF] = px_config[:css_ref]
      view[PxModule::PROP_JS_REF] = px_config[:js_ref]
      view[PxModule::HOST_URL] = "https://collector-#{px_config[:app_id]}.perimeterx.net"
      view[PxModule::PROP_LOGO_VISIBILITY] = px_config[:custom_logo] ? PxModule::VISIBLE : PxModule::HIDDEN

      return view.render.html_safe
    end
  end #end class
end #end module