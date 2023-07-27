class StoresController < LoggedInController
  include IconsHelper

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
    require_user! || return
  end

  ##
  # GET /stores/webhooks
  def webhooks
  end

  ##
  # GET /stores/deactivate
  def deactivate
    if !@current_store.integrator.footer_script_included? && @current_store.deactivate!
      render json: { store: @current_store, type: "success", message: "In-Store Reserver app has been deactivated." }
    else
      if @current_store.integrator.footer_script_included?
        render json: { store: @current_store, type: "error", message: "Footer script is still included in your store theme. In-Store Reserver app could not be deactivated." }
      else
        render json: { store: @current_store, type: "error", message: "In-Store Reserver app could not be deactivated. Please contact our support team for help." }
      end
    end
  end

  def footer_code_integrated_svg_icon
    return success_svg_icon if @current_store.integrator.footer_script_included?

    failed_svg_icon
  end

  def snippet_integrated_svg_icon
    return success_svg_icon if @current_store.integrator.snippet_footer_code_found?

    failed_svg_icon
  end

  ##
  # GET /stores/activate
  def activate
    message = "In-Store Reserver app could not be activated."
    footer_script_not_included = "<p>#{ footer_code_integrated_svg_icon } Footer code: layout/theme.liquid</p>"
    snippet_not_found = "<p>#{ snippet_integrated_svg_icon } Snippet: snippets/reserveinstore_footer.liquid</p>"

    if @current_store.integrator.snippet_footer_code_found? && @current_store.integrator.footer_script_included?  && @current_store.activate!
      render json: { store: @current_store, type: "success", message: "In-Store Reserver app has been activated." }
    else
      if !@current_store.integrator.snippet_footer_code_found? || !@current_store.integrator.footer_script_included?
        render json: { store: @current_store, type: "error", message: "#{ message } #{ snippet_not_found } #{ footer_script_not_included } " }
      else
        render json: { store: @current_store, type: "error", message: "#{ message } Please contact our support team for help." }
      end
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
