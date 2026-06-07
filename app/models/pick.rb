class Pick < ApplicationRecord
  belongs_to :user
  belongs_to :match

  enum :prediction, { home: 0, draw: 1, away: 2 }

  validates :prediction, presence: true
  validates :user_id, uniqueness: { scope: :match_id }
  validate :kickoff_not_passed
  validate :no_draw_in_knockout

  # True once the match has finished and our prediction matches the result.
  def correct?
    match.finished? && match.result == prediction.to_sym
  end

  private

  # The one hard rule: picks lock at kickoff. Reject any create or update once
  # the match has started so the scoring denominator stays well-defined.
  def kickoff_not_passed
    return if match.nil? || match.kickoff_at.nil?

    if match.locked?
      errors.add(:base, "Picks lock at kickoff and can no longer be changed")
    end
  end

  # A knockout always produces a winner (extra time, then penalties), so "draw"
  # isn't a valid call there — you pick which team goes through.
  def no_draw_in_knockout
    errors.add(:prediction, "isn't an option for a knockout") if draw? && match&.knockout?
  end
end
