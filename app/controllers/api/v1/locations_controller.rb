module Api
  module V1
    class LocationsController < ApiController

      ##
      # GET /api/v1/locations/modal
      def modal
        @current_location = @store.locations.find(params[:location_id]) if params[:location_id].present?
      end

      private

    end
  end
end
