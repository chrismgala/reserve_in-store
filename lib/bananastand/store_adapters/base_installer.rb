module Bananastand
  module StoreAdapters
    class BaseInstaller < BaseStoreAdapter
      delegate :api, :products, :orders, :customers, :platform_data, to: :store

      def installation_instructions_url; ENV['FRONTEND_WEBSITE_URL'] + 'resources/custom_installation.html'; end
      def install!
        cancel_uninstallation!
      end
      def reinstall!; install!; end

      def cancel_uninstallation!
        store.has_not!(:uninstalled) if store.has?(:uninstalled)

        if store.uninstallation.present?
          store.uninstallation.cancel!
        end

        IntercomStoreSyncWorker.perform_async(store.id)
      end

      def needs_manual_installation?
        false
      end

      def instructions_template_path
        "#{store.type_code}/installation/instructions"
      end

      ##
      # IS there a page that instructs users on how to setup Fera AI for this platform? If so, override the path here.
      # @return [String|NiLClass] path if string, if nil then assumed that there is no additional setup instructions
      def custom_setup_path
        nil
      end

      def uninstall!(skip_email: false)
        log("Store uninstall! was called.")

        cancel_uninstallation!

        # Create installation record
        uninstallation = Uninstallation.create(account: store.account,
                                               store_data: store.as_json,
                                               store_id: store.id,
                                               store_created_at: store.created_at,
                                               store_type: store.type,
                                               store_url: store.url,
                                               subscription_data: store.subscription.as_json)

        unless skip_email || store.account.stores.count > 1 || store.free? # If they have more than 1 store probably just cleaning stuff up.
          # Say sorry to the users
          store.account.users.each do |user|
            user.send_goodbye_email!(store)
          end
        end

        # Schedule store for deletion
        uninstallation.schedule!

        schedule_data_deletion_emails(uninstallation) unless skip_email

        Bananastand::InternalNotificationService.new_uninstall(store)

        IntercomStoreSyncWorker.perform_async(store.id)
      rescue => e # Don't die if we fail to do any of these things
        Raven.capture_exception(e)
        error("Failed to uninstall store properly. User was not notified. Message was: #{e.message}.")
      end

      ##
      # If an Uninstallation record exists for this store and it is still alive, then the store is
      # @return [Boolean]
      def uninstalled?
        return @is_uninstalled unless @is_uninstalled.nil?
        # the has? flag lets us check if they are scheduled for uninstall as well.
        # Also we need to force it to return boolean so we don't re-run this method several times
        @is_uninstalled = !!(store.uninstallation.present? || store.has?(:uninstalled))
      end

      def uninstall_instructions_html
        ""
      end

      def fera_js_url(add_store_domain = false)
        url = "#{ENV['CDN_JS_BASE_PATH']}fera.js"
        url = "#{url}?shop=#{store.canonical_domain}" if add_store_domain
        url
      end
      alias_method :bananastand_js_url, :fera_js_url

      ##
      # Store adapters should override this url if they ever need re-authorization with oauth.
      # This way we can easily create links in the view to re-authenticate.
      # @return [String|NiLClass]
      def api_authorization_url
        nil
      end

      private

      def schedule_data_deletion_emails(uninstallation)
        if store.created_at > 3.days.ago
          log("Skipping data deletion email because store was created in the last 3 days.")
          return
        end

        if store.shoppers.count < 50
          log("Skipping data deletion email because store has less than 50 shopper journeys.")
          return
        end

        # Figure out when we should send the email
        send_at = uninstallation.scheduled_for - 24.hours
        
        send_to = store.account.primary_contact

        UserNotifications::DeletingDataWarningEmail.create_and_send_in!(send_at, store: store, user: send_to)
      end
    end
  end
end
