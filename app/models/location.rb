class Location < ActiveRecord::Base
  belongs_to :store
  has_many :reservations, dependent: :destroy

  validates :name, :email, presence: true
  validates_associated :store

  PERMITTED_PARAMS = [:name, :email, :address, :country, :state, :city, :phone, :zip, :custom_html, :platform_location_id, :details, :product_tag_filter, :visible_in_cart, :visible_in_product]
  PUBLIC_ATTRIBUTES = [:id, :name, :address, :country, :state, :city, :zip, :google_maps_url, :platform_location_id, :formatted_address, :details, :product_tag_filter, :visible_in_cart, :visible_in_product]


  alias_attribute :custom_html, :details
  ##
  # @return [String] Google Map url searching for current store's location
  def google_map_url
    return "" if full_address.strip.blank?
    'https://www.google.com/maps/search/?api=1&query=' + URI.encode(full_address)
  end
  alias_method :google_maps_url, :google_map_url

  def to_public_h
    PUBLIC_ATTRIBUTES.map{ |attr| [attr, send(attr)] }.to_h.with_indifferent_access
  end

  def to_liquid
    {
      id: id,
      platform_location_id: platform_location_id,
      name: name,
      google_map_url: google_map_url,
      address: address,
      formatted_address: formatted_address,
      country: country,
      city: city,
      state: state,
      zip: zip,
      province: state,
      region: state,
      phone: phone,
      email: email,
      product_tag_filter: product_tag_filter,
      custom_html: details, # legacy reverse-compatibility
      details: details,
      visible_in_cart: visible_in_cart,
      visible_in_product: visible_in_product
    }.stringify_keys
  end

  def full_address
    "#{address} #{city} #{state} #{country} #{zip}".strip
  end

  ##
  # Filter out empty address fields, and returns a string containing city, state and postal code.
  # @return [String] in the form of 'City, State, ZIP/Postal code'
  def formatted_address
    [city, state, zip].reject { |c| c.blank? }.join(', ')
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

    shopify_attr = if shopify_loc.is_a?(ShopifyAPI::Location)
                     shopify_loc.try(:attributes)
                   else
                     shopify_loc
                   end.to_h.with_indifferent_access

    loc.platform_location_id = shopify_attr[:id]
    loc.load_from_shopify(shopify_attr)
    loc.store_id = store.id
    loc.email = store.email
    loc.store
    loc
  end

end
