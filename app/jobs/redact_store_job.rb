# ShopifyApp's WebhooksManager uses ActiveJob by default
# For now, Rails will run the jobs inline
class RedactStoreJob < ActiveJob::Base
  def perform(shop_domain:, webhook:)
    # Store is already deleted.
    # We keep this job around to keep our webhook reception simple and respond a 200.
  end
end
