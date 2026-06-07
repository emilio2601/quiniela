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

      # Resolve a knockout fixture's teams once football-data knows them.
      if match.knockout? && !match.teams_known? && fd.dig("homeTeam", "name").present?
        match.home_team = canonical(fd.dig("homeTeam", "name"))
        match.away_team = canonical(fd.dig("awayTeam", "name"))
        resolved = true
      end

      if fd["status"] == "FINISHED"
        scored = !match.finished?
        full_time = fd.dig("score", "fullTime") || {}
        match.home_score = full_time["home"]
        match.away_score = full_time["away"]
        match.status = "finished"
      end

      match.save! if match.changed?
      [ scored, resolved ]
    end

    def canonical(name)
      NAME_ALIASES.fetch(name, name)
    end
  end
end
