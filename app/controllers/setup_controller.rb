class SetupController < LoggedInController
  include Integrator

  ##
  # GET /setup/integrate
  def integrate
    install!(@current_store)
    redirect_to stores_settings_url
  end

end
