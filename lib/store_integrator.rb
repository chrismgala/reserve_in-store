class StoreIntegrator
  attr_accessor :errors

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

  ##
  # @param store [Store] The store that you want to check if has been integrated properly
  # @return [Boolean] True if integrated properly, false otherwise.
  def integrated?
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
    ShopifyAPI::Asset.find(path)
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

  def has_errors?
    @errors.to_a.any?
  end

  private

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
