module Bananastand
  module StoreAdapters
    class BaseSyncer < BaseStoreAdapter
      delegate :api, :products, :orders, :customers, :platform_data, to: :store

      def can_sync?; false; end
      def sync_products!(params = {}); false; end
      def sync_platform_product_ids!(platform_product_ids); false; end

      def download_product(platform_product_id, platform_data = nil); raise NotImplementedError, "Store classes must implement the download_product method and implement all required api methods to pull the correct data."; end
      def sync_customer_ids!(platform_customer_ids); raise NotImplementedError, "Store classes must implement the sync_customer_ids! method and implement all required api methods to pull the correct data."; end
      def download_order(platform_order_id, platform_data = nil); raise NotImplementedError, "Store classes must implement the download_order method and implement all required api methods to pull the correct data."; end
      def sync_store_info!; raise NotImplementedError, "sync_store_info! must be implemented by parent!"; end
      def resync_out_of_sync_products; raise NotImplementedError, "resync_out_of_sync_products! not implemented!"; end
      def determine_trailing_1d_data; raise NotImplementedError, "#determine_trailing_1d_data must be implemented"; end

      ##
      # Memorized hash of default filters to send to #api.orders
      # Used by #estimate_avg_monthly_rev
      # @return [Hash] filters to use
      def order_estimation_filters
        raise NotImplementedError, "order_estimation_filters! must be implemented by parent!";
      end

      ##
      # Calculate the total revenue from a list of platform orders provided.
      # Used by #estimate_avg_monthly_rev
      # @param platform_orders [Array<Object>] Collection of platform order objects that contain data about the order
      # @return [Float] total revenue from a list of orders
      def total_rev_from_orders(platform_orders)
        raise NotImplementedError, "total_rev_from_orders! must be implemented by parent!";
      end

      def sync_preliminary_data!
        determine_trailing_1d_data
        store.save!
        store
      end

      def load_platform_orders(page, throttle)
        api.orders(order_estimation_filters.merge({ page: page,
                                                    cache_expires_in: 15.minutes,
                                                    throttle: throttle
                                                  }))
      end

      def sample_location
        nil
      end

      ##
      # Calculate a quick estimate (limited by the number of seconds in time_limit) of the store's average monthly revenue.
      # @param time_limit [Integer] (optional) Number of seconds to limit the estimation process at. default: 30.seconds
      # @param throttle [Integer] (optional) How long should we wait between API requests? default: 1.second
      # @return [Float|NilClass] Estimated average monthly revenue for this store or nil if you can't figure it out (or don't have enough data)
      def estimate_avg_monthly_rev(time_limit: 30.seconds, throttle: 1.second)
        start_time = Time.now.to_f
        p = 1
        last_order = nil
        first_order = nil
        total_rev = 0
        current_throttle = 0
        order_count = 0

        while (platform_orders = load_platform_orders(p, current_throttle)).try(:any?)
          current_throttle = throttle

          first_order = platform_orders.first if first_order.blank?
          last_order = platform_orders.last
          order_count += platform_orders.count
          total_rev += total_rev_from_orders(platform_orders)

          if Time.now.to_f - start_time > time_limit
            log("Hit time limit - breaking.")
            break
          end

          p += 1
        end

        # If we have 3 or less orders then we should assume that we cannot estimate the average monthly rev
        if order_count <= 3 || total_rev == 0
          log("Found less than 4 orders to estimate monthly revenue based on so skipping average monthly revenue estimation. Found #{order_count} order(s).")
          return nil
        end

        from = platform_order_created_at(last_order)
        to = platform_order_created_at(first_order)
        days_of_orders = ((to.to_f - from.to_f)/60/60/24)

        if days_of_orders/2 > order_count
          log("Cannot estimate average monthly revenue because we need at least 1 order every 2 days on average to get a usable number and we currently have #{days_of_orders} days of orders and #{order_count} total number of orders in that period.")
          return nil
        end

        if days_of_orders < 7 && order_count < 100
          log("Cannot estimate average monthly revenue because we need at least 7 days of orders and we currently only have #{days_of_orders}")
          return nil
        end

        rev_per_sec = total_rev.to_f / (to.to_f - from.to_f)
        est_avg_monthly_rev = (rev_per_sec *60*60*24*30.42).round(2)

        log("Estimated avg monthly revenue across #{p} page(s) of orders. From #{from} to #{to} (#{days_of_orders.floor} months) the merchant made $#{total_rev.round(2)} USD. Average monthly revenue is: $#{est_avg_monthly_rev}")

        est_avg_monthly_rev
      end

      def platform_order_created_at(platform_order)
        DateTime.strptime(platform_order.created_at)
      end

      def back_process_order_events!(date_range: 31.days.ago..Time.current, limit: 100)
        old_orders = orders.order(platform_created_at: :desc).where(platform_created_at: date_range).limit(limit)

        # First we need to preload download all the customers for these orders
        platform_customer_ids = old_orders.to_a.map(&:platform_customer_id).uniq.reject(&:blank?)
        if platform_customer_ids.any? # Only do this if we have customer ids to look at.
          sync_customer_ids!(platform_customer_ids)
        end

        old_orders.each do |order|
          order.process!(false)
        end
      end

      def update_order_from_data!(platform_order_id, platform_data = nil)
        if platform_order_id.is_a?(Order)
          order = platform_order_id
          platform_order_id = order.platform_order_id
        else
          order = orders.find_by(platform_order_id: platform_order_id.to_s)
        end

        if order.blank?
          order = download_order(platform_order_id, platform_data)
          log("order downloaded", order: order.id)
        else
          order.load_from_platform(platform_data)
          order.save!
          log("order updated", order: order.id)
        end

        order
      end

      def update_product_from_data!(platform_product_id, platform_data = nil)
        store.product(platform_product_id, platform_data)
      end

      def product(platform_product_id, platform_data = nil)
        products.find_by(platform_product_id: platform_product_id.to_s) || download_product(platform_product_id, platform_data)
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid # Failsafe for the race condition
        products.find_by(platform_product_id: platform_product_id.to_s)
      end

      def order(platform_order_id, platform_data)
        orders.find_by(platform_order_id: platform_order_id.to_s) || download_order(platform_order_id, platform_data)
      end

      def syncing?
        store.last_sync_started_at.present? && store.last_sync_ended_at.blank?
      end

      def synced?
        store.last_sync_started_at.present? && store.last_sync_ended_at.present?
      end

      ##
      # Fetch logo from their website using the API
      # @deprecated this is turned off for now until we can run it in paralell since it slows down the install process by quite a few seconds.
      def fetch_logo_from_api
        store.logo_url = fetch_store_logo
      rescue StandardError => e
        # Ignore errors with fetching logo
        warn("Failed to pull shopify store logo from the API: #{e.message}")
      end

      ##
      # @deprecated Not used as of December 12, 2017 but leaving it here in case we want to use it again
      def fetch_store_logo
        store_page_nok = Nokogiri(store_page_html)
        logo_imgs = store_page_nok.css('img[itemprop="logo"]')
        return nil if logo_imgs.blank?
        potential_logos = logo_imgs.map{|img| img.attributes['src'].value if img.attributes['src'].present? }.reject { |v| v.blank? }
        if potential_logos.size > 0
          best_match = potential_logos.select{|x|x=~/logo\./}
          if best_match.size > 0
            best_match.first
          else
            best_match.sample(1).first
          end
        else
          nil
        end
      end

      private

      def store_page_html
        HTTParty.get(store.url, timeout: 5.seconds).to_s
      end

    end
  end
end
