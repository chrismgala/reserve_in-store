class StoresController < LoggedInController

  ##
  # GET /stores/help
  def help
    require_user! || return
  end

  ##
  # GET /stores/templates
  def templates
    require_user! || return
  end

  ##
  # GET /stores/setup
  def setup
    if @current_store.users.any?
      redirect_to action: :settings
    end
  end

  def hide_menu?
    params[:action] == 'setup'
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
    require_user! || return

    return if @current_store.integrator.integrated?

    return if @current_store.integrator.integrate!

    # integration was not successful:
    flash.now[:error] = "Integration failed! Please contact our support team for help."
  end

  ##
  # GET /stores/deactivate
  def deactivate
    @current_store.deactivate!

    render :settings, notice: 'Reserve In-store has been deactivated.'
  end

  ##
  # GET /stores/activate
  def activate
    @current_store.activate!

    render :settings, notice: 'Reserve In-store has been activated.'
  end

  ##
  # PUT/PATCH /stores/settings
  def save_settings
    respond_to do |format|
      save_params = store_params

      # Ensure values are boolean if they are enabled/disabled flags
      store_params.keys.each do |key|
        if key.to_s =~ /.+(_enabled)/
          unless store_params[key].is_a?(TrueClass) || store_params[key].is_a?(FalseClass)
            store_params[key] = store_params[key].to_bool
          end
        end
      end

      @current_store.assign_attributes(save_params)

      if @current_store.save
        format.html { redirect_to params[:next_url].presence || stores_settings_url, notice: 'Store settings were successfully updated.' }
        format.json { render :settings, status: :ok }
      else
        format.html { render :settings }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def require_user!
    unless @current_store.users.any?
      redirect_to(stores_setup_url)
      false
    else
      true
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def store_params
    params.fetch(:store, {}).permit(Store::PERMITTED_PARAMS)
  end

end
