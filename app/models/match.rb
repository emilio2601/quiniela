class Match < ApplicationRecord
  has_many :picks, dependent: :destroy
  has_many :users, through: :picks

  enum :status, { scheduled: "scheduled", finished: "finished" }, default: "scheduled"

  validates :home_team, :away_team, :kickoff_at, presence: true
  validates :number, presence: true, uniqueness: true
  validates :external_id, uniqueness: true, allow_nil: true
  validates :outcome, inclusion: { in: %w[home draw away] }, allow_nil: true

  # Matches 1..72 are the group stage; 73..104 are the knockout bracket, whose
  # teams stay as openfootball placeholders (W97, 3CDFG, …) until the results
  # poller resolves them.
  GROUP_STAGE_MATCHES = 72

  scope :locked, -> { where(kickoff_at: ..Time.current) }
  scope :open_for_picks, -> { where(kickoff_at: Time.current..) }
  # Real nations have no digit in their name; every openfootball knockout
  # placeholder (W97, 3CDFG, 1A) does — so this finds matches whose teams are
  # resolved. See #teams_known?.
  scope :with_known_teams, -> { where("home_team !~ '[0-9]' AND away_team !~ '[0-9]'") }
  # Pickable = teams resolved and not yet kicked off.
  scope :pickable, -> { open_for_picks.with_known_teams }

  def knockout?
    number.to_i > GROUP_STAGE_MATCHES
  end

  def teams_known?
    [ home_team, away_team ].none? { |team| team.to_s.match?(/\d/) }
  end

  # The match result as :home, :draw, or :away. Prefers the authoritative
  # outcome from the results feed (which knows a penalty-shootout winner even
  # when the score is level); falls back to deriving it from the scores for
  # data that has scores but no recorded outcome (e.g. dev seeds).
  def result
    return outcome.to_sym if outcome.present?
    return nil unless home_score && away_score

    if home_score > away_score
      :home
    elsif home_score < away_score
      :away
    else
      :draw
    end
  end

  # True once the results feed has recorded a shootout score. home_score/away_score
  # then hold the level pre-shootout result; home_penalties/away_penalties the
  # shootout itself.
  def decided_on_penalties?
    home_penalties.present? && away_penalties.present?
  end

  # Picks lock at kickoff — see Pick#kickoff_not_passed.
  def locked?
    kickoff_at <= Time.current
  end

  # For a finished match, how the scoring breaks down: how many players picked
  # it, how many called it right, and the points a correct pick earns (the
  # number of people beaten). Returns nil until the match is settled.
  def points_breakdown
    return nil unless finished? && result

    total = picks.size
    correct = picks.count { |pick| pick.prediction.to_sym == result }
    { total: total, correct: correct, beat: total - correct,
      award: Leaderboard.points_for_correct(total_picks: total, correct_picks: correct) }
  end
end
