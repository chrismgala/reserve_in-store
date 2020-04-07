module Admins
  class SubscriptionsController < ::Admins::ApplicationController
    before_action :load_store_for_admin

    ##
    # GET /admin/stores/:store_id/subscriptions
    def index
      @subscription = @store.subscription
    end

    private

    def load_store_for_admin
      @store = Store.find(params[:store_id].to_i)
    end
  end
end
