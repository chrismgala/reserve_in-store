class LocationsController < LoggedInController
  before_action :set_location, only: [:show, :edit, :update, :destroy]

  ##
  # GET /locations
  def index
    @locations = @current_store.locations.order(id: :asc).page params[:page]
  end

  ##
  # GET /locations/new
  def new
    @location = Location.new(store: @current_store)
  end

  ##
  # POST /locations
  def create
    @location = Location.new(location_params.merge(store_id: @current_store.id))

    respond_to do |format|
      if @location.save
        flash[:notice] = "Location was successfully created."
        format.js { render "layouts/flash_messages" }
        format.json { render json: @location, status: :ok }
      else
        flash[:error] = @location.errors.full_messages.join("\n")
        format.js { render "layouts/flash_messages" }
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
        flash[:notice] = "Location was successfully updated."
        format.js { render  :template => "layouts/flash_messages.js.erb"}
        format.json { render :show, status: :ok, location: @location }
      else
        flash[:error] = @location.errors.full_messages.join("\n")
        format.js { render  :template => "layouts/flash_messages.js.erb"}
        format.json { render json: @location.errors, status: :unprocessable_entity }
      end
    end
  end

  ##
  # DELETE /locations/1
  def destroy
    @location.destroy
    respond_to do |format|
      format.html { redirect_to locations_path, notice: 'Location was successfully deleted.' }
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
    params.fetch(:location, {}).permit(Location::PERMITTED_PARAMS)
  end

end
