module Admins
  class UninstallationsController < ::Admins::ApplicationController

    ##
    # GET /admin/uninstallations
    def index
      @uninstalls = Uninstallation.order(id: :desc)
      @uninstalls = @uninstalls.page(params[:page]).per(20)
    end

  end
end
