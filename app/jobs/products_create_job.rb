class ProductsCreateJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    @store = Store.find_by(shopify_domain: shop_domain)

    return if @store.blank?

    @store.cached_api.clear_product_cache(webhook[:id])
    @store.cached_api.product(webhook[:id])

  rescue ActiveResource::ClientError => e
    if e.try(:response).try(:code).to_i == 429
      ForcedLogger.log(e, store: @store.try(:id))
    else
      raise e
    end
  end
end
