class StoresController < LoggedInController

  ##
  # GET /stores/settings
  def settings
    unless ShopifyAPI::ScriptTag.all.any?
      redirect_to setup_integrate_path
    end
  end

  ##
  # PUT/PATCH /stores/settings
  def save_settings
    respond_to do |format|
      if @current_store.update(store_params)
        format.html { redirect_to stores_settings_url, notice: 'Store settings were successfully updated.' }
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
    params.fetch(:store, {}).permit(:top_msg, :success_msg, :email_template, :show_phone, :show_comments)
  end

end
