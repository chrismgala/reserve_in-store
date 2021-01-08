module Shopify
  class Api < Bananastand::StoreAdapters::BaseApi

    #################################################################################################################
    # API Fetch methods
    #################################################################################################################

    def customer(id, params = {})
      ShopifyAPI::Customer.find(id)
    end

    def customers(params = {})
      ShopifyAPI::Customer.where(params)
    end

    def inventory_levels(params = {})
      results = []

      levels = ShopifyAPI::InventoryLevel.where(params)
      results = levels.to_a

      while levels.next_page?
        levels = levels.fetch_next_page
        results += levels.to_a
      end

      results
    end

    def order(id, params = {})
      ShopifyAPI::Order.find(id)
    end

    def orders(params = {})
      throttle = params.delete(:throttle)

      if params[:cache_expires_in]
        cache_key = "stores/#{@store.id}/api/orders/#{params.except(:created_at_min).inspect}"
        platform_orders = Rails.cache.fetch(cache_key, expires_in: params.delete(:cache_expires_in)) do

          uncached_platform_orders = ShopifyAPI::Order.where(params)

          sleep(throttle) if throttle.present?

          uncached_platform_orders
        end
      else

        platform_orders = ShopifyAPI::Order.where(params)

        sleep(throttle) if throttle.present?
      end

      platform_orders
    end

    def products(params = {})
      ShopifyAPI::Product.where(params)
    end

    def product(id, params = {})
      ShopifyAPI::Product.find(id)
    end

    def variant(id)
      ShopifyAPI::Variant.find(id)
    end

    def custom_collections(params = {})
      ShopifyAPI::CustomCollection.where(params)
    end

    def smart_collections(params = {})
      ShopifyAPI::SmartCollection.where(params)
    end

    def script_tags; ShopifyAPI::ScriptTag; end
    def recurring_application_charge; ShopifyAPI::RecurringApplicationCharge; end
    def usage_charge; ShopifyAPI::UsageCharge; end

    def load_asset(asset_path)
      asset(asset_path)
    rescue ActiveResource::ResourceNotFound => e
      nil
    end

    def assets
      return @assets if @assets.present?

      @assets = ShopifyAPI::Asset.all
    end

    def asset(path)
      ShopifyAPI::Asset.find(path)
    end

    def store_information(params = {})
      ShopifyAPI::Shop.current
    end
    alias_method :store_info, :store_information


    #################################################################################################################
    # Installation Methods:
    #################################################################################################################

    ##
    # @param [Object]  snippet_path Path of the snipped to check and update if necessary
    # @param [Object]  snippet_content Content to ensure is in the path requested
    # @return [Boolean] True if successful, false otherwise.
    def ensure_snippet!(snippet_path, snippet_content)

      snippet = load_asset(snippet_path)

      if snippet.blank?
        snippet = ShopifyAPI::Asset.new(key: snippet_path)
      end

      # Update content with latest footer script
      snippet.value = snippet_content
      snippet.save
    end

    ##
    # @return [Array] A list of all asset keys that we can (we think) possibly inject any code into.
    def all_tpl_that_can_inject_into
      @all_tpl_that_can_inject_into ||= injectable_assets.map { |asset| asset.key }
    end

    ##
    # @return [Boolean] Does the store have this asset with the give key?
    def store_has_asset?(key)
      return false if key.blank? # Failsafe

      injectable_assets.any? { |asset| asset.try(:key).to_s.downcase == key.to_s.downcase }
    end

    ##
    # @return [Array] ShopifyAPI::Asset instances (without value attributes!) of assets that we could probably (not definitely) inject into. This means no JS, sass, or CSS files for example.
    def editable_assets
      return [] if assets.blank? # Fail-safe if the connection failed.

      @editable_assets ||= assets.find_all do |asset|
        key = asset.try(:key).to_s.downcase
        !(key.include?('.svg') || key.include?('.jpg') || key.include?('.gif')  || key.include?('.png') || key.include?('icon-') || key.include?('.eot') || key.include?('.otf') || key.include?('.ttf') || key.include?('.woff'))
      end
    end

    ##
    # @return [Array] ShopifyAPI::Asset instances (without value attributes!) of assets that we could probably (not definitely) inject into. This means no JS, sass, or CSS files for example.
    def injectable_assets
      return [] if assets.blank? # Fail-safe if the connection failed.

      @injectable_assets ||= editable_assets.find_all do |asset|
        key = asset.try(:key).to_s.downcase
        key.include?('.liquid') && !(key.include?('.js') || key.include?('.css') || key.include?('.scss'))
      end
    end

    def load_tpl_and_key(template)
      if template.is_a?(String)
        template_key = template
        tmp = ShopifyAPI::Asset.find(template_key)
      else
        tmp = template
        template_key = tmp.key
      end
      [tmp, template_key]
    end

    ##
    # Creates a credit in the Shopify billing system against the Fera.ai app.
    # @param amount [Float] Amount to credit the account with
    # @param description [String] A description of why the credit is being issued and by whom.
    def credit_billed_subscription(amount, description)
      ShopifyAPI::ApplicationCredit.create(amount: amount, description: description, test: !Rails.env.production?)
    end

    def install_script_tag!(src)
      return true if ShopifyAPI::ScriptTag.all.any? # There should only be one

      ShopifyAPI::ScriptTag.create(src: src, event: 'onload')
    end

    def webhooks
      log("Called ShopifyAPI::Webhook.all")
      ShopifyAPI::Webhook.all
    end

    def locations
      ShopifyAPI::Location.all
    end

    ##
    # Memorized version of #webhooks so we're not doing frequent calls to the API
    def all_webhooks
      return @all_webhooks if @all_webhooks.present?

      @all_webhooks = webhooks.to_a
    end

    def install_webhook!(topic, hook_path)
      this_webhook = all_webhooks.find{ |h| h.topic == topic }

      if this_webhook.blank?
        log("Called ShopifyAPI::Webhook.create", topic: topic)
        ShopifyAPI::Webhook.create(topic: topic, address: absolute_hook_url(hook_path), format: "json")
        true
      end

      false
    end

    #################################################################################################################
    # API Creation Methods
    #################################################################################################################

    def destroy_discount(title: nil)
      return false unless @store.has_discount_access?

      destroy_price_rule(title: title)
    end

    def discount_code_active?(title: nil)
      return false unless @store.has_discount_access?

      prs = price_rules_with_title(title: title)
      if prs.blank?
        warn("No price rules found with title: #{title}")
        return false
      end

      discounts = ShopifyAPI::DiscountCode.find(:all, :params => {:price_rule_id => prs.first.id})
      discounts.any?
    end

    ##
    # Creates a new Price Rule and Discount Code.
    # If either Price Rule or Discount fail to save, then both are destroyed and nothing happens.
    # @param opts {Object} of discount & price rule parameters
    def create_discount(opts: nil)
      return false unless @store.has_discount_access? && opts.present?

      price_rule = new_price_rule(opts: opts)
      log("Called ShopifyAPI::PriceRule.create")
      unless price_rule.save
        error("Failed to save price rule: #{price_rule.inspect}")
        return false
      end

      discount_code = new_discount(title: opts[:title], price_rule_id: price_rule.id)
      log("Called ShopifyAPI::DiscountCode.save")

      if discount_code.save
        discount_code
      else
        error("Failed to save discount code: #{discount_code.inspect}")
        unless price_rule.destroy
          error("Additionally, failed to destroy price rule as a cleanup: #{price_rule.inspect}")
        end

        false
      end
    end

    private

    def destroy_price_rule(title: nil)
      price_rules_with_title(title: title).each do |b|
        unless b.destroy
          error("Failed to destroy price rule with title #{title}: #{b.inspect}")
          return false
        end
      end

      true
    end

    ##
    # Shopify currently only supports finding Price Rules by ids, not titles.
    # We have to find them all and only return the ones we need.
    #
    # @return [Array] of PriceRule objects
    def price_rules_with_title(title: nil)
      ShopifyAPI::PriceRule.all.to_a.select{|pr| pr.title == title}
    end

    ##
    # @param title [String] of price rule. Shopify recommends keeping this identical to the Price Rule title.
    # @param price_rule_id [Id] of the associated price rule
    def new_discount(title: nil, price_rule_id: nil)
      discount_code = ShopifyAPI::DiscountCode.new
      discount_code.prefix_options[:price_rule_id] = price_rule_id
      discount_code.code = title
      discount_code
    end

    def discount_value_formatted(opts: nil)
      return unless opts.present?
      return "-100" if opts[:target_type] == "shipping_line"
      opts[:value].to_i
    end

    ##
    # Usage limits must be >= 1
    # @return {Integer || nil}
    def usage_limit_formatted(usage_limit)
      return nil if usage_limit.to_i <= 0
      usage_limit.to_i
    end

    def prereq_min_total_formatted(min_total)
      return nil unless min_total.present?
      { greater_than_or_equal_to: min_total }
    end

    ##
    # Create (but dont save) a new Shopify Price Rule. This is the brains of the discount.
    # @param opts [Object] of price rule options.
    def new_price_rule(opts: nil)
      ShopifyAPI::PriceRule.new(
          price_rule: {
              title: opts[:title],
              target_type: opts[:target_type] || "line_item",
              target_selection: opts[:target_selection] || "all",
              allocation_method: opts[:allocation_method] || "each",
              value_type: opts[:value_type] || "percentage",
              value: discount_value_formatted(opts: opts) || "-100.0",
              once_per_customer: opts[:once_per_customer] || false,
              usage_limit: usage_limit_formatted(opts[:usage_limit]) || nil,
              customer_selection: opts[:customer_selection] || "all",
              prerequisite_subtotal_range: prereq_min_total_formatted(opts[:prerequisite_subtotal_range]),
              prerequisite_shipping_price_range: opts[:prerequisite_shipping_price_range],
              entitled_country_ids: opts[:entitled_country_ids] || nil,
              starts_at: opts[:starts_at] || "2017-11-19T17:59:10Z",
              ends_at: opts[:ends_at] || nil
          })
    end
  end
end
