class Location < ActiveRecord::Base
  belongs_to :store
  has_many :reservations, dependent: :destroy

  validates :name, :email, presence: true
  validates_associated :store

  ##
  # TODO rdoc
  def google_map_url
    'https://www.google.com/maps/search/?api=1&query=' + URI.encode(address+' '+city+' '+state+' '+country+' '+zip)
  end
end
