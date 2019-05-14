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
        bad_request!("Public key must be present in the parameters in order to use the API.") unless public_key.present?
        @store = Store.find_by!(public_key: public_key)
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
