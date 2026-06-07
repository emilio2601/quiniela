module MatchesHelper
  # FIFA three-letter codes for the 48 World Cup 2026 nations. Used for the
  # compact match chips/cards. Unknown names (e.g. unresolved knockout
  # placeholders like "W97") fall back to an upcased, trimmed label.
  TEAM_CODES = {
    "Algeria" => "ALG", "Argentina" => "ARG", "Australia" => "AUS", "Austria" => "AUT",
    "Belgium" => "BEL", "Bosnia & Herzegovina" => "BIH", "Brazil" => "BRA", "Canada" => "CAN",
    "Cape Verde" => "CPV", "Colombia" => "COL", "Croatia" => "CRO", "Curaçao" => "CUW",
    "Czech Republic" => "CZE", "DR Congo" => "COD", "Ecuador" => "ECU", "Egypt" => "EGY",
    "England" => "ENG", "France" => "FRA", "Germany" => "GER", "Ghana" => "GHA",
    "Haiti" => "HAI", "Iran" => "IRN", "Iraq" => "IRQ", "Ivory Coast" => "CIV",
    "Japan" => "JPN", "Jordan" => "JOR", "Mexico" => "MEX", "Morocco" => "MAR",
    "Netherlands" => "NED", "New Zealand" => "NZL", "Norway" => "NOR", "Panama" => "PAN",
    "Paraguay" => "PAR", "Portugal" => "POR", "Qatar" => "QAT", "Saudi Arabia" => "KSA",
    "Scotland" => "SCO", "Senegal" => "SEN", "South Africa" => "RSA", "South Korea" => "KOR",
    "Spain" => "ESP", "Sweden" => "SWE", "Switzerland" => "SUI", "Tunisia" => "TUN",
    "Turkey" => "TUR", "USA" => "USA", "Uruguay" => "URU", "Uzbekistan" => "UZB"
  }.freeze

  def team_code(name)
    TEAM_CODES[name] || name.to_s.upcase[0, 4]
  end

  # Human label for a prediction in the context of a match: the two teams play
  # the part of "home"/"away", with "Draw" in the middle.
  def prediction_label(prediction, match)
    case prediction.to_s
    when "home" then match.home_team
    when "away" then match.away_team
    else "Draw"
    end
  end

  # The crowd's split for a match as [home, draw, away] counts. Expects picks
  # to be loaded to avoid per-match queries.
  def pick_split(match)
    counts = match.picks.group_by(&:prediction).transform_values(&:size)
    [ counts["home"].to_i, counts["draw"].to_i, counts["away"].to_i ]
  end
end
