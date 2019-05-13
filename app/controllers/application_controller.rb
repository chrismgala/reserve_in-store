class ApplicationController < ActionController::Base
  skip_after_action :intercom_rails_auto_include

  helper_method :embedded_mode?

  def embedded_mode?
    false
  end
end
