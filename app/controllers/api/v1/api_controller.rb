module Api
  module V1
    class ApiController < ActionController::Base
      include RescuesNotFound
      include ::Bananastand::AllowsEmbedding

      before_action :authenticate!

      private

      ##
      # Check if public key is present and then set the store
      def private_authenticate!
        bad_request!("Secret key must be present in the parameters in order to use this API endpoint.") unless secret_key.present?
        @store = Store.find_by!(public_key: public_key, secret_key: secret_key)
      end

      ##
      # Check if public key is present and then set the store
      def authenticate!
        Rails.logger.info("API_AUTH: Starting authentication - public_key: #{public_key.present? ? 'PRESENT' : 'MISSING'}, public_key_value: #{public_key.inspect}")

        bad_request!("Public key must be present in the parameters in order to use the API.") unless public_key.present?

        Rails.logger.info("API_AUTH: Public key present, attempting to find store")
        @store = Store.find_by!(public_key: public_key)
        Rails.logger.info("API_AUTH: Store found - store_id: #{@store.id}, shopify_domain: #{@store.shopify_domain}, active: #{@store.active?}")
      rescue ActiveRecord::RecordNotFound => e
        Rails.logger.error("API_AUTH: Store not found for public_key: #{public_key.inspect}")
        raise e
      rescue StandardError => e
        Rails.logger.error("API_AUTH: Unexpected authentication error - public_key: #{public_key.inspect}, error: #{e.message}, class: #{e.class}")
        raise e
      end
      ##
      # @return [String] the store public key sent within the query string
      def secret_key
        @secret_key ||= (params[:store_sk].presence || params[:secret_key].presence || headers['X-SECRET-KEY']).to_s.strip
      end

      ##
      # @return [String] the store public key sent within the query string
      def public_key
        @public_key ||= (params[:store_pk].presence || params[:public_key].presence || headers['X-PUBLIC-KEY']).to_s.strip
      end
    end
  end
end
