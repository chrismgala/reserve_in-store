class UpdateFooterJob < ActiveJob::Base
  def perform(store_id)
    store = Store.find(store_id)

    store.integrator.integrate! unless store.integrator.integrated?

    store.integrator.install_footer!
  end
end
