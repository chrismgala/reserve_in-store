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
  # GET /stores/settings
  def settings
    Rails.logger.info("STORES_SETTINGS: Starting settings page request")
    Rails.logger.info("STORES_SETTINGS: @current_store present: #{@current_store.present?}, shopify_domain: #{@current_store.try(:shopify_domain)}, store_id: #{@current_store.try(:id)}")
    Rails.logger.info("STORES_SETTINGS: Request params: #{params.except(:controller, :action).inspect}")
    Rails.logger.info("STORES_SETTINGS: current_shopify_domain: #{current_shopify_domain.inspect}")
    Rails.logger.info("STORES_SETTINGS: Shopify session valid: #{ShopifyAPI::Session.present?}")

    if @current_store.present?
      Rails.logger.info("STORES_SETTINGS: Store found - checking if integrator can be initialized")
      begin
        @integrator = @current_store.integrator
        Rails.logger.info("STORES_SETTINGS: Integrator initialized successfully, has_errors: #{@integrator.try(:has_errors?)}")
        if @integrator.try(:has_errors?)
          Rails.logger.warn("STORES_SETTINGS: Integrator has errors: #{@integrator.errors.inspect}")
        end
      rescue StandardError => e
        Rails.logger.error("STORES_SETTINGS: Failed to initialize integrator - error: #{e.message}, class: #{e.class}")
      end
    else
      Rails.logger.error("STORES_SETTINGS: @current_store is nil! current_shopify_domain: #{current_shopify_domain.inspect}")
    end

    require_user! || return

    Rails.logger.info("STORES_SETTINGS: Settings page request completed successfully")
  rescue StandardError => e
    Rails.logger.error("STORES_SETTINGS: Unexpected error in settings action - error: #{e.message}, class: #{e.class}")
    Rails.logger.error("STORES_SETTINGS: Backtrace: #{e.backtrace[0..5].join("\n")}")
    raise e
  end

  ##
  # GET /stores/webhooks
  def webhooks
  end

  ##
  # GET /stores/deactivate
  def deactivate
    if !@current_store.integrator.footer_script_included? && @current_store.deactivate!
      redirect_to stores_settings_url(view: 'settings'), flash: { notice: "In-Store Reserver app has been deactivated." }
    else
      redirect_to stores_settings_url(view: 'settings', deactivation: "failed")
    end
  end

  ##
  # GET /stores/activate
  def activate
    if @current_store.integrator.snippet_footer_code_found? && @current_store.integrator.footer_script_included?  && @current_store.activate!
      redirect_to stores_settings_url(view: 'settings'), flash: { notice: "In-Store Reserver app has been activated." }
    else
      redirect_to stores_settings_url(view: 'settings', activation: "failed")
    end
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
        format.html { redirect_to params[:next_url].presence || stores_settings_url(view: 'settings'), flash: { error: "Store settings was not saved. Please contact our support team for help." }}
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
      if !params[:view] && params[:action] != 'templates' && params[:action] != 'help' && params[:action] != 'upgrade' && @current_store.reservations.count > 0
        redirect_to reservations_path(platform_order_id: params[:id])
      end
      true
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def store_params
    params.fetch(:store, {}).permit(Store::PERMITTED_PARAMS)
  end

end
