# frozen_string_literal: true

class HomeController < LoggedInController

  helper_method :hide_menu?, :embedded_mode?

  def hide_menu?
    false
  end

  def embedded_mode?
    false
  end

  def index
    redirect_to stores_settings_path(shop: @current_store.shopify_domain)
  end
end
