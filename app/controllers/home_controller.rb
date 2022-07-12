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
  end
end
