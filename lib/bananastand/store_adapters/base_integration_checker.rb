module Bananastand
  module StoreAdapters
    class BaseIntegrationChecker < BaseStoreAdapter
      EXPIRE_INTEGRATION_STATE_AFTER = 1.day # How often should we update integration state flags?
      EXPIRED_INTEGRATION_LENIENCY = 1.month # How old do integration state flags need to be before we start ignoring them?
      INTEGRATION_SECTIONS = [:home, :product_list, :product_view, :cart, :checkout]

      ##
      # @deprecated In favour of #section_integrated?
      def integrated(integration_type = :product_view)
        section_integrated?(integration_type, true) || store.integration_status.to_h[integration_type.to_s]
      end

      ##
      # @deprecated In favour of #section_integrated?
      def integrated?(integration_type = :product_view)
        !!integrated(integration_type.to_s)
      end

      def check_integrated?(integration_type = :product_view)
        integration_type = integration_type.to_s

        unless integration_type_options.include?(integration_type)
          raise StandardError, "Integration type of #{integration_type.inspect} does not exist."
        end

        is_integrated = send("#{integration_type}_integrated?")

        if store.integrated(integration_type) != is_integrated
          new_integration_status = store.integration_status.to_h
          new_integration_status[integration_type] = is_integrated

          store.integration_status = new_integration_status
          store.integration_status_will_change!
          store.save
        end
        is_integrated
      end

      ##
      # Checks integration and runs store.fail_integration! if integration has failed on anything.
      # Runs in a new thread so nothing is slowed down.
      def check_integration!
        ThreadWithConnection.new do
          ForcedLogger.log('Checking integration in a new thread...', store: store.id)

          unless check_all_integrated? # Everything is integrated, so nothing to notify about.
            campaigns = store.campaigns.to_a

            integration_type_options.each do |integration_type|
              if !integrated?(integration_type) && campaigns.any? { |c| c.requires_integration?(integration_type) && c.running? }
                @store.fail_integration!
                break
              end
            end
          end

          ForcedLogger.log('Finished checking integration.', store: store.id)
        end

        true
      end

      ##
      # Marks the section specified as integrated in the database memory for the #EXPIRE_INTEGRATION_STATE_AFTER time.
      #
      # NOTE: Performs save operation in a new thread if an update needs to happen.
      #
      # @param [*String|Symbol] One or more symbols or strings representing the sections that should be marked as integrated
      def mark_integrated!(*sections)
        now = Time.current.to_i
        updated_state = false
        integration_state = store.integration_state.to_h

        sections.each do |section|
          next unless INTEGRATION_SECTIONS.include?(section.to_s.to_sym)

          last_updated = integration_state[section.to_s].to_i

          if last_updated + EXPIRE_INTEGRATION_STATE_AFTER < now
            integration_state[section.to_s] = now
            updated_state = true
          end
        end

        if updated_state
          ThreadWithConnection.new do
            store.integration_state = integration_state
            store.save!
          end
          true
        else
          false
        end
      end

      ##
      # Tells you if a section is currently integrated
      # @param section [String|Symbol] What section do you want to check? See #INTEGRATION_SECTIONS
      # @param check_time [Boolean] (optional, default: false) If true then we will only consider integration state as
      #                               true if it was updated in the last month (or other #EXPIRED_INTEGRATION_LENIENCY value)
      # @return [Boolean]
      def section_integrated?(section, check_time = false)
        return false if store.integration_state.to_h[section.to_s].blank?
        return true unless check_time

        # If we're checking the time and the integration has not been renewed for over #EXPIRED_INTEGRATION_LENIENCY then assume integration is no longer there.
        store.integration_state.to_h[section.to_s].to_i + EXPIRED_INTEGRATION_LENIENCY < Time.current.to_i
      end

      def check_all_integrated?
        integration_type_options.find_all { |type| section_integrated?(type, true) || check_integrated?(type) }.count == integration_type_options.count
      end

      def check_integrated(section)
        section_integrated?(section, true)
      end

      def all_integrated?
        integration_type_options.find_all { |type| integrated?(type) }.count == integration_type_options.count
      end

      def integration_type_options
        self.class.integration_type_options
      end

      def self.integration_type_options
        INTEGRATION_SECTIONS.map(&:to_s)
      end

      ##
      # @return [Boolean]
      def footer_integrated?
        doc = read_url(store.url)
        return nil if doc.blank?

        has_footer_script?(doc)
      end

      ##
      # @return [Boolean]
      def has_footer_script?(doc)
        html = doc.to_s
        banana_integration = (html.include?('Banana Stand Integration Code') || html.include?('window.__bsio = window.__bsio || [];'))
        fera_integration = (html.include?('Fera.ai Integration Code') || html.include?('window.fera = window.fera || [];'))

        banana_integration || fera_integration
      end

      ##
      # @param html [String]
      # @return [Boolean]
      def product_list_integrated_into?(html)
        doc = Nokogiri::HTML(html)
        doc.css('.banana-list-container').any? && has_footer_script?(doc)
      end

      ##
      # @param html [String]
      # @return [Boolean]
      def product_view_integrated_into?(html)
        doc = Nokogiri::HTML(html)
        doc.css('.banana-view-container').any? && has_footer_script?(doc)
      end

      ##
      # @param html [String]
      # @return [Boolean]
      def cart_integrated_into?(html)
        doc = Nokogiri::HTML(html)
        doc.css('.banana-cart-container').any? && has_footer_script?(doc)
      end

      def read_url(url)
        crawler.read_url(url)
      end

      private

      def crawler
        @crawler ||= ::Bananastand::StoreCrawler.new(store, raise_errors: false)
      end

    end
  end
end
