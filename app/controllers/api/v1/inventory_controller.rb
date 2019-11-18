module Api
  module V1
    class InventoryController < ApiController

      ##
      # GET /api/v1/inventory.json?product_id=#{product_id}
      # This method was previously named 'index', however it was changed because we
      # wanted to introduce the ability to get multiple product inventories at once.
      # As such, in order follow controller naming conventions this method was renamed
      # as 'show' because it only fetches inventory for one product at a time.
      def show
        fetcher = InventoryFetcher.new(@store, params[:product_id])

        render json: fetcher.levels[params[:product_id]]

      rescue ActiveResource::ResourceNotFound
        not_found("Product or Variant not found")
      end

      ##
      # GET /api/v1/inventories.json?product_ids=#{product_id},#{product_id}
      def index
        fetcher = InventoryFetcher.new(@store, params[:product_ids])

        render json: fetcher.levels
      rescue ActiveResource::ResourceNotFound
        not_found("Products or Variants were not found")
      end

      private

    end
  end
end
