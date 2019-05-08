module Bananastand
  module StoreAdapters
    class BaseReviewChecker < BaseStoreAdapter
      attr_accessor :cache_lifetime

      def initialize(store, options = {})
        super(store, options)
        @cache_lifetime ||= 15.seconds
      end

      def can_check_if_review_written?; false; end

      ##
      # @param [Boolean|NilClass] if nil then we cannot check for a review, otherwise true/false whether the review has been provided.
      def check_review_written?(opts = {}); nil; end

      ##
      # Sync all reviews (AppStoreReview models) for this platform
      # By default looks only at the first page unless the num_pages_to_check is specified in the options
      # @param opts [Hash] (optional) Set num_pages_to_check option to decide how many pages the system will sync
      def self.sync!(opts = {}); end

      ##
      # Sync all reviews (AppStoreReview models) for all platforms in the rails application.
      # By default looks only at the first page unless the num_pages_to_check is specified in the options
      # @param opts [Hash] (optional) Set num_pages_to_check option to decide how many pages the system will sync
      def self.sync_all_platforms!(opts = {})
        $store_platforms.each do |store_platform|
          sync_platform!(store_platform, opts)
        end

        I.increment("#{self.to_s.gsub('::','.')}.#{__method__.to_s.gsub(/[^a-zA-Z_\-]/, '')}")
      end

      ##
      # Sync all reviews (AppStoreReview models) for this platform
      # By default looks only at the first page unless the num_pages_to_check is specified in the options
      # @param store_platform [Symbol|String] store platform code to sync all AppStoreReview models for
      # @param opts [Hash] (optional) Set num_pages_to_check option to decide how many pages the system will sync
      def self.sync_platform!(store_platform, opts = {})
        checker_klass = "#{store_platform.titleize}::ReviewChecker".constantize
        checker_klass.sync!(opts)
      rescue NameError => e
        # Constant does not exist so don't try to sync the app store for that thing
      end

      ##
      # @param [Boolean] Can this type of store write reviews?
      def can_write_reviews?; false; end

      def app_store_url
        @app_store_url ||= store.app_store_review_url.to_s.split("?").first.strip.split('#').first.strip
      end
    end
  end
end
