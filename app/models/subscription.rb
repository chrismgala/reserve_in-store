class Subscription < ApplicationRecord
  belongs_to :store

  delegate :price, :code, :name, :features, :limits, :trial_days, to: :plan

  ##
  # @return [Plan] A READONLY Plan based on the stored data from the plan when this subscription was created.
  def plan
    return @plan if @plan.present?

    @plan = Plan.new
    @plan.attributes.keys.each do |k|
      plan_attribute_val = plan_attributes.to_h.with_indifferent_access[k]
      next unless plan_attribute_val.present?

      @plan.send("#{k}=", plan_attribute_val)
    end

    @plan
  end

  ##
  # Assigns the plan ID and plan attributes values to this subscription.
  # Later calling #plan will return a readonly object that contains these attributes.
  # @param plan [Plan] Plan model to use in creating the subscription.
  def plan=(plan)
    self.plan_attributes = plan.attributes
  end

  ##
  # @param currency [String|Symbol] What currency should the price be in? Defaults to USD
  # @param round: [Boolean] If true the number will be rounded to the nearest whole number
  # @return [String] Price of the subscription per month
  def nice_price(currency = :usd, round: true)
    converted_price = Bananastand::CurrencyConverter.convert(price, to: currency)
    converted_price = converted_price.round if round
    ActionController::Base.helpers.number_to_currency(converted_price).to_s.chomp('.00').chomp('.00') + "/mo"
  end
end
