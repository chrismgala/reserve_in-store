class Plan < ApplicationRecord
  def terms
    "Up to #{location_limit} #{'location'.pluralize(location_limit)}"
  end

  def location_limit
    limits['locations'].to_i
  end

  def price_per_extra_location
    return 9.0 if price.blank? || location_limit.to_i < 1 # Failsafe even though this should never be the case
    price.to_f / location_limit.to_i
  end

  def price_for_store(store)
    if store.custom_fixed_price.present? && store.custom_fixed_price > 0
      return store.custom_fixed_price
    end

    locations_left = location_limit - store.distinctly_named_location_count
    if locations_left >= 0
      price
    else
      price + (price_per_extra_location*(-locations_left))
    end
  end
end
