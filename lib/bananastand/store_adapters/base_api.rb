module Bananastand
  module StoreAdapters
    class BaseApi < BaseStoreAdapter

      def initialize(store, options = {})
        super(store, options)
      end

      def store_information
        {}
      end

      def absolute_hook_url(hook_path)
        "#{ENV['BASE_APP_URL']}/#{hook_path}?store_sk=#{@store.secret_key}"
      end

      def create_discount(opts: nil)
        raise NotImplementedError, "Must implement `create_discount`!"
      end

      def destroy_discount(title: nil)
        raise NotImplementedError, "Must implement `destroy_discount`!"
      end

      def discount_code_active?(title: nil)
        raise NotImplementedError, "Must implement `discount_code_active?`!"
      end
    end
  end
end
