module Api
  module V1
    class StoresController < ApiController
      # respond_to :json

      def settings
        # respond_with(:top_msg => @store.top_msg, :success_msg => @store.success_msg)
        render json: {:top_msg => @store.top_msg, :success_msg => @store.success_msg}
        # respond_to do |format|
        #   format.json { render json: {:top_msg => @store.top_msg, :success_msg => @store.success_msg} }
        # end
      end

    end
  end
end
