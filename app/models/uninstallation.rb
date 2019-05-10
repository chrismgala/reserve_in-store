class Uninstallation < ApplicationRecord
  def self.create_from_store!(store)
    uninstallation = new

    uninstallation.store_id = store.id

    data = {}
    data[:store] = store.as_json
    data[:users] = store.users.limit(10).to_a.as_json
    data[:reservations] = store.reservations.limit(10).to_a.as_json
    data[:locations] = store.locations.limit(10).to_a.as_json
    data[:subscription] = store.subscription.as_json
    uninstallation.data = data

    uninstallation.save!
    uninstallation
  end
end
