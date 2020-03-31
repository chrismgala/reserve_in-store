module Admins
  class StoresController < ::Admins::ApplicationController

    def store
      @store = Store.find(params[:store_id].to_i)
    end  
    
    def index
      @stores = Store.order(created_at: :desc)
      @stores = @stores.page(params[:page]).per(20)
    end

    # GET /admin/stores/:store_id/show
    def show
      store
      @user = User.where(store_id: params[:store_id].to_i)
    end

    def deactivate
      store.deactivate!
      
      redirect_to admin_store_tools_path(store), notice: 'Reserve In-store has been deactivated.'
    end

    def activate
      store.activate!
      
      redirect_to admin_store_tools_path(store), notice: 'Reserve In-store has been activated.'
    end

    def tools
      store
    end

    def reintegrate
      UpdateFooterJob.new.perform(store.id)
      
      redirect_to admin_store_tools_path(store), notice: 'Reserve In-store has been re-installed into this store.'
    end

    #GET /admin/stores/:store_id/settings
    def settings
      @current_store = store
      @locations = store.locations
    end
    
    # PUT/PATCH /stores/settings
    def save_settings
      @current_store = store
      respond_to do |format|
        save_params = store_params

        # Ensure values are boolean if they are enabled/disabled flags
        store_params.keys.each do |key|
          if key.to_s =~ /.+(_enabled)/
            unless store_params[key].is_a?(TrueClass) || store_params[key].is_a?(FalseClass)
              store_params[key] = store_params[key].to_bool
            end
          end
        end

        @current_store.assign_attributes(save_params)

        if @current_store.save
          format.html { redirect_to params[:next_url].presence || stores_settings_url, notice: 'Store settings were successfully updated.' }
          format.json { render :settings, status: :ok }
        else
          format.html { render :settings }
          format.json { render json: @current_store.errors, status: :unprocessable_entity }
        end
      end
    end

    def locations
       @locations = store.locations
    end

    def templates
      store
    end  

    # Never trust parameters from the scary internet, only allow the white list through.
    def store_params
      params.fetch(:store, {}).permit(Store::PERMITTED_PARAMS)
    end  
  end
end
