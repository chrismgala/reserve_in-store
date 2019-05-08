module Bananastand
  module StoreAdapters
    class BaseIntegrator < BaseStoreAdapter
      delegate :api, :products, :orders, :customers, :platform_data, to: :store

      def integrate!; end
      def reintegrate!(integration_type = 'product_view'); integrate!; end
      def integration_instructions_url(integraton_type); store.installation_instructions_url; end
      def product_id_code; ""; end
      def cart_item_ids_code; ""; end
      def set_customer_id_js; ''; end
      def set_cart_js; ''; end
      def product_page_js; ''; end
      def adapter_code; ''; end

      ##
      # Sends the failed auto install notification to admins but makes sure not to die if it fails (so install can continue)
      def fail_integration!
        Bananastand::InternalNotificationService.failed_auto_install(store)
        store.has!(:failed_integration)
      rescue => e
        Raven.capture_exception(e)
        error("Error trying to send failed install admin notification (User was NOT informed): #{e.message}.")
      end

      def push_event_code
        [set_customer_id_js, product_page_js, adapter_code].join("\n  ") # Extra space is to tab it out in the installation view
      end

      def custom_cart_container_code(opts = {})
        opts[:classes] = "#{opts[:classes]} banana-cart-container".strip
        opts[:additions] = "#{opts[:additions]} data-cart_item_ids=\"#{cart_item_ids_code}\" data-container_type=\"cart\"".strip
        custom_container_code(opts)
      end

      def custom_list_container_code(opts = {})
        opts[:classes] = "#{opts[:classes]} banana-list-container".strip
        opts[:additions] = "#{opts[:additions]} data-product_id=\"#{product_id_code}\" data-container_type=\"list\"".strip
        custom_container_code(opts)
      end

      def custom_view_container_code(opts = {})
        opts[:classes] = "#{opts[:classes]} banana-view-container".strip
        opts[:additions] = "#{opts[:additions]} data-product_id=\"#{product_id_code}\" data-container_type=\"view\"".strip
        custom_container_code(opts)
      end

      def custom_container_code(opts = {})
        "<div class=\"banana-container #{opts[:classes]}\" data-campaign_id=\"#{opts[:campaign_id]}\" #{opts[:additions]}></div>"
      end

      def product_view_container_html
        "<div class=\"banana-container banana-view-container\" data-product_id=\"#{product_id_code}\" data-container_type=\"view\"></div>"
      end

      def product_list_container_html
        "<div class=\"banana-container banana-list-container\" data-product_id=\"#{product_id_code}\" data-container_type=\"list\"></div>"
      end

      def product_cart_container_html
        "<div class=\"banana-container banana-cart-container\" data-container_type=\"cart\"></div>"
      end

      ##
      # Run `uglifyjs --mangle -- app/assets/javascripts/public/bananastand/lib/cached_asset.js` from your console to generate this.
      # @version 0.2.0
      def cached_asset_min_js
        'var FeraCachedAsset=function(r){var n=this;var a=r.name||r.url.split("?")[0].split("#")[0];var o="Fera.AssetCache."+a;var i=(new Date).getTime()/1e3;var c=r.type||(r.url.indexOf(".html")!==-1?"text/template":"text/javascript");n.load=function(t){t=t||function(){};if(n.content){return t(n.content)}if(!e()){s(r.url,function(e){n.content=e;u(e);n.save(e);t(e)})}else{t(n.content)}return true};n.save=function(e){var t=i+(r.expiresIn||900);if(!l()){return false}var n={name:a,url:r.url,expires:t,content:e};window.localStorage.setItem(o,JSON.stringify(n));return true};n.clear=function(){window.localStorage.removeItem(o);return false};var e=function(){if(!l())return false;var e=window.localStorage.getItem(o);if(!e||typeof e!=="string"){return null}var t=JSON.parse(e);if(t.expires<i||t.url!==r.url){return n.clear()}n.content=t.content;u(n.content);return true};var u=function(e){if(document.getElementById(o))return;var t=document.createElement("script");t.type=c;t.id=o;t.async=!0;t.innerHTML=e;document.body.appendChild(t)};var s=function(e,t){var n=new XMLHttpRequest;n.async=true;n.onreadystatechange=function(){if(this.readyState==4&&this.status<300){t(this.responseText)}};n.open("GET",e,true);n.send()};var l=function(){var e="test";try{window.localStorage.setItem(e,"t");window.localStorage.removeItem(e);return 1}catch(e){return 0}}};var BananaStandCachedAsset=FeraCachedAsset;'
      end

      def cached_asset_js_expiry_time
        Rails.env.development? ? 1.second : 15.minutes
      end

      ##
      # @param checkout_mode [Boolean] If true, this preloader is for the checkout. Otherwise it is not.
      def js_preloader(checkout_mode)
        "#{cached_asset_min_js}" + \
        " new FeraCachedAsset({ name: 'bananastand', expiresIn: #{cached_asset_js_expiry_time}, url: window.feraJsUrl || \"#{store.installer.fera_js_url(checkout_mode)}\"}).load();"
      end

      ##
      # Returns code to be inserted into Google Analytics for running BSIO in the checkout
      # This is primarily just to enable cart timers for users.
      # @return [String]
      def checkout_code
        "(function(){" + \
          "window.fera = window.fera || [];" + \
          "window.feraStandaloneMode= true;" + \
          "#{configure_js}" + \
          "#{adapter_code}" + \
          "#{js_preloader(true).gsub("\n", ' ')}" + \
        "})();"
      end

      def footer_script
        "<!-- // BEGIN // Fera.ai Integration Code - DO NOT MODIFY // -->
