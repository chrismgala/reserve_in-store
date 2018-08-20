module Api
  module V1
    class ReservationsController < ApiController
      protect_from_forgery with: :null_session, only: [:create]

      ##
      # GET /api/v1/modal
      def modal
        @product_title = params[:product_title]
        @variant_title = params[:variant_title]
        @line_item = params[:line_item]
        @price = @store.price('%.2f' % (params[:price].to_f / 100))
      end

      ##
      # POST /api/v1/store_reservations
      def create
        @product_info = params.slice(:product_title, :product_handle, :variant_title)
        @reservation = Reservation.new(reservation_params.merge(store: @store))
        if @reservation.save_and_email(@product_info)
          render json: {}, status: :ok
        else
          render json: @reservation.errors.full_messages, status: :unprocessable_entity
        end
      end

      private

      def reservation_params
        params.fetch(:reservation, {}).permit(Reservation::PERMITTED_PARAMS - [:fulfilled])
      end

    end
  end
end
