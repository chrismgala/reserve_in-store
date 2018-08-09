class Location < ActiveRecord::Base
  belongs_to :store
  has_many :reservations, dependent: :destroy

  validates :name, :email, presence: true
  validates_associated :store

  ##
  # TODO rdoc
  def google_map_url
    'https://www.google.com/maps/search/?api=1&query=' + URI.encode(address + ' ' + city + ' ' + state + ' ' + country + ' ' + zip)
  end

  ##
  # TODO rdoc
  def self.default_custom_html
    ''
  end

  ##
  # TODO rdoc
  def formatted_address
    [city, state, country, zip].reject { |c| c.empty? }.join(', ')
  end

end
