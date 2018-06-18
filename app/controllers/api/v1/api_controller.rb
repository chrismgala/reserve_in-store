module Api
  module V1
    class ApiController < ActionController::Base
      include RescuesNotFound

      before_action :authenticate!

      private

      def authenticate!
        # bad_request!("Secret and Public key must both be present in the parameters or headers in order to use the API. See https://www.bananastand.io/resources/private-rest-api for more information.") unless secret_key.present? && public_key.present?
        bad_request!("Public key must be present in the parameters in order to use the API.") unless public_key.present?
        # @store = Store.find_by!(secret_key: secret_key, public_key: public_key)
        @store = Store.find_by!(public_key: public_key)
      end

      # def secret_key
      #   @secret_key ||= request.headers['X-Secret-Key'] || params[:secret_key].to_s.strip
      # end

      def public_key
        # @public_key ||= request.headers['X-Public-Key'] || params[:public_key].to_s.strip
        @public_key ||= params[:store_pk].to_s.strip
      end

      # def account
      #   @store.account
      # end
    end
  end
end
