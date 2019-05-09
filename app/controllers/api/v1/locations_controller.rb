module Api
  module V1
    class LocationsController < ApiController

      ##
      # GET /api/v1/locations/modal
      def modal

        liquid_vars[:current_location] = @store.locations.find(params[:location_id]) if params[:location_id].present?

        render html: Liquid::Template
                       .parse(@store.choose_location_modal_tpl_in_use)
                       .render!(@store.frontend_tpl_vars.stringify_keys)
                       .html_safe
      end


      ##
      # GET /api/v1/locations.json
      def index
        render json: @store.locations.to_a
      end

      private


    end
  end
end
