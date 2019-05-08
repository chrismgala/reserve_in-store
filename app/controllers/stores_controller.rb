class StoresController < LoggedInController

  ##
  # GET /stores/help
  def help
  end

  ##
  # GET /stores/templates
  def templates
  end

  ##
  # Used by the skill editors to provide previews of the components that are being built.
  # GET /stores/iframe_preview
  def iframe_preview
    render layout: false
  end

  ##
  # GET /stores/settings
  def settings
    @integrator = StoreIntegrator.new(@current_store)

    return if @integrator.integrated?

    return if @integrator.integrate!

    # integration was not successful:
    flash.now[:error] = "Integration failed! Please contact our support team for help."
  end

  ##
  # PUT/PATCH /stores/settings
  def save_settings
    respond_to do |format|
      save_params = store_params

      # Ensure values are boolean if they are enabled/disabled flags
      store_params.keys.each do |key|
        if key.to_s =~ /.+(_enabled)/
          store_params[key] = store_params[key].to_bool unless store_params[key].is_a?(TrueClass) || store_params[key].is_a?(FalseClass)
        end
      end

      @current_store.assign_attributes(save_params)

      if @current_store.validate_active_and_save!
        format.html { redirect_to params[:next_url].presence || stores_settings_url, notice: 'Store settings were successfully updated.' }
        format.json { render :settings, status: :ok }
      else
        format.html { render :settings }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def store_params
    params.fetch(:store, {}).permit(Store::PERMITTED_PARAMS)
  end

end
