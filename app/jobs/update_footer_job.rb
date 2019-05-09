class UpdateFooterJob < ActiveJob::Base
  def perform(store_id)
    Store.find(store_id).integrator.install_footer!
  end
end
