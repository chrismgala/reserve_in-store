class StoresController < ShopifyApp::AuthenticatedController
  before_action :set_store

  ##
  # GET /stores/settings
  def settings
  end

  ##
  # PUT/PATCH /stores/settings
  def save_settings
    respond_to do |format|
      if @store.update(store_params)
        format.html { redirect_to stores_settings_url, notice: 'Store settings were successfully updated.' }
        format.json { render :settings, status: :ok }
      else
        format.html { render :settings }
        format.json { render json: @store.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_store
    @store = Store.find_by(shopify_domain: current_shopify_domain)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def store_params
    params.fetch(:store, {}).permit(:top_msg, :success_msg, :email_template, :show_phone, :show_comments)
  end

end
