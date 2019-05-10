class StoreIntegrator
  attr_accessor :errors, :store

  RESERVE_IN_STORE_CODE = "Reserve In-store App Code" # Code that lets you recognize the footer start/end

  ##
  # @param store [Store] The store that you want to integrate into
  def initialize(store)
    @store = store
    @errors = []
  end

  ##
  # Integrate the app into current store
  # @return [Boolean] true if success, false if not successful
  def integrate!
    store.with_shopify_session do
      reset_errors!

      footer_install_success = install_footer!

      set_platform_data if footer_install_success

      return true if !has_errors? && integrated?

      ForcedLogger.error("Failed to integrate", sentry: true, store: @store.try(:id))
      if !has_errors?
        add_error("Failed to integrate the embedded components automatically into your store due " + \
                  "to an unknown error. Our engineers have been informed about the issue. Please contact our " + \
                  "support team for help with getting set up.")
      end

      false
    end
  end

  ##
  # @param store [Store] The store that you want to check if has been integrated properly
  # @return [Boolean] True if integrated properly, false otherwise.
  def integrated?
    store.with_shopify_session do
      if @store.platform_store_id.blank?
        log("INTEGRATION CHECK @store.platform_store_id is blank!")
        return false
      end

      footer = load_asset('snippets/reserveinstore_footer.liquid', report_not_found: false)
      unless footer.present?
        log("INTEGRATION CHECK 'snippets/reserveinstore_footer.liquid' is not present")
        return false
      end
      unless footer.value.include?(RESERVE_IN_STORE_CODE)
        log("INTEGRATION CHECK code inside 'snippets/reserveinstore_footer.liquid' is not what we want")
        return false
      end
      unless load_asset('layout/theme.liquid').value.include?("{% include 'reserveinstore_footer' %}")
        log("INTEGRATION CHECK 'layout/theme.liquid' does not include '{% include 'reserveinstore_footer' %}'")
        return false
      end
      true
    end
  end


  ##
  # Run `uglifyjs --mangle -- app/assets/javascripts/public/bananastand/lib/cached_asset.js` from your console to generate this.
  # @version 0.2.0
  def cached_asset_min_js
    'var ReserveInStoreCachedAsset=function(r){var n=this;var a=r.name||r.url.split("?")[0].split("#")[0];var o="ReserveInStore.AssetCache."+a;var i=(new Date).getTime()/1e3;var c=r.type||(r.url.indexOf(".html")!==-1?"text/template":"text/javascript");n.load=function(t){t=t||function(){};if(n.content){return t(n.content)}if(!e()){s(r.url,function(e){n.content=e;u(e);n.save(e);t(e)})}else{t(n.content)}return true};n.save=function(e){var t=i+(r.expiresIn||900);if(!l()){return false}var n={name:a,url:r.url,expires:t,content:e};window.localStorage.setItem(o,JSON.stringify(n));return true};n.clear=function(){window.localStorage.removeItem(o);return false};var e=function(){if(!l())return false;var e=window.localStorage.getItem(o);if(!e||typeof e!=="string"){return null}var t=JSON.parse(e);if(t.expires<i||t.url!==r.url){return n.clear()}n.content=t.content;u(n.content);return true};var u=function(e){if(document.getElementById(o))return;var t=document.createElement("script");t.type=c;t.id=o;t.async=!0;t.innerHTML=e;document.body.appendChild(t)};var s=function(e,t){var n=new XMLHttpRequest;n.async=true;n.onreadystatechange=function(){if(this.readyState==4&&this.status<300){t(this.responseText)}};n.open("GET",e,true);n.send()};var l=function(){var e="test";try{window.localStorage.setItem(e,"t");window.localStorage.removeItem(e);return 1}catch(e){return 0}}};'
  end

  def cached_asset_js_expiry_time
    Rails.env.development? ? 1.second : 15.minutes
  end

  ##
  # This preloading JS will add the JS script tag in the top immediately if it is not yet there.
  # By default Shopify will wait for the whole page to load first before adding scripts, so doing this
  # speeds up the initial Fera.ai load speed quite a bit.
  def js_preloader(checkout_mode = false)
    cached_asset_code =  "#{cached_asset_min_js}" + \
        " new ReserveInStoreCachedAsset({ name: 'reserveinstore.js', expiresIn: #{cached_asset_js_expiry_time}, url: window.reserveInStoreJsUrl || \"#{Store::JS_SCRIPT_PATH}\"}).load();"
    return cached_asset_code if checkout_mode
    'var headSrcUrls = document.getElementsByTagName("head")[0].innerHTML.match(/var urls = \[.*\]/);if (headSrcUrls && window.reserveInStore) { if (JSON.parse(headSrcUrls[0].replace("var urls = ", "")).find(function(url) {return url.indexOf("reserveinstore.js") !== -1 && (window.reserveInStoreJsUrl = url)})) { ' + cached_asset_code + ' } }'
  end

  ##
  # @return [Boolean] True if successful, raise an error otherwise.
  def install_footer!
    store.with_shopify_session do

      if store.active?
        footer_script = "
{% if product and product.available %}
<!-- // BEGIN // #{RESERVE_IN_STORE_CODE} - DO NOT MODIFY // -->
<script type=\"application/javascript\">
(function(){
  window.reserveInStore = window.reserveInStore || window.__reserveInStore || [];
  window.reserveInStore.push('configure', #{store.footer_config.to_json});
  window.reserveInStore.push('setProduct', {{ product | json }});
  #{js_preloader}
})();</script>
<link crossorigin=\"anonymous\" media=\"all\" rel=\"stylesheet\" href=\"#{ENV['CDN_JS_BASE_PATH']}reserveinstore.css\">
<link href=\"https://fonts.googleapis.com/css?family=Montserrat|Open+Sans|Roboto:300\" rel=\"stylesheet\">
#{cached_css}
<!-- // END // #{RESERVE_IN_STORE_CODE} // -->
{% endif %}
    "
      else
        footer_script = "<!-- Reserve In-Store is Deactivated. Please contact our support team if you need help. -->"
      end

      ensure_snippet!("snippets/reserveinstore_footer.liquid", footer_script)

      theme_template = load_asset('layout/theme.liquid')
      include_code = "{% include 'reserveinstore_footer' %}"

      if theme_template.value.include?(include_code)
        true
      else
        if theme_template.value.to_s.include?('</body>')
          theme_template.value = theme_template.value.gsub('</body>', "#{include_code}\n</body>")
          log("Shopify API update asset 'layout/theme.liquid'")
          unless theme_template.save
            add_error("Failed to edit your theme file because of an error received from the Shopify server. " + \
                  "Please consult our support team for help. Until you do this, the integrated components may " + \
                  "not show in your store.")
          end

        else
          add_error("We could not integrate the embedded components in your store because your theme is missing an ending " + \
                  "body tag in the layout/theme.liquid file. This means that your themes HTML is invalid and may render " + \
                  "incorrectly in many browser, and may also be penalized by search engines. Please consult your developer, " + \
                  "or reach out to our support team for help with fixing this problem on your store. Once it is fixed you " + \
                  "will be able to try installing this app again.")
        end

        !has_errors?
      end

      !has_errors?
    end
  end

  def has_errors?
    @errors.to_a.any?
  end

  private

  ##
  # @param [String] asset_path Path of the asset to load
  # @return [ShopifyAPI::Asset|NilClass] The Shopify asset object if successful, nil otherwise.
  def load_asset(asset_path, report_not_found: true)
    asset(asset_path)

  rescue ActiveResource::ResourceNotFound => e
    msg = "Failed to load Shopify asset #{asset_path} - #{e.message}."
    if report_not_found
      ForcedLogger.error(msg, store: @store.try(:id), sentry: true)
    else
      log(msg)
    end

    nil
  end

  ##
  # @param [String] path Path of the asset to load
  # @return [ShopifyAPI::Asset] The Shopify asset object if successful, raise an error otherwise.
  def asset(path)
    log("Shopify API load asset " + path)

    store.with_shopify_session do
      ShopifyAPI::Asset.find(path)
    end
  end

  ##
  # Set current store's name and platform id
  # @return [Boolean] True if successful, false otherwise.
  def set_platform_data
    log("Shopify API load store data")
    platform_data = @store.shopify_settings
    @store.platform_store_id = platform_data['id']
    @store.name = platform_data['name']
    log("Loaded these store settings into modal: #{platform_data.inspect}")
    @store.save
  end

  ##
  # @param [Object]  snippet_path Path of the snippet to check and update if necessary
  # @param [Object]  snippet_content Content to ensure is in the path requested
  # @return [Boolean] True if successful, false otherwise.
  def ensure_snippet!(snippet_path, snippet_content)
    snippet = load_asset(snippet_path)

    if snippet.blank?
      log("Shopify API create asset " + snippet_path)
      snippet = ShopifyAPI::Asset.new(key: snippet_path)
    end

    # Update content with latest footer script
    snippet.value = snippet_content
    log("Shopify API update asset " + snippet_path)
    snippet.save
  end


  def cached_css
    "<style>#{store.custom_css_in_use}</style>"
  end

  def log(msg, contexts = {})
    ForcedLogger.log(msg, { store: @store.try(:id) }.merge(contexts))
  end

  def add_error(message)
    @errors << message
  end

  def reset_errors!
    @errors = []
  end

end
