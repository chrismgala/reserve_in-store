class SplashPageController < ApplicationController
  include ShopifyApp::EmbeddedApp
  include ShopifyApp::RequireKnownShop
  # include ShopifyApp::ShopAccessScopesVerification

  helper_method :hide_menu?, :embedded_mode?

  def hide_menu?
    true
  end
end
