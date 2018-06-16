class SetupController < LoggedInController

  ##
  # GET /setup/integrate
  def integrate
    StoreIntegrator.new(@current_store).integrate!
    redirect_to stores_settings_url
  end

end
