module Api
  module V1
    class ReservationsController < ApiController
      protect_from_forgery with: :null_session, only: [:create]

      ##
      # GET /api/v1/modal
      def modal
        @product_title = params[:product_title]
        @variant_title = params[:variant_title]
      end

      ##
      # POST /api/v1/store_reservations
      def create
        @reservation = Reservation.new(reservation_params.merge(store: @store))
        if @reservation.save
          render json: 'test', status: :ok
        else
          render json: @reservation.errors, status: :unprocessable_entity
        end
      end

      private

      def reservation_params
        params.fetch(:reservation, {}).except(:location_name).permit(:customer_name, :customer_email, :customer_phone, :location_id,
                                                                     :platform_product_id, :platform_variant_id, :comments, :fulfilled)
      end

    end
  end
end
