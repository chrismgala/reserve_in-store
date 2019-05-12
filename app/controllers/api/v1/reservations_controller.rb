module Api
  module V1
    class ReservationsController < ApiController
      protect_from_forgery with: :null_session, only: [:create]

      ##
      # GET /api/v1/reservations/modal
      def modal
        liquid_vars = @store.frontend_tpl_vars.merge({ line_items: [] })

        if params[:product_title].present?
          liquid_vars[:line_items] << {
            title: params[:product_title],
            variant_title: params[:variant_title],
            price: @store.currency(params[:price].to_f/100).to_s.chomp('.00').chomp('.0')
          }.stringify_keys
        else
          # todo pass line items from frontend
        end

        render html: Liquid::Template.parse(@store.reserve_product_modal_tpl_in_use).render!(liquid_vars.stringify_keys).html_safe
      end

      ##
      # POST /api/v1/store_reservations
      def create
        @reservation = Reservation.new(reservation_params.merge(store: @store))
        if @reservation.save_and_email(params.permit(:product_title, :product_handle, :variant_title))
          render json: {}, status: :ok
        else
          render json: @reservation.errors.full_messages, status: :unprocessable_entity
        end
      end

      def index
        private_authenticate!

        reservations = @store.reservations

        reservations.where(fulfilled: params[:fulfilled].to_bool) if params[:fulfilled].present?
        reservations.where(location_id: params[:location_id].to_i) if params[:location_id].present?
        reservations.where("customer_name ILIKE ?", "%#{params[:customer_name]}%") if params[:customer_name].present?
        reservations.where("customer_email ILIKE ?", "%#{params[:customer_email]}%") if params[:customer_email].present?
        reservations.where("customer_phone ILIKE ?", "%#{params[:customer_phone]}%") if params[:customer_phone].present?

        render json: reservations.page(params[:page]).per(250).map{ |obj| obj.to_api_h }
      end

      private

      def reservation_params
        params.fetch(:reservation, {}).permit(Reservation::PERMITTED_PARAMS - [:fulfilled])
      end

    end
  end
end
