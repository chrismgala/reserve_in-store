class CallbacksController < ShopifyApp::SessionsController

  private

  ##
  # The session callback normally tries to go to the url of the non-embedded app but then redirects to the embedded app
  # This causes a jarring redirect where the non-embedded app flashes on screen for a second
  # @return [String] - The url of the embedded app. We just go directly to this to avoid the redirect
  def return_address
    embedded_app_address = "https://#{current_shopify_domain}/admin/apps/#{ShopifyApp.configuration.api_key}"
    embedded_app_address + session.delete(:return_to).to_s
  end
end
