class Plan < ApplicationRecord

  def terms
    "Up to #{limits['locations']} #{'location'.pluralize(limits['locations'])}"
  end
end
