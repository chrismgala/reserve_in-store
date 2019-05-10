class AppInstalledJob < ActiveJob::Base
  def perform(shop_domain:, webhook: {})
    store = Store.find_by(shopify_domain: shop_domain)

    store.name = store.shopify_settings['name']
    store.platform_store_id = store.id
    store.save!

    new_store(store)

    store.sync_locations!

    UpdateFooterJob.perform_later(store.id)
  end

  private

  ##
  # Send a notification to the team on Slack about a new store signup.
  # @param store [Store]
  def new_store(store)
    msg = "👶  #{store_markdown(store)} signed up."
    Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_GENERAL']).ping(msg)
  end

  def store_markdown(store)
    return "_store that no longer exists_" if store.blank?
    store_name = store.name.size > 22 ? "#{store.name[0..20]}..." : store.name
    "[:shopify:](#{store.url.to_s.strip} #{store_name})"
  end
end
