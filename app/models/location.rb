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
  alias_method :google_maps_url, :google_map_url

  def to_liquid
    {
      'id' => id,
      'platform_location_id' => platform_location_id,
      'name' => name,
      'google_map_url' => google_map_url,
      'address' => address,
      'formatted_address' => formatted_address,
      'country' => country,
      'custom_html' => custom_html
    }
  end

  ##
  # Filter out empty address fields, and returns a string containing city, state and postal code.
  # @return [String] in the form of 'City, State, ZIP/Postal code'
  def formatted_address
    [city, state, zip].reject { |c| c.empty? }.join(', ')
  end

  def load_from_shopify(shopify_attr)
    loc_attr = shopify_attr
    loc_attr.transform_values!(&:to_s)
    loc_attr[:address] = loc_attr[:address1] + " " + loc_attr[:address2]
    loc_attr[:state] = loc_attr[:province]
    loc_attr[:country] = Carmen::Country.coded(loc_attr[:country_code]).name
    update_attributes(loc_attr.slice(*Location::PERMITTED_PARAMS))
  end

  ##
  # Create a new Location object from a Shopify::Location object
  # This object is invalid until it is provided a store_id (save with .update(store_id: id))
  # @param [Shopify::Location] shopify_loc A Shopify Location object
  # @return [Location] a new Location object made from the Shopify::Location
  def self.new_from_shopify(shopify_loc, store)
    loc = Location.new
    shopify_attr = shopify_loc.try(:attributes).with_indifferent_access || shopify_loc.with_indifferent_access
    loc.platform_location_id = shopify_attr[:id]
    loc.load_from_shopify(shopify_attr)
    loc.store_id = store.id
    loc.email = store.email
    loc.store
    loc
  end

end
