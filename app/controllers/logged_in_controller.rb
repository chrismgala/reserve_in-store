class LoggedInController < ShopifyApp::AuthenticatedController
  before_action :load_current_store

  private

  def load_current_store
    @current_store ||= Store.find_by(shopify_domain: current_shopify_domain)
  end
end
