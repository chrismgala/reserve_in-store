module Bananastand
  class SlackNotifier

    def self.ping_sales_and_marketing(msg)
      if ENV['SLACK_WEBHOOK_URL_SALES_AND_MARKETING'].present?
        sales_and_marketing.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [Sales_And_Marketing] #{msg}")
      end
    end

    def self.ping_reviews(msg)
      if ENV['SLACK_WEBHOOK_URL_REVIEWS'].present?
        reviews.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [Reviews] #{msg}")
      end
    end

    def self.ping_urgent_engineering(msg)
      if ENV['SLACK_WEBHOOK_URL_URGENT_ENGINEERING'].present?
        urgent_engineering.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [Urgent Engineering] #{msg}")
      end
    end

    def self.ping_engineering(msg)
      if ENV['SLACK_WEBHOOK_URL_ENGINEERING'].present?
        engineering.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [Engineering] #{msg}")
      end
    end

    def self.ping_general(msg)
      if ENV['SLACK_WEBHOOK_URL_GENERAL'].present?
        general.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [General] #{msg}")
      end
    end

    def self.ping_server(msg)
      if ENV['SLACK_WEBHOOK_URL_SERVER'].present?
        server.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [Server] #{msg}")
      end
    end

    def self.ping_uninstallations(msg)
      if ENV['SLACK_WEBHOOK_URL_UNINSTALLATIONS'].present?
        uninstallations.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [Uninstallations] #{msg}")
      end
    end

    def self.ping_support(msg)
      if ENV['SLACK_WEBHOOK_URL_SUPPORT'].present?
        support.ping(msg)
      else
        ForcedLogger.warn("Bananastand.SlackNotifier: [Support] #{msg}")
      end
    end

    private

    def self.urgent_engineering
      @urgent_engineering ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_URGENT_ENGINEERING'])
    end

    def self.engineering
      @engineering ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_ENGINEERING'])
    end

    def self.sales_and_marketing
      @sales_and_marketing ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_SALES_AND_MARKETING'])
    end

    def self.reviews
      @reviews ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_REVIEWS'])
    end

    def self.general
      @general ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_GENERAL'])
    end

    def self.server
      @server ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_SERVER'])
    end

    def self.uninstallations
      @uninstallations ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_UNINSTALLATIONS'])
    end

    def self.support
      @support ||= Slack::Notifier.new(ENV['SLACK_WEBHOOK_URL_SUPPORT'])
    end
  end
end
