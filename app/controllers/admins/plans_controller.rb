module Admins
  class PlansController < ::Admins::ApplicationController

    ##
    # GET /admin/plans
    def index
      @plans = Plan.order(price: :asc)
      @plans = @plans.page(params[:page]).per(20)
    end

  end
end
