class SetupController < LoggedInController
  include Integrator

  def integrate
    install!(@current_store)
    redirect_to stores_settings_url
  end

end
