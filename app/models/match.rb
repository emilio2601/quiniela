class Match < ApplicationRecord
  has_many :picks, dependent: :destroy
  has_many :users, through: :picks

  enum :status, { scheduled: "scheduled", finished: "finished" }, default: "scheduled"

  validates :home_team, :away_team, :kickoff_at, presence: true
  validates :number, presence: true, uniqueness: true

  # Matches 1..72 are the group stage; 73..104 are the knockout bracket, whose
  # teams stay as openfootball placeholders (W97, 3CDFG, …) until the results
  # poller resolves them.
  GROUP_STAGE_MATCHES = 72

  scope :locked, -> { where(kickoff_at: ..Time.current) }
  scope :open_for_picks, -> { where(kickoff_at: Time.current..) }

  def knockout?
    number.to_i > GROUP_STAGE_MATCHES
  end

  # Derived W/D/L from the scores. Returns :home, :draw, or :away once both
  # scores are present, otherwise nil.
  def result
    return nil unless home_score && away_score

    if home_score > away_score
      :home
    elsif home_score < away_score
      :away
    else
      :draw
    end
  end

  # Picks lock at kickoff — see Pick#kickoff_not_passed.
  def locked?
    kickoff_at <= Time.current
  end
end
