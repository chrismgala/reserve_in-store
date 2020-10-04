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
  end

  ##
  # GET /stores/webhooks
  def webhooks
    return
  end

  ##
  # GET /stores/deactivate
  def deactivate
    @current_store.deactivate!

    redirect_to stores_settings_url(view: 'settings'), notice: 'Reserve In-store has been deactivated.'
  end

  ##
  # GET /stores/activate
  def activate
    @current_store.activate!

    redirect_to stores_settings_url(view: 'settings'), notice: 'Reserve In-store has been activated.'
  end

  ##
  # GET /stores/reinstall
  def reinstall
    UpdateFooterJob.new.perform(@current_store.id)

    redirect_to stores_settings_url(view: 'settings'), notice: 'Reserve In-store has been re-installed into your store.'
  end
  ##
  # GET /stores/resync
  def resync
    @current_store.sync_locations!

    redirect_to stores_settings_url(view: 'settings'), notice: 'Reserve In-store has re-synced your store locations.'
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
        format.html { redirect_to params[:next_url].presence || stores_settings_url(view: 'settings'), notice: 'Store settings were successfully updated.' }
        format.json { render :settings, status: :ok }
      else
        format.html { render :settings }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  def hide_menu?
    params[:action] == 'setup'
  end

  private

  def require_user!
    unless @current_store.users.any?
      redirect_to(stores_setup_url)
      false
    else
      if !params[:view] && params[:action] != 'templates' && params[:action] != 'help' && @current_store.reservations.count > 0
        redirect_to reservations_path
      end
      true
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def store_params
    #params.fetch(:store, {}).permit(Store::PERMITTED_PARAMS, webhooks: [:url, :topic])
    params.fetch(:store, {}).permit(Store::PERMITTED_PARAMS)
  end

end
