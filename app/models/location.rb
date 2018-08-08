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
    '<div class="ris-row ris-weekDays">
  <di>
    <ul>
      <li>
        <div>
          <p>Mon - Fri</p>
          <p>10 AM - 9 PM</p>
        </div>
      </li>
      <li>
        <div>
          <p>Sat</p>
          <p>9:30 AM - 6 PM </p>
        </div>
      </li>
      <li>
        <div>
          <p>Sun</p>
          <p>11 AM - 6 PM</p>
        </div>
      </li>
    </ul>
  </di>
</div>

<div class="ris-row ris-phone">
  <p>Phone</p>
  <p>123.456.7890</p>
</div>'
  end

  ##
  # TODO rdoc
  def formatted_address
    [city, state, country, zip].reject { |c| c.empty? }.join(', ')
  end

  # TODO Not efficient not seems to be correct OMG
  # def self.example_location
  #   Location.new('')
  #   byebug
  # end
end
