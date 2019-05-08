module Bananastand
  module StoreAdapters
    class BaseStoreAdapter
      extend ActiveSupport::Concern

      attr_accessor :store, :options

      def initialize(store, options = {})
        @store = store
        @options = options.to_h.with_indifferent_access
      end

      def log(message, context = {})
        ForcedLogger.log(message, context.merge(store: store.try(:id), class: self.class.to_s))
      end

      def warn(message, context = {})
        ForcedLogger.warn(message, context.merge(store: store.try(:id), class: self.class.to_s))
      end

      def error(message, context = {})
        ForcedLogger.error(message, context.merge(store: store.try(:id), class: self.class.to_s))
      end
    end
  end
end
