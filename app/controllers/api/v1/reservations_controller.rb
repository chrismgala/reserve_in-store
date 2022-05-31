module Api
  module V1
    class ReservationsController < ApiController
      protect_from_forgery with: :null_session, only: [:create]

      ##
      # GET /api/v1/reservations/modal
      def modal
        liquid_vars = @store.frontend_tpl_vars(product_tag_filter: params[:product_tag_filter], current_page: params[:current_page])

        if params[:product_title].present?
          liquid_vars[:cart] = load_legacy_params
        elsif params[:cart].present?
          liquid_vars[:cart] = load_cart_params
        else
          bad_request!("Params must include either product information or cart info.")
          return
        end

        tpl = @store.reserve_modal_tpl_in_use

        # Load in product data if we are referencing it in the template and it is not in the data
        if tpl.include?('product.') || tpl.include?('variant.')
          # Load item products
          liquid_vars[:items] = load_product_data(liquid_vars[:items])
        end

        if params[:current_page] == "cart"
          liquid_vars[:is_cart_page] = true
        end

        content = Liquid::Template.parse(tpl).render!(liquid_vars.deep_stringify_keys).html_safe

        respond_to do |format|
          format.html { render html: content }
          format.json { render json: { content: content } }
        end

      end

      ##
      # POST /api/v1/store_reservations
      def create
        @reservation = Reservation.new(reservation_params.merge(store: @store))
        if @reservation.save_and_email
          render json: { message: "Reservation was successfully created.", reservation_id: @reservation.id }, status: :ok
        else
          render json: @reservation.errors.full_messages, status: :unprocessable_entity
        end
      end

      def index
        private_authenticate!

        reservations = @store.reservations

        reservations = reservations.where(fulfilled: params[:fulfilled].to_bool) if params[:fulfilled].present?
        reservations = reservations.where(location_id: params[:location_id].to_i) if params[:location_id].present?
        reservations = reservations.where("customer_name ILIKE ?", "%#{params[:customer_name]}%") if params[:customer_name].present?
        reservations = reservations.where("customer_email ILIKE ?", "%#{params[:customer_email]}%") if params[:customer_email].present?
        reservations = reservations.where("customer_phone ILIKE ?", "%#{params[:customer_phone]}%") if params[:customer_phone].present?

        reservations = reservations.order(id: 'desc')
        reservations = reservations.page(params[:page]).per(250)

        render json: reservations.map{ |obj| obj.to_api_h }
      end

      private

      def load_cart_params
        cart = params[:cart].to_unsafe_h

        cart[:items].to_a.map do |item|
          item[:total_formatted] = format_currency(item[:total])
        end

        cart
      end

      def load_legacy_params
        total = @store.currency(params[:price].to_f/100).to_s.chomp('.00').chomp('.0')
        {
          items: [{
                    title: params[:product_title],
                    product_id: params[:platform_product_id],
                    variant_id: params[:platform_variant_id],
                    variant_title: params[:variant_title],
                    total: total.is_a?(String) ? total.to_f : total/100,
                    total_formatted: total.is_a?(String) ? total : format_currency(total)
                  }]
        }
      end

      def format_currency(num)
        @store.currency(num.to_f/100).to_s.chomp('.00').chomp('.0')
      end

      def load_product_data(items)
        pid = params[:product_id].presence || params[:platform_product_id].presence

        items.map do |item|
          unless item[:product].pesent?
            prod = @store.cached_api.product(pid)

            if prod.present?
              item[:product] = prod.attributes
              item[:product][:price] = @store.currency(prod.price)

              unless item[:variant].pesent?
                vid = params[:variant_id].presence || params[:platform_variant_id].presence
                variant = prod.variants.find{ |v| v[:id] == vid}

                if variant.present?
                  item[:variant] = variant.attributes
                  item[:variant][:price] = @store.currency(variant.price)
                end
              end
            end
          end

          item
        end
      end

      def reservation_params
        @reservation_params ||= params.fetch(:reservation, {}).permit(Reservation::PERMITTED_PARAMS - [:fulfilled])
      end

    end
  end
end
