class ApplicationRecord < ActiveRecord::Base
  include HasFlags

  self.abstract_class = true
end
