class LocationsController < LoggedInController
  before_action :set_location, only: [:show, :edit, :update, :destroy]

  ##
  # GET /locations
  def index
    @locations = @current_store.locations.order(id: :asc).page params[:page]
  end

  ##
  # POST /locations
  def create
    @location = Location.new(location_params.merge(store: @current_store))

    respond_to do |format|
      if @location.save
        format.html { redirect_to locations_path, notice: 'location was successfully created.' }
        format.json { render :locations, status: :ok }
      else
        format.html { redirect_to locations_path, flash: { error: @location.errors.full_messages.join("\n") } }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  ##
  # GET /locations/1/edit
  def edit
  end

  ##
  # PATCH/PUT /locations/1
  def update
    respond_to do |format|
      if @location.update(location_params)
        format.html { redirect_to locations_path, notice: 'location was successfully updated.' }
        format.json { render :show, status: :ok, location: @location }
      else
        format.html { redirect_to locations_path, flash: { error: @location.errors.full_messages.join("\n") } }
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  ##
  # DELETE /locations/1
  def destroy
    @location.destroy
    respond_to do |format|
      format.html { redirect_to locations_url, notice: 'location was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_location
    @location = @current_store.locations.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def location_params
    params.fetch(:location, {}).permit(:name, :email, :address, :country, :state, :city, :phone, :zip)
  end

end
