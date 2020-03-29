module Admins
  class DashboardController < ::Admins::ApplicationController
    before_action :authenticate_admin!

    def index
    end
    
    private

  end
end
