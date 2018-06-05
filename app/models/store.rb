class Store < ActiveRecord::Base
  include ShopifyApp::SessionStorage
  has_many :locations
  has_many :reservations
end
