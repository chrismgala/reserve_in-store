module Bananastand
  module StoreAdapters
    class BaseSampler < BaseStoreAdapter

      ##
      # @return [NilClass|String] nil if failed or a string for the URL to the cart that will also add a product to the cart
      def loaded_cart_url
        raise NotImplementedError, "sampler#loaded_cart_url must be implemented"
      end

      def cart_url
        raise NotImplementedError, "sampler#cart_url must be implemented"
      end

      def detect_product_url
        product.try(:url)
      end

      def detect_category_url
        raise NotImplementedError, "sampler#detect_category_url must be implemented"
      end

      def download_sample_products!
        raise NotImplementedError, "sampler#download_sample_products must be implemented"
      end

      def product(download_if_none = true)
        store.products.first
      end

      def checkout_url
        store.url_to('checkout')
      end

      def download_preview_data
        preview_urls
        preview_css
        true
      end

      def preview_css
        {}
      end

      def preview_urls
        @preview_urls ||= Rails.cache.fetch("sampler/preview_urls/store-#{store.id}/cache_key-#{store.cache_timestamp_val(:products_last_updated_at)}", expires_in: 1.day) do
          gen_preview_urls
        end
      end

      def custom_preview_url_manager
        @custom_preview_url_manager ||= ::Bananastand::Campaigns::CustomPreviewUrlManager.new(store)
      end

      ##
      # @return custom orverride category for the URL to a category page
      def override_sample_category_url
        store.sample_data.to_h['category'].to_h['url'] if store.sample_data.to_h['category'].to_h['url'].present?
      end

      ##
      # @return custom orverride category for the URL to a category page
      def category_url
        return store.sample_data.to_h['category'].to_h['url'] if store.sample_data.to_h['category'].to_h['url'].present?
        Rails.cache.fetch("stores/#{store.id}/base_sampler/detect_category_url", expires_in: 1.week) { detect_category_url }
      end

      ##
      # @return custom orverride product for the URL to a product detail page
      def override_sample_product_url
        store.sample_data.to_h['product'].to_h['url'] if store.sample_data.to_h['product'].to_h['url'].present?
      end
      
      ##
      # @return custom orverride product for the URL to a product detail page
      def product_url
        return store.sample_data.to_h['product'].to_h['url'] if store.sample_data.to_h['product'].to_h['url'].present?
        detect_product_url
      end

      private

      def gen_preview_urls
        {
          home:           custom_preview_url_manager.preview_urls[:home].presence || store.home_url || store.home_url,
          cart:           custom_preview_url_manager.preview_urls[:cart].presence || cart_url || store.home_url,
          product_view:   custom_preview_url_manager.preview_urls[:product_view].presence || product_url || store.home_url,
          product_list:   custom_preview_url_manager.preview_urls[:product_list].presence || category_url || store.home_url,
          checkout:       custom_preview_url_manager.preview_urls[:checkout].presence || checkout_url || store.home_url,
          order_complete: custom_preview_url_manager.preview_urls[:order_complete].presence || checkout_url || store.home_url
        }
      end

      def read_url(url)
        page = crawler.read_url(url)
        return nil if page.nil?

        # If we get redirected to the password page it means that we can't check for integration
        # This is specific to Shopify. (just noting it since it seems like most of the other code in this file are not specific to shopify and can be abstracted later)
        if page.uri.to_s.downcase.include?('/password')
          nil
        else
          page
        end
      end

      def crawler
        @crawler ||= ::Bananastand::StoreCrawler.new(store, raise_errors: false)
      end

    end
  end
end

