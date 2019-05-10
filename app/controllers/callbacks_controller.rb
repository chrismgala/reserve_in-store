class CallbacksController < ShopifyApp::SessionsController

  private

  ##
  # Overwriting login_shop to also make it populate locations via ShopifyAPI
  def login_shop
    super
    store = Store.find_by(shopify_domain: current_shopify_domain)

    new_session = ShopifyAPI::Session.new(shop_name, token)
    ShopifyAPI::Base.activate_session(new_session)
  end

  ##
  # The session callback normally tries to go to the url of the non-embedded app but then redirects to the embedded app
  # This causes a jarring redirect where the non-embedded app flashes on screen for a second
  # @return [String] - The url of the embedded app. We just go directly to this to avoid the redirect
  def return_address
    embedded_app_address = "https://#{current_shopify_domain}/admin/apps/#{ShopifyApp.configuration.api_key}"
    embedded_app_address + session.delete(:return_to).to_s
  end
end
