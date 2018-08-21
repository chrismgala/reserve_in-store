class StoreIntegrator

  RESERVE_IN_STORE_CODE = "Reserve In-store App Code" # Code that lets you recognize the footer start/end

  ##
  # @param store [Store] The store that you want to integrate into
  def initialize(store)
    @store = store
  end

  ##
  # Integrate the app into current store
  def integrate!
    install_footer!
    set_platform_data
    unless integrated?
      ForcedLogger.error("Failed to integrate", sentry: true, store: @store.try(:id))
    end
  end

  ##
  # @param store [Store] The store that you want to check if has been integrated properly
  # @return [Boolean] True if integrated properly, false otherwise.
  def integrated?
    unless @store.platform_store_id.present?
      ForcedLogger.log("INTEGRATION CHECK @store.platform_store_id.present? == false")
      return false
    end
    footer = load_asset('snippets/reserveinstore_footer.liquid')
    unless footer.present?
      ForcedLogger.log("INTEGRATION CHECK 'snippets/reserveinstore_footer.liquid' is not present")
      return false
    end
    unless footer.value.include?(RESERVE_IN_STORE_CODE)
      ForcedLogger.log("INTEGRATION CHECK code inside 'snippets/reserveinstore_footer.liquid' is not what we want")
      return false
    end
    unless load_asset('layout/theme.liquid').value.include?("{% include 'reserveinstore_footer' %}")
      ForcedLogger.log("INTEGRATION CHECK 'layout/theme.liquid' does not include '{% include 'reserveinstore_footer' %}'")
      return false
    end
    true
  end

  ##
  # @param [Object] asset_path Path of the asset to load
  # @return [ShopifyAPI::Asset|NilClass] The Shopify asset object if successful, nil otherwise.
  def load_asset(asset_path)
    asset(asset_path)
  rescue ActiveResource::ResourceNotFound => e
    ForcedLogger.error("Failed to load Shopify asset #{asset_path}, #{e}", sentry: true, store: @store.try(:id))
    nil
  end

  ##
  # @param [Object] path Path of the asset to load
  # @return [ShopifyAPI::Asset] The Shopify asset object if successful, raise an error otherwise.
  def asset(path)
    ForcedLogger.log("Shopify API load asset " + path)
    ShopifyAPI::Asset.find(path)
  end

  ##
  # Set current store's name and platform id
  # @return [Boolean] True if successful, false otherwise.
  def set_platform_data
    ForcedLogger.log("Shopify API load store data")
    platform_data = ShopifyAPI::Shop.current.attributes
    @store.platform_store_id = platform_data['id']
    @store.name = platform_data['name']
    @store.save
  end

  ##
  # @param [Object]  snippet_path Path of the snippet to check and update if necessary
  # @param [Object]  snippet_content Content to ensure is in the path requested
  # @return [Boolean] True if successful, false otherwise.
  def ensure_snippet!(snippet_path, snippet_content)

    snippet = load_asset(snippet_path)

    if snippet.blank?
      ForcedLogger.log("Shopify API create asset " + snippet_path)
      snippet = ShopifyAPI::Asset.new(key: snippet_path)
    end

    # Update content with latest footer script
    snippet.value = snippet_content
    ForcedLogger.log("Shopify API update asset " + snippet_path)
    snippet.save
  end

  ##
  # @return [Boolean] True if successful, raise an error otherwise.
  def install_footer!
    public_key = @store.public_key
    footer_script = "
      <!-- // BEGIN // #{RESERVE_IN_STORE_CODE} - DO NOT MODIFY // -->
      <script type=\"application/javascript\">
      (function(){
        window.__reserveInStore = window.__reserveInStore || [];
        window.__reserveInStore.push({ action: \"configure\", data: { store_pk: \"#{public_key}\", api_url: \"#{ENV['BASE_APP_URL']}\" }} );
        window.__reserveInStore.push({ action: \"setProduct\", data: {{ product | json }} });
        var headSrcUrls=document.getElementsByTagName(\"head\")[0].innerHTML.match(/var urls = \[.*\]/);if(headSrcUrls&&window.__reserveInStore){window.__reserveInStore.jsUrl=JSON.parse(headSrcUrls[0].replace(\"var urls = \",\"\")).find(function(url){return url.indexOf(\"reserveinstore.js\")!==-1});if(window.__reserveInStore.jsUrl){var s=document.createElement(\"script\");s.type=\"text/javascript\";s.async=!0;s.src=window.__reserveInStore.jsUrl;document.body.appendChild(s)}}
      })();</script>
      <link crossorigin=\"anonymous\" media=\"all\" rel=\"stylesheet\" href=\"#{ENV['CDN_JS_BASE_PATH']}reserveinstore.css\">
      <link href=\"https://fonts.googleapis.com/css?family=Montserrat|Open+Sans|Roboto:300\" rel=\"stylesheet\">
      <!-- // END // #{RESERVE_IN_STORE_CODE} // -->
    "

    ensure_snippet!("snippets/reserveinstore_footer.liquid", footer_script)

    theme_template = load_asset('layout/theme.liquid')
    include_code = "{% include 'reserveinstore_footer' %}"

    if theme_template.value.include?(include_code)
      true
    else
      theme_template.value = theme_template.value.gsub('</body>', "#{include_code}\n</body>")
      ForcedLogger.log("Shopify API update asset 'layout/theme.liquid'")
      theme_template.save
    end
  end

end
