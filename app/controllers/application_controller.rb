class ApplicationController < ActionController::Base
  skip_after_action :intercom_rails_auto_include

  helper_method :embedded_mode?

  def embedded_mode?
    false
  end

  private

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(admins)
    admin_root_path
  end
end
