class ApplicationController < ActionController::Base
  before_action :set_host

  helper_method :embedded_mode?

  def embedded_mode?
    false
  end

  private

  def set_host
    @host = params[:host]
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(admins)
    admin_root_path
  end
end
