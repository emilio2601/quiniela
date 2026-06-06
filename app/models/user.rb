class User < ApplicationRecord
  has_many :picks, dependent: :destroy
  has_many :matches, through: :picks

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Find an existing player by name (case-insensitively) or create one.
  # Returns the user, or an unpersisted invalid record if the name is unusable.
  def self.identify(name)
    name = name.to_s.strip
    where("LOWER(name) = ?", name.downcase).first || create(name: name)
  end
end
