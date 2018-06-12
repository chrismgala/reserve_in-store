module Integrator

  ##
  # @param store [Store] The store that you want to run the integration process on
  def install!(store)
    install_script_tag!("#{ENV['CDN_JS_BASE_PATH']}reserveinstore.js")
    install_footer!(store)
    set_platform_data(store)
  end

  ##
  # @param [Object] src Source of the script tag to install
  def install_script_tag!(src)
    return true if ShopifyAPI::ScriptTag.all.any? # There should only be one

    ShopifyAPI::ScriptTag.create(src: src, event: 'onload')
  end

  ##
  # @param [Object] asset_path Path of the asset to load
  # @return [ShopifyAPI::Asset|NilClass] The Shopify asset object if successful, nil otherwise.
  def load_asset(asset_path)
    asset(asset_path)
  rescue ActiveResource::ResourceNotFound => e
    nil
  end

  ##
  # @param [Object] path Path of the asset to load
  # @return [ShopifyAPI::Asset] The Shopify asset object if successful, raise an error otherwise.
  def asset(path)
    ShopifyAPI::Asset.find(path)
  end

  ##
  # @param store [Store] The store that you want to set its name and platform id
  # @return [Boolean] True if successful, false otherwise.
  def set_platform_data(store)
    platform_data = ShopifyAPI::Shop.current.attributes
    store.platform_store_id = platform_data['id']
    store.name = platform_data['name']
    store.save
  end

  ##
  # @param [Object]  snippet_path Path of the snippet to check and update if necessary
  # @param [Object]  snippet_content Content to ensure is in the path requested
  # @return [Boolean] True if successful, false otherwise.
  def ensure_snippet!(snippet_path, snippet_content)

    snippet = load_asset(snippet_path)

    if snippet.blank?
      snippet = ShopifyAPI::Asset.new(key: snippet_path)
    end

    # Update content with latest footer script
    snippet.value = snippet_content
    snippet.save
  end

  ##
  # @param store [Store] The store that you want to install the footer on.
  def install_footer!(store)
    public_key = store.public_key
    footer_script = "
      <!-- // BEGIN // Reserve In-store App Code - DO NOT MODIFY // -->
      <script type=\"application/javascript\">
      (function(){
        window.__reserveInStore = window.__reserveInStore || [];
        window.__reserveInStore.push({ action: \"configure\", data: { store_pk: \"#{public_key}\", api_url: \"#{ENV['BASE_APP_URL']}\" }} );
        var headSrcUrls=document.getElementsByTagName(\"head\")[0].innerHTML.match(/var urls = \[.*\]/);if(headSrcUrls&&window.__reserveInStore){window.__reserveInStore.jsUrl=JSON.parse(headSrcUrls[0].replace(\"var urls = \",\"\")).find(function(url){return url.indexOf(\"reserveinstore.js\")!==-1});if(window.__reserveInStore.jsUrl){var s=document.createElement(\"script\");s.type=\"text/javascript\";s.async=!0;s.src=window.__reserveInStore.jsUrl;document.body.appendChild(s)}}
      })();</script>
      <!-- // END // Reserve In-store App Code // -->
    "

    ensure_snippet!("snippets/reserveinstore_footer.liquid", footer_script)

    theme_template = asset('layout/theme.liquid')
    include_code = "{% include 'reserveinstore_footer' %}"

    if theme_template.value.include?(include_code)
      true
    else
      theme_template.value = theme_template.value.gsub('</body>', "#{include_code}\n</body>")
      theme_template.save
    end
  end
end
