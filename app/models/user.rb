class User < ApplicationRecord
  has_many :picks, dependent: :destroy
  has_many :matches, through: :picks

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
