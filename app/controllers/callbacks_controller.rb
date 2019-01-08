class CallbacksController < ShopifyApp::SessionsController

  private

  ##
  # Overwriting login_shop to also make it populate locations via ShopifyAPI
  # @return [Boolean] - whether current_store.save is successful
  def login_shop
    super
    current_store = Store.find_by(shopify_domain: current_shopify_domain)
    new_session = ShopifyAPI::Session.new(shop_name, token)
    ShopifyAPI::Base.activate_session(new_session)
    store_attributes = ShopifyAPI::Shop.current.attributes
    if current_store.locations.empty?
      ShopifyAPI::Location.all.each do |shopify_loc|
        loc_attr = shopify_loc.attributes
        loc_attr.transform_values!(&:to_s)
        loc_attr[:address] = loc_attr[:address1] + " " + loc_attr[:address2]
        loc_attr[:state] = loc_attr[:province]
        loc_attr[:email] = store_attributes[:email]
        Location.create(loc_attr.slice(*Location::PERMITTED_PARAMS).merge(store_id: current_store.id)) if loc_attr[:address].present?
      end
    end
    current_store.save
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
