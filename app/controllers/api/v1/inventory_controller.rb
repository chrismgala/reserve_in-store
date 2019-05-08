module Api
  module V1
    class InventoryController < ApiController

      ##
      # GET /api/v1/inventory.json?product_id=#{product_id}
      def index
        fetcher = InventoryFetcher.new(@store, params[:product_id])

        render json: fetcher.levels

      rescue ActiveResource::ResourceNotFound
        not_found("Product or Variant not found")
      end

      private

    end
  end
end
