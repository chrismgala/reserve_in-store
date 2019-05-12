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
        locations = @store.locations.page(params[:page]).per(250)

        if secret_key.present?
          private_authenticate!
        else
          locations = locations.to_a.map{ |loc| loc.to_public_h }
        end

        render json: locations
      end

      private


    end
  end
end
