class ReservationsController < LoggedInController
  include HasSortableColumns

  before_action :set_reservation, only: [:show, :edit, :update, :destroy]

  ##
  # GET /reservations
  def index
    @reservations = @current_store.reservations
    @reservations = @reservations.where(location_id: params[:search_location]) if params[:search_location].present?
    @reservations = @reservations.where(platform_order_id: params[:platform_order_id]) if params[:platform_order_id].present?
    @reservations = @reservations.where('customer_name ILIKE :query OR LOWER(customer_email) LIKE :query', query: "%#{params[:search]}%") if params[:search].present?
    @reservations = @reservations.where(fulfilled: params[:search_status].to_bool) if params[:search_status].present?

    if @current_store.checkout_without_clearing_cart?
      @reservations = @reservations.where("platform_order_id IS NOT NULL") if params[:search_online_pay] != "false"
    end

    @reservations = @reservations.order(column_sort_query).page(params[:page]).includes(:location)
    @reservation = Reservation.new
  end

  ##
  # POST /reservations
  def create
    @reservation = Reservation.new(reservation_params.merge(store: @current_store))

    respond_to do |format|
      if @reservation.save_and_email
        format.html { redirect_to reservations_path, notice: 'Reservation was successfully created.' }
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
        if reservation_params[:fulfilled].to_bool == true && @current_store.reservation_fulfilled_send_notification?
          ReservationMailer.fulfilled_reservation(store: @current_store, reservation:@reservation).deliver_later
        end
        format.html { redirect_to reservations_path, notice: 'Reservation was successfully updated.' }
        format.json { render :show, status: :ok, reservation: @reservation }
      else
        format.html { redirect_to reservations_path, flash: { error: @reservation.errors.full_messages.join("\n") } }
        format.json { render json: @reservation.errors, status: :unprocessable_entity }
      end
    end
  end

  ##
  # POST /reservations/:reservation_id/unfulfilled_send_email
  def unfulfilled_send_email
    @reservation = @current_store.reservations.find(params[:reservation_id])
    @reservation.update(reservation_params)
    respond_to do |format|
      if ReservationMailer.unfulfilled_reservation(store: @current_store, reservation:@reservation).deliver_later
        format.html { redirect_to reservations_path, notice: 'Unfulfilled Reservation Notification was successfully sent.' }
        format.json { render :reservations, status: :ok }
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

  def show
    redirect_to action: :index
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_reservation
    @reservation = @current_store.reservations.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def reservation_params
    params.fetch(:reservation, {}).permit(Reservation::PERMITTED_PARAMS)
  end

  ##
  # Only allow the order table to be sorted by whitelisted columns
  # @return [Array] - Array of strings of appropriate column names
  def sortable_columns
    ['created_at', 'fulfilled', 'location_id']
  end
end
