# Maps football-data.org match payloads onto our Match rows and writes through
# finished scores and resolved knockout teams.
#
# Matching: prefer a stored external_id; otherwise join on kickoff time, which
# is unique except for the 12 simultaneous group-stage slots — those are
# disambiguated by team name. Knockout matches always have a unique kickoff.
module FootballData
  class ResultsImporter
    # football-data spells a handful of nations differently from openfootball.
    NAME_ALIASES = {
      "Bosnia-Herzegovina" => "Bosnia & Herzegovina",
      "Cape Verde Islands" => "Cape Verde",
      "Congo DR" => "DR Congo",
      "Czechia" => "Czech Republic",
      "United States" => "USA"
    }.freeze

    # football-data's score.winner -> our outcome. This is authoritative: a
    # knockout decided on penalties reports the winner even with a level score.
    WINNER_OUTCOME = {
      "HOME_TEAM" => "home",
      "AWAY_TEAM" => "away",
      "DRAW" => "draw"
    }.freeze

    Summary = Struct.new(:scored, :resolved, :unmatched, keyword_init: true) do
      def to_s = "scored=#{scored} resolved=#{resolved} unmatched=#{unmatched}"
    end

    def import(fd_matches)
      summary = Summary.new(scored: 0, resolved: 0, unmatched: 0)

      fd_matches.each do |fd|
        match = locate(fd)
        if match.nil?
          summary.unmatched += 1
          next
        end

        scored, resolved = apply(match, fd)
        summary.scored += 1 if scored
        summary.resolved += 1 if resolved
      end

      summary
    end

    private

    def locate(fd)
      Match.find_by(external_id: fd["id"]) || by_kickoff(fd)
    end

    def by_kickoff(fd)
      kickoff = Time.zone.parse(fd["utcDate"])
      candidates = Match.where(kickoff_at: kickoff).to_a
      return candidates.first if candidates.one?

      # group-stage simultaneous slot: pick the one whose teams line up
      home = canonical(fd.dig("homeTeam", "name"))
      away = canonical(fd.dig("awayTeam", "name"))
      candidates.find { |m| m.home_team == home && m.away_team == away }
    end

    def apply(match, fd)
      scored = false
      resolved = false
      match.external_id ||= fd["id"]

      # Resolve a knockout fixture's teams once football-data knows them. Both
      # sides must be filled in: mid-bracket it can post one before the other,
      # and writing a blank team would fail the not-null validation and abort
      # the whole import.
      if match.knockout? && !match.teams_known? &&
         fd.dig("homeTeam", "name").present? && fd.dig("awayTeam", "name").present?
        match.home_team = canonical(fd.dig("homeTeam", "name"))
        match.away_team = canonical(fd.dig("awayTeam", "name"))
        resolved = true
      end

      # football-data often flips a match to FINISHED before its backend posts
      # the score (nulls right after the final whistle), and for a shootout it
      # posts a level fullTime before the penalties land. Only settle once we
      # have a usable result, so "finished" always means "we have a result" —
      # no scoreless finished rows, no premature feed/standings entry, and no
      # knockout sitting as a draw while we wait for the shootout to resolve.
      if fd["status"] == "FINISHED" && settleable?(fd)
        scored = !match.finished?
        apply_score(match, fd)
        match.status = "finished"
      end

      match.save! if match.changed?
      [ scored, resolved ]
    end

    def settleable?(fd)
      full_time = fd.dig("score", "fullTime") || {}
      return false if full_time["home"].nil? || full_time["away"].nil?

      # A shootout is undecided until fullTime is no longer level — the side with
      # more goals won the penalties (both were level after extra time).
      return full_time["home"] != full_time["away"] if shootout?(fd)

      true
    end

    # For a shootout, football-data's fullTime is the cumulative tally
    # (regulation + extra time + penalties), so home_score/away_score take the
    # level pre-shootout score (regularTime + extraTime) and the penalties are
    # the remainder — derived from fullTime, because the score/penalties node
    # itself lags (it can sit level for a while after fullTime has resolved).
    # The winner is whoever scored more, since they were level before penalties;
    # we still prefer score/winner when football-data has filled it in. Every
    # other result uses fullTime as-is — it already reflects an extra-time
    # winner (e.g. 2-1 AET).
    def apply_score(match, fd)
      full_time = fd.dig("score", "fullTime") || {}

      if shootout?(fd)
        regular = fd.dig("score", "regularTime") || {}
        extra = fd.dig("score", "extraTime") || {}
        match.home_score = regular["home"].to_i + extra["home"].to_i
        match.away_score = regular["away"].to_i + extra["away"].to_i
        match.home_penalties = full_time["home"] - match.home_score
        match.away_penalties = full_time["away"] - match.away_score
        match.outcome = WINNER_OUTCOME[fd.dig("score", "winner")] ||
                        (full_time["home"] > full_time["away"] ? "home" : "away")
      else
        match.home_score = full_time["home"]
        match.away_score = full_time["away"]
        match.home_penalties = nil
        match.away_penalties = nil
        match.outcome = WINNER_OUTCOME[fd.dig("score", "winner")]
      end
    end

    def shootout?(fd)
      fd.dig("score", "duration") == "PENALTY_SHOOTOUT"
    end

    def canonical(name)
      NAME_ALIASES.fetch(name, name)
    end
  end
end
