class Location < ActiveRecord::Base
  belongs_to :store
  has_many :reservations, dependent: :destroy

  validates :name, :email, presence: true
  validates_associated :store
end
