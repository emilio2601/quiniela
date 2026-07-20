class User < ApplicationRecord
  has_many :picks, dependent: :destroy
  has_many :matches, through: :picks

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Find an existing player by name (case-insensitively), or nil. The pool
  # closed with the 2026 tournament, so an unrecognised name is no longer
  # signed up as a new player — sign-in only, for players already on the board.
  def self.identify(name)
    where("LOWER(name) = ?", name.to_s.strip.downcase).first
  end
end
