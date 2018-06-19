module Api
  module V1
    class ReservationsController < ApiController
      # respond_to :json

      def modal
        # @locations = @store.locations

        @reservation = Reservation.new
        render_to_string :modal, locals: {store_pk: @store_pk}
        # render html: '<div>html goes here</div>'.html_safe
        # render json: @locations
        # respond_to do |format|
        #   format.json { render json: @locations }
        # end

        # TODO Not sure what it is doing looks like a logger or something like that
        # I.increment("#{self.class.to_s.gsub('::', '.')}.index")
      end

      def create
        @reservation = Reservation.new(reservation_params.merge(store: @store))
        @reservation.save
      end

      private

      def reservation_params
        # params.fetch(:reservation, {}).require(:name, :email).permit(:address, :country, :state, :city, :phone)
        params.fetch(:reservation, {}).permit(:customer_name, :customer_email, :customer_phone, :location_id,
                                              :platform_product_id, :platform_variant_id, :comments, :fulfilled)
      end

    end
  end
end