<script type=\"application/javascript\">
(function(){
  window.fera = window.fera || [];#{' window.feraDebugMode = true;' if Rails.env.development?}
  #{configure_js}
  #{adapter_code}
  #{set_customer_id_js}
  #{set_cart_js}
  #{product_page_js}
  #{js_preloader(false)}
})();
</script>
<!-- // END // Fera.ai Integration Code // -->".gsub(/^\s*$\n/, '')
      end

      ##
      # Returns code for a merchant to trigger an add to cart event for our JS API
      # @return [String]
      def cart_add_event_code
        "window.fera = window.fera || [];
window.fera.push({ action: 'pushEvent', data: {event_type: 'product_add_to_cart'}, product: { PRODUCT_INFORMATION } });"
      end

      ##
      # Returns code for a merchant to trigger an order event for our JS API
      # @return [String]
      def create_order_code
        "window.fera = window.fera || [];
window.fera.push({ action: 'pushOrder', order: { ORDER_INFORMATION }});"
      end

      ##
      # Returns code for a merchant to trigger a product viewed for our JS API
      # @return [String]
      def product_viewed_event_script
        "<script type=\"application/javascript\">
(function(){
  window.fera = window.fera || [];
  window.fera.push({ action: 'setProductId', product_id: '#{product_id_code}'});
window.fera.push({ action: 'startProductPageViewing' });
})();
</script>"
      end

      ##
      # Returns code for a merchant to trigger setting the cart for our JS API
      # @return [String]
      def set_cart_script
        "<script type=\"application/javascript\">
(function(){
  window.fera = window.fera || [];
  window.fera.push({ action: 'setCart',
    cart: {
      items: [{ PRODUCT_INFORMATION }]
    }});
})();
</script>"
      end


      def configure_js
        extra_api_params = ''
        if Rails.env.development?
          extra_api_params += ", api_url: '#{ENV['BASE_APP_URL']}/api/v1/'"
          extra_api_params += ", dev_mode: true"
        end
        "window.fera.push({ action: \"configure\", data: { store_pk: \"#{store.public_key}\" #{extra_api_params} }} );"
      end

      def needs_checkout_integration?
        !store.integration_checker.section_integrated?(:checkout)
      end

      def needs_prod_view_integration?
        !store.integration_checker.section_integrated?(:product_list)
      end

      def needs_prod_list_integration?
        !store.integration_checker.section_integrated?(:product_view)
      end

      def needs_cart_integration?
        !store.integration_checker.section_integrated?(:cart)
      end

      ##
      # Store classes can override these to specify a partial that contains instructions to integrate.
      # These partials will be rendered as a tab under the campaign.
      # They all @return [String | nil]
      ##

      def checkout_integration_partial
        nil
      end

      def prod_view_integration_partial
        nil
      end

      def prod_list_integration_partial
        nil
      end

      def cart_integration_partial
        nil
      end

      def store_integrations_partial
        nil
      end
    end
  end
end
