# Computes the standings on read — there is no leaderboard table.
#
# Scoring rule: for each finished match a pick is "correct" if its prediction
# matches the derived result. A correct pick earns the number of people it beat:
#
#     (users who picked the match) - (users who picked it correctly)
#
# So calling an upset few others called is worth far more than taking an obvious
# favourite everyone took. Incorrect picks earn 0.
class Leaderboard
  # The per-correct-pick formula, isolated so it is easy to swap. To guarantee
  # at least 1 point for any correct pick, change this to:
  #
  #     1 + (total_picks - correct_picks)
  def self.points_for_correct(total_picks:, correct_picks:)
    total_picks - correct_picks
  end

  # Returns rows of { user:, points:, correct:, played: } sorted by points desc,
  # then name. `played` counts finished matches the user picked; `correct` how
  # many of those they called right. Every user appears, even with zero points.
  def self.standings
    tally = User.pluck(:id).index_with { { points: 0, correct: 0, played: 0 } }

    Match.finished.includes(:picks).find_each do |match|
      result = match.result
      next unless result

      total = match.picks.size
      correct = match.picks.select { |pick| pick.prediction.to_sym == result }
      award = points_for_correct(total_picks: total, correct_picks: correct.size)

      match.picks.each { |pick| tally[pick.user_id][:played] += 1 if tally.key?(pick.user_id) }
      correct.each do |pick|
        next unless tally.key?(pick.user_id)

        tally[pick.user_id][:points] += award
        tally[pick.user_id][:correct] += 1
      end
    end

    users = User.where(id: tally.keys).index_by(&:id)
    tally
      .map { |user_id, stat| { user: users[user_id], **stat } }
      .sort_by { |row| [ -row[:points], row[:user].name ] }
  end
end
