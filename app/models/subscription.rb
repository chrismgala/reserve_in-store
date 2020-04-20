class Subscription < ApplicationRecord
  belongs_to :store

  delegate :price, :code, :name, :features, :limits, :trial_days, to: :plan

  scope :total_active_mrr, -> {
    where(store_id: Store.all.find_all{ |s| s.connected? && (s.trial_days_left || 0) < 1 }.map{ |s| s.id }).sum("(plan_attributes ->> 'price')::float")
  }

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
  # @note Make sure the subscription.store already exists before running this line or else the per location pricing may not work properly.
  # @param plan [Plan] Plan model to use in creating the subscription.
  def plan=(plan)
    plan_attr = plan.attributes

    plan_attr['limits'] ||= {}

    if store.present?
      plan_attr['price'] = plan.price_for_store(store)
      plan_attr['limits']['locations'] = store.distinctly_named_location_count
    end

    plan_attr['limits'] = plan_attr['limits'].merge(store.plan_overrides.to_h['limits'].to_h)

    self.plan_attributes = plan_attr

    @plan = nil # To force the #plan method to reload

    self
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
