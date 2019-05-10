module Bananastand
  module RescuesNotFound
    extend ActiveSupport::Concern

    included do
      rescue_from ActiveRecord::RecordNotFound do |exception|
        not_found(exception)
      end unless Rails.env.development?
    end

    protected

    def bad_request!(message = nil)
      Rails.logger.info "A bad request was triggered manually from an ApplicationController"

      raise ActionController::BadRequest.new('request', message.present? ? StandardError.new(message) : nil)
    end

    def not_found(exception = nil)
      Rails.logger.warn("Triggered routing error manually from ApplicationController." + (exception.present? ? "Specific error was: #{exception.inspect}" : ''))

      raise ActionController::RoutingError.new('Page not Found')
    end

  end
end
