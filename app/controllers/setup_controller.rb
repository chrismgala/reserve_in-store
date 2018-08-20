class SetupController < LoggedInController

  ##
  # TODO This is not in use right now
  # GET /setup/integrate
  def integrate
    StoreIntegrator.new(@current_store).integrate!
    redirect_to stores_settings_url
  end

end
