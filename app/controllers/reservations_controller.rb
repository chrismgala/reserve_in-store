class ReservationsController < ShopifyApp::AuthenticatedController
  before_action :set_store
  before_action :set_reservation, only: [:show, :edit, :update, :destroy]

  ##
  # GET /reservations
  def index
    @reservations = @current_store.reservations.order(id: :asc).page params[:page]
    @reservation = Reservation.new
    # WTD temporary line for testing
    # response.headers['X-Frame-Options'] = 'ALLOWALL'
  end

  ##
  # POST /reservations
  def create
    @reservation = Reservation.new(reservation_params.merge(store: @current_store))

    respond_to do |format|
      if @reservation.save
        format.html { redirect_to reservations_path, notice: 'reservation was successfully created.' }
        format.json { render :reservations, status: :ok }
      else
        format.html { redirect_to reservations_path, flash: { error: @reservation.errors.full_messages.join("\n") } }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  ##
  # PATCH/PUT /reservations/1
  def update
    respond_to do |format|
      if @reservation.update(reservation_params)
        format.html { redirect_to reservations_path, notice: 'reservation was successfully updated.' }
        format.json { render :show, status: :ok, reservation: @reservation }
      else
        format.html { redirect_to reservations_path, flash: { error: @reservation.errors.full_messages.join("\n") } }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  ##
  # DELETE /reservations/1
  def destroy
    @reservation.destroy
    respond_to do |format|
      format.html { redirect_to reservations_url, notice: 'reservation was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  # Set current store
  def set_store
    @current_store = Store.find_by(shopify_domain: current_shopify_domain)
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_reservation
    @reservation = @current_store.reservations.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def reservation_params
    # params.fetch(:reservation, {}).require(:name, :email).permit(:address, :country, :state, :city, :phone)
    params.fetch(:reservation, {}).permit(:customer_name, :customer_email, :customer_phone, :location_id,
                                          :platform_product_id, :platform_variant_id, :comments, :fulfilled)
  end

end
