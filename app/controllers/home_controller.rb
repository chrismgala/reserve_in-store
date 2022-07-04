# frozen_string_literal: true

class HomeController < LoggedInController

  helper_method :hide_menu?, :embedded_mode?

  def hide_menu?
    false
  end

  def embedded_mode?
    false
  end

  ##
  # GET /home
  def index
    if @current_store.users.any?
      if @current_store.reservations.count > 0
        redirect_to(reservations_path)
      else
        redirect_to(stores_settings_path)
      end
    end
  end
end
