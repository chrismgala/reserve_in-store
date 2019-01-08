class Location < ActiveRecord::Base
  belongs_to :store
  has_many :reservations, dependent: :destroy

  validates :name, :email, presence: true
  validates_associated :store

  PERMITTED_PARAMS = [:name, :email, :address, :country, :state, :city, :phone, :zip, :custom_html]

  ##
  # @return [String] Google Map url searching for current store's location
  def google_map_url
    'https://www.google.com/maps/search/?api=1&query=' + URI.encode(address + ' ' + city + ' ' + state + ' ' + country + ' ' + zip)
  end

  ##
  # Filter out empty address fields, and returns a string containing city, state and postal code.
  # @return [String] in the form of 'City, State, ZIP/Postal code'
  def formatted_address
    [city, state, zip].reject { |c| c.empty? }.join(', ')
  end

  ##
  # Create a new Location object from a Shopify::Location object
  # This object is invalid until it is provided a store_id (save with .update(store_id: id))
  # @param [Shopify::Location] shopify_loc A Shopify Location object
  # @return [Location] a new Location object made from the Shopify::Location
  def self.newFromShopify(shopify_loc)
    loc_attr = shopify_loc.attributes
    loc_attr.transform_values!(&:to_s)
    loc_attr[:address] = loc_attr[:address1] + " " + loc_attr[:address2]
    loc_attr[:state] = loc_attr[:province]
    Location.new(loc_attr.slice(*Location::PERMITTED_PARAMS))
  end

end
