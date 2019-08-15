class Plan < ApplicationRecord
  def terms
    "Up to #{location_limit} #{'location'.pluralize(location_limit)}"
  end

  def location_limit
    limits['locations'].to_i
  end

  def price_for_store(store)
    locations_left = location_limit - store.distinctly_named_location_count
    if locations_left >= 0
      price
    else
      price + (9.0*(-locations_left))
    end
  end
end
