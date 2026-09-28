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
        Rails.logger.info("INVENTORY_API: Starting inventory fetch for product_id=#{params[:product_id]}, store_id=#{@store.try(:id)}, shopify_domain=#{@store.try(:shopify_domain)}")
        Rails.logger.info("INVENTORY_API: Request params: #{params.except(:controller, :action).inspect}")

        fetcher = InventoryFetcher.new(@store, params[:product_id])

        Rails.logger.info("INVENTORY_API: Fetcher created, calling levels for product_id=#{params[:product_id]}")
        result = fetcher.levels[params[:product_id]]
        Rails.logger.info("INVENTORY_API: Successfully fetched inventory for product_id=#{params[:product_id]}, result keys: #{result.try(:keys).inspect}")

        render json: result

      rescue ActiveResource::ResourceNotFound => e
        Rails.logger.error("INVENTORY_API: Product/Variant not found - product_id=#{params[:product_id]}, store_id=#{@store.try(:id)}, error=#{e.message}")
        not_found("Product or Variant not found")
      rescue ActiveResource::ClientError => e
        Rails.logger.error("INVENTORY_API: Shopify API ClientError - product_id=#{params[:product_id]}, store_id=#{@store.try(:id)}, response_code=#{e.try(:response).try(:code)}, error=#{e.message}")
        raise e
      rescue ActiveResource::UnauthorizedAccess => e
        Rails.logger.error("INVENTORY_API: Shopify API Unauthorized - product_id=#{params[:product_id]}, store_id=#{@store.try(:id)}, shopify_domain=#{@store.try(:shopify_domain)}, error=#{e.message}")
        raise e
      rescue ActiveResource::ConnectionError => e
        Rails.logger.error("INVENTORY_API: Shopify API ConnectionError - product_id=#{params[:product_id]}, store_id=#{@store.try(:id)}, error=#{e.message}")
        raise e
      rescue StandardError => e
        Rails.logger.error("INVENTORY_API: Unexpected error - product_id=#{params[:product_id]}, store_id=#{@store.try(:id)}, error=#{e.message}, class=#{e.class}")
        Rails.logger.error("INVENTORY_API: Backtrace: #{e.backtrace[0..5].join("\n")}")
        raise e
      end

      ##
      # GET /api/v1/inventories.json?product_ids=#{product_id},#{product_id}
      def index
        fetcher = InventoryFetcher.new(@store, params[:product_ids])

        render json: fetcher.levels
      rescue ActiveResource::ResourceNotFound
        not_found("Products or Variants were not found")
      end

      ##
      # GET /api/v1/stock.json?product_ids=#{product_id},#{product_id}
      def stock
        fetcher = InventoryFetcher.new(@store, params[:product_ids])

        render json: fetcher.load_levels_stock_avail
      rescue ActiveResource::ResourceNotFound
        not_found("Products or Variants were not found")
      end
      private

    end
  end
end
