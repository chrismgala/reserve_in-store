module Api
  module V1
    class ApiController < ActionController::Base
      include RescuesNotFound

      before_action :authenticate!

      private

      ##
      # Check if public key is present and then set the store
      def authenticate!
        bad_request!("Public key must be present in the parameters in order to use the API.") unless public_key.present?
        @store = Store.find_by!(public_key: public_key)
      end

      ##
      # @return [String] the store public key sent within the query string
      def public_key
        @public_key ||= params[:store_pk].to_s.strip
      end
    end
  end
end
