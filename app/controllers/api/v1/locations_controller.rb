module Api
  module V1
    class LocationsController < ApiController
      # respond_to :json

      def index
        @locations = @store.locations
        render json: @locations
        # respond_to do |format|
        #   format.json { render json: @locations }
        # end

        # TODO Not sure what it is doing looks like a logger or something like that
        # I.increment("#{self.class.to_s.gsub('::', '.')}.index")
      end

    end
  end
end
