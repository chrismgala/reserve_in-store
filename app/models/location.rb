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

end
